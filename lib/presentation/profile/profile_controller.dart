import 'dart:async';

import 'package:get/get.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/profile_summary.dart';
import '../../domain/utils/format.dart';

class ProfileController extends GetxController {
  final ProfileRepository profiles;
  final ProfileWriteRepository profileWriter;
  final WorkoutRepository workouts;
  final BodyMetricsRepository bodyMetrics;
  final MeasurementsRepository measurements;
  final RoutineRepository routines;
  final String userId;
  final DateTime Function() clock;

  /// Se llama al guardar el perfil (p. ej. para refrescar el saludo de Inicio)
  /// sin que este controlador conozca a los demás.
  final void Function()? onProfileChanged;

  ProfileController({
    required this.profiles,
    required this.profileWriter,
    required this.workouts,
    required this.bodyMetrics,
    required this.measurements,
    required this.routines,
    required this.userId,
    this.onProfileChanged,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final summary = Rxn<ProfileSummary>();
  final routineList = <Routine>[].obs;
  final error = RxnString();

  UserProfile? _profile;
  List<WorkoutSession>? _sessions;
  List<BodyWeightEntry>? _weights;
  List<BodyMeasurement>? _measures;
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    error.value = null;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    try {
      _profile = await profiles.getProfile(userId);
      routineList.assignAll(await routines.getRoutines(userId));
    } catch (e) {
      _onError(e);
      return;
    }
    _subs
      ..add(workouts.watchSessions(userId).listen((v) {
        _sessions = v;
        _recompute();
      }, onError: _onError))
      ..add(bodyMetrics.watchWeights(userId).listen((v) {
        _weights = v;
        _recompute();
      }, onError: _onError))
      ..add(measurements.watchMeasurements(userId).listen((v) {
        _measures = v;
        _recompute();
      }, onError: _onError));
  }

  /// Guarda los datos del perfil. Devuelve un mensaje de error o null.
  Future<String?> saveProfile({
    required String name,
    required String goal,
    required String heightCm,
    required int weeklyGoal,
    Sex? sex,
  }) async {
    final current = _profile;
    if (current == null) return 'El perfil aún no carga.';
    if (name.trim().isEmpty) return 'Escribe tu nombre.';
    if (weeklyGoal < 1 || weeklyGoal > 7) {
      return 'La meta semanal va de 1 a 7 entrenos.';
    }
    double? height;
    if (heightCm.trim().isNotEmpty) {
      height = parseDecimal(heightCm);
      if (height == null || height < 100 || height > 250) {
        return 'Escribe tu altura en centímetros (por ejemplo 175).';
      }
    }
    final updated = current.copyWith(
      name: name.trim(),
      goal: goal.trim(),
      weeklyGoal: weeklyGoal,
      heightCm: height,
      sex: sex,
    );
    try {
      await profileWriter.saveProfile(updated);
    } catch (e) {
      return 'No se pudo guardar el perfil: $e';
    }
    _profile = updated;
    _recompute();
    onProfileChanged?.call();
    return null;
  }

  UserProfile? get profile => _profile;

  /// Cambia solo el sexo (lo usa la recomendación de rutinas).
  Future<void> updateSex(Sex sex) async {
    final current = _profile;
    if (current == null || current.sex == sex) return;
    final updated = current.copyWith(sex: sex);
    try {
      await profileWriter.saveProfile(updated);
    } catch (_) {
      return; // no es crítico: se puede volver a elegir en Perfil
    }
    _profile = updated;
    _recompute();
  }

  /// Registra medidas. [raw] va de clave de medida a texto escrito; las
  /// vacías se ignoran. Devuelve un mensaje de error o null.
  Future<String?> addMeasurement(Map<String, String> raw) async {
    final values = <String, double>{};
    for (final t in kMeasurementTypes) {
      final text = raw[t.key]?.trim() ?? '';
      if (text.isEmpty) continue;
      final v = parseDecimal(text);
      if (v == null || v < 10 || v > 300) {
        return 'Revisa el valor de ${t.label.toLowerCase()} (en cm).';
      }
      values[t.key] = v;
    }
    if (values.isEmpty) return 'Escribe al menos una medida.';
    try {
      await measurements.addMeasurement(
        userId,
        BodyMeasurement(id: '', date: clock(), valuesCm: values),
      );
      return null;
    } catch (e) {
      return 'No se pudieron guardar las medidas: $e';
    }
  }

  void _recompute() {
    final p = _profile, s = _sessions, w = _weights, m = _measures;
    if (p == null || s == null || w == null || m == null) return;
    summary.value = buildProfileSummary(
      profile: p,
      sessions: s,
      weights: w,
      measurements: m,
    );
  }

  void _onError(Object e) => error.value = 'No se pudo cargar tu perfil: $e';

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}
