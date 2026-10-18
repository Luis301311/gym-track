import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/progression.dart';
import '../../domain/usecases/workout_usecases.dart';
import '../../domain/utils/format.dart';
import 'workout_draft.dart';

/// Maneja la sesión de entrenamiento activa: cronómetro, descanso, series y
/// guardado. No sabe qué backend hay detrás: solo usa casos de uso y contratos.
class WorkoutController extends GetxController {
  final RoutineRepository routines;
  final GetPreviousPerformance getPrevious;
  final FinishWorkout finishWorkout;

  /// Opcional: si está, cada ejercicio trae su objetivo de hoy (progresión).
  final GetProgressionSuggestions? getSuggestions;
  final String userId;
  final DateTime Function() clock;

  WorkoutController({
    required this.routines,
    required this.getPrevious,
    required this.finishWorkout,
    required this.userId,
    this.getSuggestions,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  // --- Selección de rutina
  final availableRoutines = <Routine>[].obs;
  final loadingRoutines = true.obs;
  final routinesError = RxnString();

  // --- Sesión activa
  final routine = Rxn<Routine>();
  final drafts = <ExerciseDraft>[].obs;
  final current = 0.obs;
  final elapsed = Duration.zero.obs;
  final restRemaining = 0.obs;
  final restTotal = 0.obs;
  final starting = false.obs;
  final saving = false.obs;

  DateTime? _startedAt;
  String? _sessionId;
  Timer? _ticker;
  Timer? _restTimer;

  bool get isActive => routine.value != null;
  bool get isResting => restRemaining.value > 0;
  ExerciseDraft? get currentDraft =>
      drafts.isEmpty ? null : drafts[current.value];

  int get totalSets => drafts.fold(0, (a, d) => a + d.sets.length);
  int get doneSets => drafts.fold(0, (a, d) => a + d.doneCount);
  double get progress => totalSets == 0 ? 0 : doneSets / totalSets;

  @override
  void onInit() {
    super.onInit();
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    loadingRoutines.value = true;
    routinesError.value = null;
    try {
      availableRoutines.assignAll(await routines.getRoutines(userId));
    } catch (e) {
      routinesError.value = 'No se pudieron cargar tus rutinas: $e';
    } finally {
      loadingRoutines.value = false;
    }
  }

  Future<void> start(Routine r) async {
    if (isActive || starting.value) return;
    starting.value = true;
    try {
      final previous = await getPrevious(userId, r.exercises);
      final suggestions =
          await getSuggestions?.call(userId, r.exercises) ?? const {};
      drafts.assignAll([
        for (final e in r.exercises)
          ExerciseDraft.fromHistory(
            e,
            previous[e.id] ?? const [],
            suggestion: suggestions[e.id],
          ),
      ]);
      current.value = 0;
      _startedAt = clock();
      _sessionId = '${_startedAt!.microsecondsSinceEpoch}';
      elapsed.value = Duration.zero;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value = clock().difference(_startedAt!);
      });
      routine.value = r; // al final: la UI cambia cuando todo está listo
    } finally {
      starting.value = false;
    }
  }

  void goTo(int index) {
    if (index < 0 || index >= drafts.length) return;
    current.value = index;
  }

  void updateKg(int exercise, int set, String value) =>
      drafts[exercise].sets[set].kg = value;

  void updateReps(int exercise, int set, String value) =>
      drafts[exercise].sets[set].reps = value;

  /// Marca o desmarca una serie. Si los campos están vacíos usa los valores
  /// de la vez anterior. Devuelve un mensaje de error para mostrar, o null.
  String? toggleSet(int exercise, int set) {
    final d = drafts[exercise];
    final s = d.sets[set];

    if (s.done) {
      s.done = false;
      drafts.refresh();
      return null;
    }

    // Campos vacíos = "hice lo sugerido" (progresión o, si no, la vez anterior).
    final reps =
        s.reps.trim().isEmpty ? d.suggestedReps(set) : int.tryParse(s.reps);
    if (reps == null || reps <= 0) {
      return 'Escribe cuántas repeticiones hiciste.';
    }
    final double? kg =
        s.kg.trim().isEmpty ? (d.suggestedKg(set) ?? 0.0) : parseDecimal(s.kg);
    if (kg == null || kg < 0) return 'El peso no es válido.';

    s
      ..kg = formatKg(kg)
      ..reps = '$reps'
      ..done = true;
    drafts.refresh();
    HapticFeedback.lightImpact();
    startRest(d.exercise.restSeconds);
    return null;
  }

  void addSet(int exercise) {
    drafts[exercise].sets.add(SetDraft());
    drafts.refresh();
  }

  void removeSet(int exercise, int set) {
    final sets = drafts[exercise].sets;
    if (sets.length <= 1) return;
    sets.removeAt(set);
    drafts.refresh();
  }

  // --- Descanso
  void startRest(int seconds) {
    _restTimer?.cancel();
    restTotal.value = seconds;
    restRemaining.value = seconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      restRemaining.value = max(0, restRemaining.value - 1);
      if (restRemaining.value == 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void adjustRest(int deltaSeconds) {
    if (!isResting) return;
    restRemaining.value = max(0, restRemaining.value + deltaSeconds);
    restTotal.value = max(restTotal.value, restRemaining.value);
    if (restRemaining.value == 0) skipRest();
  }

  void skipRest() {
    _restTimer?.cancel();
    restRemaining.value = 0;
  }

  // --- Cierre
  WorkoutSession buildSession() => WorkoutSession(
        id: _sessionId ?? '',
        routineName: routine.value?.name ?? '',
        startedAt: _startedAt ?? clock(),
        finishedAt: clock(),
        logs: [
          for (final d in drafts)
            if (d.doneCount > 0) d.toLog(),
        ],
      );

  /// Guarda la sesión. Requiere al menos una serie completada.
  Future<WorkoutResult> finish() async {
    if (doneSets == 0) {
      throw StateError('No hay series completadas para guardar.');
    }
    saving.value = true;
    try {
      final result = await finishWorkout(userId, buildSession());
      _reset();
      return result;
    } finally {
      saving.value = false;
    }
  }

  void discard() => _reset();

  void _reset() {
    _ticker?.cancel();
    _restTimer?.cancel();
    routine.value = null;
    drafts.clear();
    current.value = 0;
    elapsed.value = Duration.zero;
    restRemaining.value = 0;
    restTotal.value = 0;
    _startedAt = null;
    _sessionId = null;
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    super.onClose();
  }
}
