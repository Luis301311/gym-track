import 'package:get/get.dart';

import '../home/home_controller.dart';
import '../profile/profile_controller.dart';
import '../progress/progress_controller.dart';
import '../routines/routines_controller.dart';
import '../workout/workout_controller.dart';
import 'shell_controller.dart';

/// Controladores de una sesión de usuario. Se crean al iniciar sesión con el
/// uid real y se destruyen al cerrarla, así nunca se mezclan datos de cuentas.
///
/// Son `permanent` para que GetX no los borre solo al cambiar de ruta: su
/// ciclo de vida lo controla la sesión (ver `_SessionScope` en auth_gate.dart).
class SessionBinding extends Bindings {
  final String userId;
  SessionBinding(this.userId);

  @override
  void dependencies() {
    Get.put(ShellController(), permanent: true);
    Get.put(HomeController(Get.find(), userId: userId), permanent: true);
    Get.put(
      WorkoutController(
        routines: Get.find(),
        getPrevious: Get.find(),
        finishWorkout: Get.find(),
        getSuggestions: Get.find(),
        userId: userId,
      ),
      permanent: true,
    );
    Get.put(
      ProgressController(
        workouts: Get.find(),
        bodyMetrics: Get.find(),
        userId: userId,
      ),
      permanent: true,
    );
    Get.put(
      ProfileController(
        profiles: Get.find(),
        profileWriter: Get.find(),
        workouts: Get.find(),
        bodyMetrics: Get.find(),
        measurements: Get.find(),
        routines: Get.find(),
        userId: userId,
        // Inicio muestra el nombre y la meta semanal: se recarga al editar.
        onProfileChanged: () => Get.find<HomeController>().load(),
      ),
      permanent: true,
    );
    Get.put(
      RoutinesController(
        routines: Get.find(),
        writer: Get.find(),
        recommender: Get.find(),
        userId: userId,
        // Las pantallas que muestran rutinas se recargan al cambiarlas.
        onChanged: () {
          Get.find<WorkoutController>().loadRoutines();
          Get.find<HomeController>().load();
          Get.find<ProfileController>().load();
        },
      ),
      permanent: true,
    );
  }

  /// Destruye los controladores de la sesión de [userId] (si siguen siendo
  /// de ese usuario). Cancela timers y suscripciones vía `onClose`.
  static void dispose(String userId) {
    final owns = Get.isRegistered<HomeController>() &&
        Get.find<HomeController>().userId == userId;
    if (!owns) return;
    Get.delete<RoutinesController>(force: true);
    Get.delete<ProfileController>(force: true);
    Get.delete<ProgressController>(force: true);
    Get.delete<WorkoutController>(force: true);
    Get.delete<HomeController>(force: true);
    Get.delete<ShellController>(force: true);
  }
}
