import 'dart:async';

import 'package:get/get.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/progress_summary.dart';

class ProgressController extends GetxController {
  final WorkoutRepository workouts;
  final BodyMetricsRepository bodyMetrics;
  final String userId;
  final DateTime Function() clock;

  ProgressController({
    required this.workouts,
    required this.bodyMetrics,
    required this.userId,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final range = ProgressRange.month.obs;
  final summary = Rxn<ProgressSummary>();
  final error = RxnString();

  List<WorkoutSession>? _sessions;
  List<BodyWeightEntry>? _weights;
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    error.value = null;
    for (final s in _subs) {
      s.cancel();
    }
    _subs
      ..clear()
      ..add(workouts.watchSessions(userId).listen((s) {
        _sessions = s;
        _recompute();
      }, onError: _onError))
      ..add(bodyMetrics.watchWeights(userId).listen((w) {
        _weights = w;
        _recompute();
      }, onError: _onError));
  }

  void setRange(ProgressRange r) {
    range.value = r;
    _recompute();
  }

  /// Guarda un peso nuevo. Devuelve un mensaje de error o null.
  Future<String?> addWeight(String raw) async {
    final kg = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (kg == null || kg < 20 || kg > 400) {
      return 'Escribe un peso válido en kg (por ejemplo 78.4).';
    }
    try {
      await bodyMetrics.addWeight(
        userId,
        BodyWeightEntry(id: '', date: clock(), kg: kg),
      );
      return null;
    } catch (e) {
      return 'No se pudo guardar el peso: $e';
    }
  }

  void _recompute() {
    final s = _sessions, w = _weights;
    if (s == null || w == null) return; // esperar ambas fuentes
    summary.value = buildProgressSummary(
      sessions: s,
      weights: w,
      range: range.value,
      now: clock(),
    );
  }

  void _onError(Object e) => error.value = 'No se pudo cargar tu progreso: $e';

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}
