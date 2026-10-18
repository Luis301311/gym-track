import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/repositories/asset_exercise_library.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_repositories.dart';
import '../../data/repositories/memory_repositories.dart';
import '../../domain/metrics/progress_metrics.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/account_usecases.dart';
import '../../domain/usecases/get_home_summary.dart';
import '../../domain/usecases/routine_recommender.dart';
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

/// Con --dart-define=EMULATORS=true el backend Firebase usa los emuladores
/// locales (Auth y Firestore) en vez de la nube.
const useFirebaseEmulators = bool.fromEnvironment('EMULATORS');

Backend get currentBackend => Backend.values.firstWhere(
      (b) => b.name == const String.fromEnvironment('BACKEND'),
      orElse: () => Backend.memory,
    );

Future<void> initDependencies() async {
  switch (currentBackend) {
    case Backend.memory:
      Get.put<WorkoutRepository>(InMemoryWorkoutRepository(), permanent: true);
      final memoryRoutines = InMemoryRoutineRepository();
      Get.put<RoutineRepository>(memoryRoutines, permanent: true);
      Get.put<RoutineWriteRepository>(memoryRoutines, permanent: true);
      Get.put<AuthRepository>(InMemoryAuthRepository(), permanent: true);
      final memoryProfiles = InMemoryProfileRepository();
      Get.put<ProfileRepository>(memoryProfiles, permanent: true);
      Get.put<ProfileWriteRepository>(memoryProfiles, permanent: true);
      Get.put<MeasurementsRepository>(InMemoryMeasurementsRepository(),
          permanent: true);
      Get.put<BodyMetricsRepository>(InMemoryBodyMetricsRepository(),
          permanent: true);
    case Backend.firebase:
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final db = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      // Caché local sin límite: la app funciona sin señal y sincroniza después.
      db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      if (useFirebaseEmulators) {
        // Firebase corriendo en tu PC (firebase emulators:start).
        // El emulador de Android ve tu PC como 10.0.2.2.
        final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';
        db.useFirestoreEmulator(host, 8080);
        await auth.useAuthEmulator(host, 9099);
      }
      Get.put<WorkoutRepository>(FirestoreWorkoutRepository(db), permanent: true);
      final firestoreRoutines = FirestoreRoutineRepository(db);
      Get.put<RoutineRepository>(firestoreRoutines, permanent: true);
      Get.put<RoutineWriteRepository>(firestoreRoutines, permanent: true);
      Get.put<AuthRepository>(FirebaseAuthRepository(auth),
          permanent: true);
      final firestoreProfiles = FirestoreProfileRepository(db);
      Get.put<ProfileRepository>(firestoreProfiles, permanent: true);
      Get.put<ProfileWriteRepository>(firestoreProfiles, permanent: true);
      Get.put<MeasurementsRepository>(FirestoreMeasurementsRepository(db),
          permanent: true);
      Get.put<BodyMetricsRepository>(FirestoreBodyMetricsRepository(db),
          permanent: true);
  }

  // Biblioteca de ejercicios: igual para cualquier backend (va dentro de la app).
  Get.put<ExerciseLibraryRepository>(AssetExerciseLibrary(), permanent: true);

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
  Get.lazyPut(() => RoutineRecommender(), fenix: true);
  Get.lazyPut(
    () => EnsureStarterData(
      routines: Get.find(),
      routineWriter: Get.find(),
      profileWriter: Get.find(),
    ),
    fenix: true,
  );
}
