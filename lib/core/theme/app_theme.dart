import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/metrics/progress_metrics.dart';

/// Tokens del diseño en Figma ("GymTrack Tokens").
abstract final class AppColors {
  static const bg = Color(0xFF0E0F12);
  static const surface = Color(0xFF181A20);
  static const surface2 = Color(0xFF23262F);
  static const primary = Color(0xFFC6F432);
  static const onPrimary = Color(0xFF0E0F12);
  static const text = Color(0xFFF4F5F7);
  static const muted = Color(0xFF8B90A0);
  static const orange = Color(0xFFFF8A3D);
  static const blue = Color(0xFF5B8CFF);

  static Color soft(Color c, [double alpha = 0.15]) => c.withValues(alpha: alpha);

  static Color accent(MetricAccent a) => switch (a) {
        MetricAccent.primary => primary,
        MetricAccent.orange => orange,
        MetricAccent.blue => blue,
      };
}

abstract final class AppRadius {
  static const md = 16.0;
  static const lg = 24.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}
