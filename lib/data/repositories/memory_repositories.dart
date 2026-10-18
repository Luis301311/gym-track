import 'dart:async';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/utils/date_utils.dart';

/// Implementaciones en memoria con datos de ejemplo.
/// Permiten correr la app sin configurar Firebase y sirven para pruebas.

const _bench = Exercise(id: 'bench', name: 'Press de banca', muscleGroup: 'Pecho', equipment: 'Barra');
const _ohp = Exercise(id: 'ohp', name: 'Press militar', muscleGroup: 'Hombro', equipment: 'Barra');
const _dips = Exercise(id: 'dips', name: 'Fondos', muscleGroup: 'Tríceps', equipment: 'Paralelas');
const _row = Exercise(id: 'row', name: 'Remo con barra', muscleGroup: 'Espalda', equipment: 'Barra');
const _pullup = Exercise(id: 'pullup', name: 'Dominadas', muscleGroup: 'Espalda', equipment: 'Barra fija');
const _curl = Exercise(id: 'curl', name: 'Curl de bíceps', muscleGroup: 'Bíceps', equipment: 'Mancuernas', restSeconds: 60);
const _squat = Exercise(id: 'squat', name: 'Sentadilla', muscleGroup: 'Piernas', equipment: 'Barra', restSeconds: 150);
const _rdl = Exercise(id: 'rdl', name: 'Peso muerto rumano', muscleGroup: 'Femoral', equipment: 'Barra', restSeconds: 120);
const _lunge = Exercise(id: 'lunge', name: 'Zancadas', muscleGroup: 'Piernas', equipment: 'Mancuernas');

final _routines = <Routine>[
  const Routine(
    id: 'push', name: 'Push Day', focus: 'Pecho, hombro y tríceps',
    exercises: [_bench, _ohp, _dips], estimatedMinutes: 55, weekdays: [1, 4],
  ),
  const Routine(
    id: 'pull', name: 'Pull Day', focus: 'Espalda y bíceps',
    exercises: [_row, _pullup, _curl], estimatedMinutes: 50, weekdays: [2, 5],
  ),
  const Routine(
    id: 'legs', name: 'Leg Day', focus: 'Piernas y glúteos',
    exercises: [_squat, _rdl, _lunge], estimatedMinutes: 60, weekdays: [3, 6],
  ),
];

/// Pesos de trabajo base por ejercicio para generar el historial.
const _baseKg = {
  'bench': 65.0, 'ohp': 37.5, 'dips': 0.0, 'row': 55.0, 'pullup': 0.0,
  'curl': 12.0, 'squat': 90.0, 'rdl': 70.0, 'lunge': 14.0,
};

List<WorkoutSession> _seedSessions(DateTime now) {
  final sessions = <WorkoutSession>[];
  // Últimas 3 semanas, sin incluir hoy, siguiendo el plan de rutinas.
  for (var back = 21; back >= 1; back--) {
    final day = dayOnly(now).subtract(Duration(days: back));
    final routine = _routines.where((r) => r.weekdays.contains(day.weekday));
    if (routine.isEmpty) continue;
    final r = routine.first;
    final progress = (21 - back) / 21; // sube poco a poco el peso
    final start = day.add(const Duration(hours: 18));
    sessions.add(WorkoutSession(
      id: 'seed-$back',
      routineName: r.name,
      startedAt: start,
      finishedAt: start.add(Duration(minutes: r.estimatedMinutes)),
      logs: [
        for (final e in r.exercises)
          ExerciseLog(
            exercise: e,
            sets: List.generate(
              4,
              (_) => WorkoutSet(
                reps: e.id == 'squat' ? 5 : 8,
                weightKg: ((_baseKg[e.id] ?? 0) * (1 + 0.1 * progress) / 2.5)
                        .roundToDouble() *
                    2.5,
              ),
            ),
          ),
      ],
    ));
  }
  return sessions;
}

class InMemoryWorkoutRepository implements WorkoutRepository {
  final _sessions = <String, List<WorkoutSession>>{};
  final _controller = StreamController<String>.broadcast();

  List<WorkoutSession> _of(String uid) =>
      _sessions.putIfAbsent(uid, () => _seedSessions(DateTime.now()));

  @override
  Stream<List<WorkoutSession>> watchSessions(String userId) async* {
    yield List.unmodifiable(_of(userId));
    yield* _controller.stream
        .where((uid) => uid == userId)
        .map((_) => List<WorkoutSession>.unmodifiable(_of(userId)));
  }

  @override
  Future<void> saveSession(String userId, WorkoutSession session) async {
    final list = _of(userId)..removeWhere((s) => s.id == session.id);
    list.add(session);
    _controller.add(userId);
  }
}

class InMemoryRoutineRepository implements RoutineRepository {
  @override
  Future<List<Routine>> getRoutines(String userId) async => _routines;
}

class InMemoryProfileRepository
    implements ProfileRepository, ProfileWriteRepository {
  final _profiles = <String, UserProfile>{};

  @override
  Future<UserProfile> getProfile(String userId) async =>
      _profiles[userId] ??
      UserProfile(
        id: userId,
        name: 'Luis Vega',
        goal: 'Ganar masa muscular',
        weeklyGoal: 5,
        heightCm: 175,
      );

  @override
  Future<void> saveProfile(UserProfile profile) async =>
      _profiles[profile.id] = profile;
}
  return list;
}

class InMemoryBodyMetricsRepository implements BodyMetricsRepository {
  final _weights = <String, List<BodyWeightEntry>>{};
  final _controller = StreamController<String>.broadcast();

  List<BodyWeightEntry> _of(String uid) =>
      _weights.putIfAbsent(uid, () => _seedWeights(DateTime.now()));

  @override
  Stream<List<BodyWeightEntry>> watchWeights(String userId) async* {
    yield List.unmodifiable(_of(userId));
    yield* _controller.stream
        .where((uid) => uid == userId)
        .map((_) => List<BodyWeightEntry>.unmodifiable(_of(userId)));
  }

  @override
  Future<void> addWeight(String userId, BodyWeightEntry entry) async {
    final id = entry.id.isEmpty
        ? 'w-${DateTime.now().microsecondsSinceEpoch}'
        : entry.id;
    _of(userId)
      ..removeWhere((w) => w.id == id)
      ..add(BodyWeightEntry(id: id, date: entry.date, kg: entry.kg));
    _controller.add(userId);
  }
}

class InMemoryMeasurementsRepository implements MeasurementsRepository {
  final _data = <String, List<BodyMeasurement>>{};
  final _controller = StreamController<String>.broadcast();

  List<BodyMeasurement> _of(String uid) => _data.putIfAbsent(uid, () {
        final today = dayOnly(DateTime.now());
        return [
          BodyMeasurement(
            id: 'm-60',
            date: today.subtract(const Duration(days: 60)),
            valuesCm: const {'chest': 100, 'arm': 35, 'waist': 83.5},
          ),
          BodyMeasurement(
            id: 'm-5',
            date: today.subtract(const Duration(days: 5)),
            valuesCm: const {'chest': 102, 'arm': 36, 'waist': 82},
          ),
        ];
      });

  @override
  Stream<List<BodyMeasurement>> watchMeasurements(String userId) async* {
    yield List.unmodifiable(_of(userId));
    yield* _controller.stream
        .where((uid) => uid == userId)
        .map((_) => List<BodyMeasurement>.unmodifiable(_of(userId)));
  }

  @override
  Future<void> addMeasurement(String userId, BodyMeasurement m) async {
    final id =
        m.id.isEmpty ? 'm-${DateTime.now().microsecondsSinceEpoch}' : m.id;
    _of(userId)
      ..removeWhere((x) => x.id == id)
      ..add(BodyMeasurement(id: id, date: m.date, valuesCm: m.valuesCm));
    _controller.add(userId);
  }
}
