import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import '../../data/repositories/firestore_repositories.dart';
import '../../data/repositories/memory_repositories.dart';
import '../../domain/metrics/progress_metrics.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/get_home_summary.dart';
import '../../domain/usecases/workout_usecases.dart';
import '../../firebase_options.dart';

/// Backend activo. Se elige al compilar:
///   flutter run                                  -> memoria (datos de ejemplo)
///   flutter run --dart-define=BACKEND=firebase   -> Firestore
///
/// Para agregar un backend nuevo (p. ej. una API NestJS):
///   1. Crear `ApiWorkoutRepository implements WorkoutRepository`, etc.
///   2. Agregar un valor al enum y un `case` aquí.
/// Ninguna pantalla, controlador ni caso de uso se modifica.
enum Backend { memory, firebase }

/// Usuario actual. Se reemplaza por el uid de Firebase Auth cuando se agregue
/// el inicio de sesión.
const kCurrentUserId = 'demo-user';

Backend get currentBackend => Backend.values.firstWhere(
      (b) => b.name == const String.fromEnvironment('BACKEND'),
      orElse: () => Backend.memory,
    );

Future<void> initDependencies() async {
  switch (currentBackend) {
    case Backend.memory:
      Get.put<WorkoutRepository>(InMemoryWorkoutRepository(), permanent: true);
      Get.put<RoutineRepository>(InMemoryRoutineRepository(), permanent: true);
      Get.put<ProfileRepository>(InMemoryProfileRepository(), permanent: true);
      Get.put<BodyMetricsRepository>(InMemoryBodyMetricsRepository(),
          permanent: true);
    case Backend.firebase:
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final db = FirebaseFirestore.instance;
      Get.put<WorkoutRepository>(FirestoreWorkoutRepository(db), permanent: true);
      Get.put<RoutineRepository>(FirestoreRoutineRepository(db), permanent: true);
      Get.put<ProfileRepository>(FirestoreProfileRepository(db), permanent: true);
      Get.put<BodyMetricsRepository>(FirestoreBodyMetricsRepository(db),
          permanent: true);
  }

  // Métricas de Inicio: agregar una nueva = agregar una línea aquí.
  Get.put<List<ProgressMetric>>(
    [StreakMetric(), WeeklyCountMetric(), WeeklyVolumeMetric()],
    permanent: true,
  );

  Get.lazyPut(
    () => GetHomeSummary(
      workouts: Get.find(),
      routines: Get.find(),
      profiles: Get.find(),
      metrics: Get.find(),
    ),
    fenix: true,
  );
  Get.lazyPut(() => GetPreviousPerformance(Get.find()), fenix: true);
  Get.lazyPut(() => FinishWorkout(Get.find()), fenix: true);
}
