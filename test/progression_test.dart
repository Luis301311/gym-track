import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/data/repositories/memory_repositories.dart';
import 'package:gymtrack/domain/entities/entities.dart';
import 'package:gymtrack/domain/usecases/coach.dart';
import 'package:gymtrack/domain/usecases/progression.dart';
import 'package:gymtrack/domain/usecases/workout_usecases.dart';
import 'package:gymtrack/presentation/workout/workout_controller.dart';

const bench = Exercise(
    id: 'bench', name: 'Press de banca', muscleGroup: 'Pecho',
    equipment: 'Barra', targetSets: 3, targetReps: '8-12');
const squat = Exercise(
    id: 'squat', name: 'Sentadilla', muscleGroup: 'Piernas',
    equipment: 'Barra', targetSets: 3, targetReps: '8-12');
const dbCurl = Exercise(
    id: 'curl', name: 'Curl', muscleGroup: 'Bíceps',
    equipment: 'Mancuernas', targetSets: 3, targetReps: '8-12');
const pullup = Exercise(
    id: 'pullup', name: 'Dominadas', muscleGroup: 'Espalda',
    equipment: 'Barra fija', targetSets: 3, targetReps: '6-10');
const plank = Exercise(
    id: 'plank', name: 'Plancha', muscleGroup: 'Core',
    equipment: 'Peso corporal', targetReps: '30-45 s');

List<WorkoutSet> sets(double kg, List<int> reps) =>
    [for (final r in reps) WorkoutSet(reps: r, weightKg: kg)];

void main() {
  const advisor = ProgressionAdvisor();

  group('Rango de repeticiones', () {
    test('lee rangos, números sueltos y descarta tiempos', () {
      final r = RepRange.parse('8-12')!;
      expect([r.min, r.max], [8, 12]);
      expect(RepRange.parse('10')!.max, 10);
      expect(RepRange.parse('10 reps')!.min, 10);
      expect(RepRange.parse('30-45 s'), isNull);
      expect(RepRange.parse('1 min'), isNull);
    });
  });

  group('Progresión doble', () {
    test('todas las series en el tope → sube el peso', () {
      final s = advisor.suggest(bench, [sets(100, [12, 12, 12])]);
      expect(s.kind, ProgressionKind.increase);
      expect(s.kg, 102.5);
      expect(s.reps, 8);
    });

    test('el incremento depende del equipo y la zona', () {
      expect(advisor.suggest(squat, [sets(100, [12, 12, 12])]).kg, 105);
      expect(advisor.suggest(dbCurl, [sets(12, [12, 12, 12])]).kg, 14);
    });

    test('sin llegar al tope → mismo peso y una rep más', () {
      final s = advisor.suggest(bench, [sets(100, [10, 9, 8])]);
      expect(s.kind, ProgressionKind.hold);
      expect(s.kg, 100);
      expect(s.reps, 9);
    });

    test('menos series que el plan no cuenta para subir', () {
      final s = advisor.suggest(bench, [sets(100, [12, 12])]);
      expect(s.kind, ProgressionKind.hold);
    });

    test('dos sesiones por debajo del mínimo → descarga del 10 %', () {
      final s = advisor.suggest(bench, [
        sets(100, [6, 6, 5]),
        sets(100, [7, 6, 6]),
      ]);
      expect(s.kind, ProgressionKind.deload);
      expect(s.kg, 90);
    });

    test('si la sesión anterior era más liviana, no es estancamiento', () {
      final s = advisor.suggest(bench, [
        sets(100, [6, 6, 5]),
        sets(95, [7, 6, 6]),
      ]);
      expect(s.kind, ProgressionKind.hold);
      expect(s.reps, 8); // al menos el mínimo del rango
    });

    test('peso corporal en el tope → variante más difícil', () {
      final s = advisor.suggest(pullup, [sets(0, [10, 10, 10])]);
      expect(s.kind, ProgressionKind.harderVariant);
    });

    test('primera vez y ejercicios por tiempo', () {
      final first = advisor.suggest(bench, []);
      expect(first.kind, ProgressionKind.firstTime);
      expect(first.kg, isNull);
      expect(first.reps, 8);

      final p = advisor.suggest(plank, [sets(0, [40, 40, 40])]);
      expect(p.reps, isNull);
    });
  });

  test('historial: la sesión más reciente primero, máximo 2', () {
    WorkoutSession s(int day, double kg) => WorkoutSession(
          id: '$day',
          routineName: 'x',
          startedAt: DateTime(2026, 10, day),
          logs: [ExerciseLog(exercise: bench, sets: sets(kg, [8]))],
        );
    final h = exerciseHistory([s(1, 90), s(10, 100), s(5, 95)], 'bench');
    expect(h.map((x) => x.first.weightKg), [100, 95]);
  });

  group('Coach', () {
    WorkoutResult result({
      List<PersonalRecord> records = const [],
      List<ProgressionSuggestion> next = const [],
    }) =>
        WorkoutResult(
          WorkoutSession(
            id: 's',
            routineName: 'Push',
            startedAt: DateTime(2026, 10, 15, 18),
            finishedAt: DateTime(2026, 10, 15, 18, 50),
            logs: [ExerciseLog(exercise: bench, sets: sets(100, [12, 12, 12]))],
          ),
          records,
          next,
        );

    test('el coach local celebra, indica qué subir y la meta semanal', () async {
      final up = advisor.suggest(bench, [sets(100, [12, 12, 12])]);
      final msg = await const LocalCoach().workoutFeedback(CoachRequest(
        result: result(
          records: [
            PersonalRecord(
                exercise: bench,
                set: const WorkoutSet(reps: 12, weightKg: 100),
                previousBestKg: 97.5),
          ],
          next: [up],
        ),
        profile: const UserProfile(
            id: 'u', name: 'Luis', goal: '', weeklyGoal: 4),
        weeklyDone: 2,
      ));
      expect(msg, contains('récord'));
      expect(msg, contains('102.5 kg'));
      expect(msg, contains('2 de 4'));
    });

    test('si la IA falla, responde el coach local', () async {
      final coach = FallbackCoach(_Failing(), const LocalCoach());
      final msg = await coach.workoutFeedback(CoachRequest(result: result()));
      expect(msg, isNotEmpty);
    });

    test('si la IA responde, se usa su mensaje', () async {
      final coach = FallbackCoach(_Fixed('¡Gran sesión!'), const LocalCoach());
      expect(await coach.workoutFeedback(CoachRequest(result: result())),
          '¡Gran sesión!');
    });

    test('lo que se envía a la IA no incluye datos personales', () {
      final payload = CoachRequest(
        result: result(),
        profile: const UserProfile(id: 'uid-123', name: 'Luis Vega', goal: 'Masa'),
      ).toPayload();
      final text = payload.toString();
      expect(text, isNot(contains('uid-123')));
      expect(text, isNot(contains('Luis Vega')));
      expect(payload['exercises'], isNotEmpty);
    });
  });

  group('Integración', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('al terminar se calcula qué hacer la próxima vez', () async {
      final repo = InMemoryWorkoutRepository();
      final result = await FinishWorkout(repo)('u', WorkoutSession(
        id: 'hoy',
        routineName: 'Push',
        startedAt: DateTime.now(),
        logs: [ExerciseLog(exercise: bench, sets: sets(100, [12, 12, 12]))],
      ));
      expect(result.nextSteps.single.kind, ProgressionKind.increase);
    });

    test('al entrenar, el ✓ con campos vacíos usa el objetivo de hoy', () async {
      final repo = InMemoryWorkoutRepository();
      final c = WorkoutController(
        routines: InMemoryRoutineRepository(),
        getPrevious: GetPreviousPerformance(repo),
        finishWorkout: FinishWorkout(repo),
        getSuggestions: GetProgressionSuggestions(repo),
        userId: 'u',
      );
      final push = (await InMemoryRoutineRepository().getRoutines('u'))
          .firstWhere((r) => r.id == 'push');
      await c.start(push);
      final d = c.drafts.first;
      expect(d.suggestion, isNotNull);

      c.toggleSet(0, 0);
      expect(d.sets.first.reps, '${d.suggestion!.reps}');
      c.discard();
    });
  });
}

class _Failing implements AiCoach {
  @override
  Future<String> workoutFeedback(CoachRequest r) async =>
      throw Exception('sin señal');
}

class _Fixed implements AiCoach {
  final String text;
  _Fixed(this.text);
  @override
  Future<String> workoutFeedback(CoachRequest r) async => text;
}
