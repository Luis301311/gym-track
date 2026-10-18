import 'package:get/get.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/routine_recommender.dart';

class RoutinesController extends GetxController {
  final RoutineRepository routines;
  final RoutineWriteRepository writer;
  final RoutineRecommender recommender;
  final String userId;

  /// Se llama al cambiar las rutinas para que Entrenar, Inicio y Perfil se
  /// actualicen, sin que este controlador los conozca.
  final void Function()? onChanged;

  RoutinesController({
    required this.routines,
    required this.writer,
    required this.recommender,
    required this.userId,
    this.onChanged,
  });

  final list = <Routine>[].obs;
  final loading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      list.assignAll(await routines.getRoutines(userId));
    } catch (e) {
      error.value = 'No se pudieron cargar tus rutinas: $e';
    } finally {
      loading.value = false;
    }
  }

  String newId() => 'r${DateTime.now().microsecondsSinceEpoch}';

  /// Guarda (crea o edita) una rutina. Devuelve un mensaje de error o null.
  Future<String?> save(Routine r) async {
    if (r.name.trim().isEmpty) return 'Ponle un nombre a la rutina.';
    if (r.exercises.isEmpty) return 'Agrega al menos un ejercicio.';
    try {
      await writer.saveRoutine(userId, r);
    } catch (e) {
      return 'No se pudo guardar la rutina: $e';
    }
    await _changed();
    return null;
  }

  Future<String?> delete(String routineId) async {
    try {
      await writer.deleteRoutine(userId, routineId);
    } catch (e) {
      return 'No se pudo eliminar la rutina: $e';
    }
    await _changed();
    return null;
  }

  RoutineRecommendation recommend(RecommendationInput input) =>
      recommender.recommend(
        input,
        idPrefix: 'rec${DateTime.now().millisecondsSinceEpoch}',
      );

  /// Guarda un plan recomendado. Con [replace] borra antes las rutinas
  /// actuales; si no, las nuevas se suman a las existentes.
  Future<String?> saveRecommendation(
    RoutineRecommendation plan, {
    required bool replace,
  }) async {
    try {
      if (replace) {
        for (final r in [...list]) {
          await writer.deleteRoutine(userId, r.id);
        }
      }
      for (final r in plan.routines) {
        await writer.saveRoutine(userId, r);
      }
    } catch (e) {
      return 'No se pudo guardar el plan: $e';
    }
    await _changed();
    return null;
  }

  Future<void> _changed() async {
    await load();
    onChanged?.call();
  }
}
