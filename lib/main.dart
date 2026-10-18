import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/di/dependency_injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/auth_controller.dart';
import 'presentation/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  Get.put(
    AuthController(auth: Get.find(), ensureStarterData: Get.find()),
    permanent: true,
  );
  runApp(const GymTrackApp());
}

class GymTrackApp extends StatelessWidget {
  const GymTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GymTrack',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}
