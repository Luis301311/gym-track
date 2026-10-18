import 'dart:async';

import '../../domain/catalog/starter_routines.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/utils/date_utils.dart';

/// Implementaciones en memoria con datos de ejemplo.
/// Permiten correr la app sin configurar Firebase y sirven para pruebas.

final _routines = <Routine>[...kStarterRoutines];

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

class InMemoryRoutineRepository
    implements RoutineRepository, RoutineWriteRepository {
  @override
  Future<List<Routine>> getRoutines(String userId) async =>
      List.unmodifiable(_routines);

  @override
  Future<void> saveRoutine(String userId, Routine routine) async {
    final i = _routines.indexWhere((r) => r.id == routine.id);
    if (i >= 0) {
      _routines[i] = routine; // conserva el orden al editar
    } else {
      _routines.add(routine);
    }
  }

  @override
  Future<void> deleteRoutine(String userId, String routineId) async {
    _routines.removeWhere((r) => r.id == routineId);
  }
}

/// Sesión simulada: arranca con el usuario de ejemplo ya dentro, así la app
/// abre directo en Inicio cuando se corre sin Firebase.
class InMemoryAuthRepository implements AuthRepository {
  static const demo =
      AuthUser(uid: 'demo-user', email: 'demo@gymtrack.app', displayName: 'Luis Vega');

  AuthUser? _current;
  final _controller = StreamController<AuthUser?>.broadcast();

  InMemoryAuthRepository({bool signedIn = true}) : _current = signedIn ? demo : null;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  void _emit(AuthUser? u) {
    _current = u;
    _controller.add(u);
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    if (password.length < 6) {
      throw const AuthFailure('Correo o contraseña incorrectos.');
    }
    _emit(demo);
    return demo;
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final u = AuthUser(uid: demo.uid, email: email, displayName: name);
    _emit(u);
    return u;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => _emit(null);
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
  Future<void> saveProfile(UserProfile profile) async {
    _profiles[profile.id] = profile;
  }
}

/// Peso de ejemplo: un registro cada 3 días durante ~4 meses, bajando poco a
/// poco de 80.5 a 78.4 kg con algo de variación natural.
List<BodyWeightEntry> _seedWeights(DateTime now) {
  const days = 120, every = 3;
  const wobble = [0.0, 0.3, -0.2, 0.4, -0.1, 0.2, -0.3, 0.1];
  final list = <BodyWeightEntry>[];
  for (var back = days, i = 0; back >= 0; back -= every, i++) {
    final t = 1 - back / days; // 0 -> 1
    final kg = back == 0 ? 78.4 : 80.5 - 2.1 * t + wobble[i % wobble.length];
    list.add(BodyWeightEntry(
      id: 'w-$back',
      date: dayOnly(now).subtract(Duration(days: back)).add(const Duration(hours: 7)),
      kg: (kg * 10).roundToDouble() / 10,
    ));
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
