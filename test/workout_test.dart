import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/data/repositories/memory_repositories.dart';
import 'package:gymtrack/domain/entities/entities.dart';
import 'package:gymtrack/domain/usecases/workout_usecases.dart';
import 'package:gymtrack/presentation/workout/workout_controller.dart';

const _bench = Exercise(id: 'bench', name: 'Press de banca', muscleGroup: 'Pecho');

WorkoutSession _session(String id, double kg, {int reps = 8}) => WorkoutSession(
      id: id,
      routineName: 'Push',
      startedAt: DateTime(2026, 10, 1),
      logs: [
        ExerciseLog(exercise: _bench, sets: [
          WorkoutSet(reps: reps, weightKg: kg),
          WorkoutSet(reps: reps, weightKg: kg - 5),
        ]),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Récords personales', () {
    test('detecta cuando se supera la mejor marca', () {
      final records =
          detectPersonalRecords([_session('a', 70)], _session('b', 72.5));
      expect(records, hasLength(1));
      expect(records.single.set.weightKg, 72.5);
      expect(records.single.previousBestKg, 70);
    });

    test('no hay récord si se iguala o se baja', () {
      expect(detectPersonalRecords([_session('a', 70)], _session('b', 70)),
          isEmpty);
    });

    test('la primera vez que se hace un ejercicio no cuenta como récord', () {
      expect(detectPersonalRecords([], _session('b', 70)), isEmpty);
    });
  });

  group('WorkoutController', () {
    late InMemoryWorkoutRepository workouts;
    late WorkoutController c;

    setUp(() {
      workouts = InMemoryWorkoutRepository();
      c = WorkoutController(
        routines: InMemoryRoutineRepository(),
        getPrevious: GetPreviousPerformance(workouts),
        finishWorkout: FinishWorkout(workouts),
        userId: 'u',
      );
    });

    tearDown(() => c.discard());

    Future<Routine> push() async =>
        (await InMemoryRoutineRepository().getRoutines('u'))
            .firstWhere((r) => r.id == 'push');

    test('al empezar trae las series de la vez anterior', () async {
      await c.start(await push());
      expect(c.isActive, isTrue);
      expect(c.drafts.first.previous, isNotEmpty);
      expect(c.drafts.first.sets.length, c.drafts.first.previous.length);
    });

    test('completar una serie vacía usa los valores anteriores e inicia el descanso',
        () async {
      await c.start(await push());
      final prev = c.drafts.first.previousFor(0)!;

      expect(c.toggleSet(0, 0), isNull);
      final s = c.drafts.first.sets.first;
      expect(s.done, isTrue);
      expect(s.reps, '${prev.reps}');
      expect(c.isResting, isTrue);
      expect(c.restRemaining.value, _bench.restSeconds);
    });

    test('pide reps cuando no hay referencia', () async {
      await c.start(await push());
      c.addSet(0);
      final last = c.drafts.first.sets.length - 1;
      // Hay referencia (última serie anterior), así que forzamos un valor inválido.
      c.updateReps(0, last, '0');
      expect(c.toggleSet(0, last), isNotNull);
      expect(c.drafts.first.sets[last].done, isFalse);
    });

    test('acepta kg con coma decimal', () async {
      await c.start(await push());
      c.updateKg(0, 0, '72,5');
      c.updateReps(0, 0, '8');
      c.toggleSet(0, 0);
      expect(c.drafts.first.sets.first.kg, '72.5');
    });

    test('terminar guarda solo las series completadas y detecta récords',
        () async {
      await c.start(await push());
      c.updateKg(0, 0, '200');
      c.updateReps(0, 0, '1');
      c.toggleSet(0, 0);

      final result = await c.finish();

      expect(c.isActive, isFalse);
      expect(result.completedSets, 1);
      expect(result.session.logs, hasLength(1));
      expect(result.records.single.exercise.id, 'bench');

      final saved = await workouts.watchSessions('u').first;
      expect(saved.any((s) => s.id == result.session.id), isTrue);
    });

    test('no deja terminar sin series completadas', () async {
      await c.start(await push());
      await expectLater(c.finish(), throwsStateError);
    });
  });
}
