import 'package:get/get.dart';

import '../../core/di/dependency_injection.dart';
import '../home/home_controller.dart';
import '../progress/progress_controller.dart';
import '../workout/workout_controller.dart';
import 'shell_controller.dart';

/// Controladores de la app. Son permanentes porque las pestañas viven en un
/// IndexedStack: la sesión de entrenamiento sigue corriendo aunque cambies de
/// pestaña.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShellController(), permanent: true);
    Get.put(
      HomeController(Get.find(), userId: kCurrentUserId),
      permanent: true,
    );
    Get.put(
      WorkoutController(
        routines: Get.find(),
        getPrevious: Get.find(),
        finishWorkout: Get.find(),
        userId: kCurrentUserId,
      ),
      permanent: true,
    );
    Get.put(
      ProgressController(
        workouts: Get.find(),
        bodyMetrics: Get.find(),
        userId: kCurrentUserId,
      ),
      permanent: true,
    );
  }
}
