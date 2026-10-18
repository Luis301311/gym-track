import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/di/dependency_injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/shell/app_binding.dart';
import 'presentation/shell/shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
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
      initialBinding: AppBinding(),
      home: const ShellPage(),
    );
  }
}
