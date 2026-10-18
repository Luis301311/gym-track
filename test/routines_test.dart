import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/domain/catalog/exercise_catalog.dart';
import 'package:gymtrack/domain/entities/entities.dart';
import 'package:gymtrack/domain/repositories/repositories.dart';
import 'package:gymtrack/domain/usecases/routine_recommender.dart';
import 'package:gymtrack/presentation/routines/routines_controller.dart';

RecommendationInput _input({
  TrainingGoal goal = TrainingGoal.hypertrophy,
  int days = 3,
  ExperienceLevel level = ExperienceLevel.intermediate,
  EquipmentAccess access = EquipmentAccess.gym,
  int minutes = 60,
}) =>
    RecommendationInput(
        goal: goal,
        daysPerWeek: days,
        level: level,
        access: access,
        minutes: minutes);

class _Routines implements RoutineRepository, RoutineWriteRepository {
  final list = <Routine>[];
  @override
  Future<List<Routine>> getRoutines(String userId) async => List.of(list);
  @override
  Future<void> saveRoutine(String userId, Routine r) async {
    list
      ..removeWhere((x) => x.id == r.id)
      ..add(r);
  }

  @override
  Future<void> deleteRoutine(String userId, String id) async =>
      list.removeWhere((x) => x.id == id);
}

void main() {
  final recommender = RoutineRecommender();
  final byId = {for (final c in kExerciseCatalog) c.exercise.id: c};

  group('Recomendador', () {
    test('elige la división según los días', () {
      expect(recommender.recommend(_input(days: 3)).splitName, 'Cuerpo completo');
      expect(recommender.recommend(_input(days: 4)).splitName, 'Torso / Pierna');
      expect(recommender.recommend(_input(days: 6)).splitName,
          'Empuje / Tirón / Pierna');
    });

    test('una rutina por día, en días distintos de la semana', () {
      for (var d = 2; d <= 6; d++) {
        final plan = recommender.recommend(_input(days: d));
        expect(plan.routines, hasLength(d));
        final days = plan.routines.expand((r) => r.weekdays).toList();
        expect(days.toSet(), hasLength(d), reason: '$d días');
      }
    });

    test('respeta el equipo disponible', () {
      for (final access in EquipmentAccess.values) {
        final plan = recommender.recommend(_input(access: access, days: 4));
        for (final r in plan.routines) {
          expect(r.exercises, isNotEmpty);
          for (final e in r.exercises) {
            expect(access.allowed, contains(byId[e.id]!.equipment),
                reason: '${e.name} con ${access.label}');
          }
        }
      }
    });

    test('no repite un ejercicio dentro del mismo día', () {
      for (var d = 2; d <= 6; d++) {
        for (final r in recommender.recommend(_input(days: d)).routines) {
          final ids = r.exercises.map((e) => e.id).toList();
          expect(ids.toSet(), hasLength(ids.length), reason: r.name);
        }
      }
    });

    test('rota ejercicios entre días (A y B no son iguales)', () {
      final plan = recommender.recommend(_input(days: 4));
      final torsoA = plan.routines[0].exercises.map((e) => e.id).toSet();
      final torsoB = plan.routines[2].exercises.map((e) => e.id).toSet();
      expect(torsoA, isNot(equals(torsoB)));
    });

    test('series y repeticiones según objetivo y experiencia', () {
      Exercise firstCompound(RoutineRecommendation p) => p.routines.first
          .exercises
          .firstWhere((e) => byId[e.id]!.compound);

      final strength = firstCompound(recommender.recommend(
          _input(goal: TrainingGoal.strength)));
      expect(strength.targetReps, '4-6');
      expect(strength.targetSets, 5);
      expect(strength.restSeconds, 180);

      final beginner = firstCompound(recommender.recommend(_input(
          goal: TrainingGoal.strength, level: ExperienceLevel.beginner)));
      expect(beginner.targetSets, 4);
    });

    test('menos tiempo = menos ejercicios; principiante, uno menos', () {
      int count(RecommendationInput i) =>
          recommender.recommend(i).routines.first.exercises.length;
      expect(count(_input(minutes: 45)), 4);
      expect(count(_input(minutes: 75)), 6);
      expect(count(_input(minutes: 60, level: ExperienceLevel.beginner)), 4);
    });

    test('es determinista', () {
      final a = recommender.recommend(_input(days: 5), idPrefix: 'x');
      final b = recommender.recommend(_input(days: 5), idPrefix: 'x');
      expect(a.routines.map((r) => r.exercises.map((e) => e.id).join()),
          b.routines.map((r) => r.exercises.map((e) => e.id).join()));
    });
  });

  group('Rutina', () {
    const bench = Exercise(id: 'b', name: 'Press', muscleGroup: 'Pecho',
        targetSets: 4, restSeconds: 120);
    const fly = Exercise(id: 'f', name: 'Aperturas', muscleGroup: 'Pecho');
    const ext = Exercise(id: 't', name: 'Extensión', muscleGroup: 'Tríceps');

    test('el enfoque se arma con los grupos musculares', () {
      expect(describeFocus([bench, fly, ext]), 'Pecho y tríceps');
      expect(describeFocus([]), '');
    });

    test('duración estimada', () {
      // 4×(45+120) + 3×(45+90) = 660 + 405 = 1065 s ≈ 18 min + 5
      expect(estimateMinutes([bench, fly]), 23);
    });
  });

  group('RoutinesController', () {
    late _Routines repo;
    late RoutinesController c;
    var changes = 0;

    setUp(() async {
      repo = _Routines();
      changes = 0;
      c = RoutinesController(
        routines: repo,
        writer: repo,
        recommender: recommender,
        userId: 'u',
        onChanged: () => changes++,
      );
      await c.load();
    });

    test('valida nombre y ejercicios', () async {
      expect(
          await c.save(Routine.build(
              id: '1', name: ' ', exercises: const [], weekdays: const [])),
          isNotNull);
      expect(
          await c.save(Routine.build(
              id: '1', name: 'Torso', exercises: const [], weekdays: const [])),
          isNotNull);
      expect(changes, 0);
    });

    test('crear, editar y eliminar avisa a las demás pantallas', () async {
      const e = Exercise(id: 'b', name: 'Press', muscleGroup: 'Pecho');
      final r = Routine.build(
          id: '1', name: 'Torso', exercises: const [e], weekdays: const [1]);
      expect(await c.save(r), isNull);
      expect(c.list.single.name, 'Torso');

      expect(await c.delete('1'), isNull);
      expect(c.list, isEmpty);
      expect(changes, 2);
    });

    test('guardar un plan: reemplazar o sumar', () async {
      const e = Exercise(id: 'b', name: 'Press', muscleGroup: 'Pecho');
      await c.save(Routine.build(
          id: 'mia', name: 'Mía', exercises: const [e], weekdays: const [7]));

      final plan = c.recommend(_input(days: 3));
      await c.saveRecommendation(plan, replace: false);
      expect(c.list, hasLength(4));

      await c.saveRecommendation(c.recommend(_input(days: 2)), replace: true);
      expect(c.list, hasLength(2));
      expect(c.list.any((r) => r.id == 'mia'), isFalse);
    });
  });
}
