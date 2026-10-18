import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/data/mappers/mappers.dart';
import 'package:gymtrack/data/repositories/asset_exercise_library.dart';
import 'package:gymtrack/domain/catalog/exercise_catalog.dart';
import 'package:gymtrack/domain/catalog/starter_routines.dart';
import 'package:gymtrack/domain/usecases/routine_recommender.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la biblioteca trae el catálogo curado primero y cientos más', () async {
    final all = await AssetExerciseLibrary().getAll();
    expect(all.length, greaterThan(500));
    expect(all.first.exercise.id, kExerciseCatalog.first.exercise.id);

    final library = all.skip(kExerciseCatalog.length);
    expect(library.every((c) => c.exercise.id.startsWith('lib_')), isTrue);
    expect(library.every((c) => c.exercise.imageUrls.length == 2), isTrue);
    expect(library.every((c) => c.pattern == null), isTrue);
    // Sin ids repetidos.
    expect(all.map((c) => c.exercise.id).toSet(), hasLength(all.length));
  });

  test('las fotos apuntan a free-exercise-db', () {
    final bench = kExerciseCatalog.firstWhere((c) => c.exercise.id == 'bench');
    expect(bench.exercise.imageUrls, [
      '${kExerciseImageBase}Barbell_Bench_Press_-_Medium_Grip/0.jpg',
      '${kExerciseImageBase}Barbell_Bench_Press_-_Medium_Grip/1.jpg',
    ]);
  });

  test('rutinas guardadas sin fotos las recuperan por id', () {
    // Las rutinas de ejemplo se crearon antes de las fotos.
    expect(exBench.imageUrls, isEmpty);
    expect(exerciseImages(exBench), isNotEmpty);
  });

  test('las rutinas recomendadas ya incluyen fotos', () {
    final plan = RoutineRecommender().recommend(const RecommendationInput(
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      level: ExperienceLevel.intermediate,
      access: EquipmentAccess.gym,
      minutes: 60,
    ));
    final withPhotos = plan.routines
        .expand((r) => r.exercises)
        .where((e) => e.imageUrls.isNotEmpty);
    expect(withPhotos, isNotEmpty);
  });

  test('las fotos se guardan y se leen del mapa', () {
    final e = kExerciseCatalog.first.exercise;
    expect(exerciseFromMap(exerciseToMap(e)).imageUrls, e.imageUrls);
    expect(exerciseFromMap(const {'id': 'x', 'name': 'X'}).imageUrls, isEmpty);
  });
}
