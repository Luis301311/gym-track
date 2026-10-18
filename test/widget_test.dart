import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gymtrack/core/di/dependency_injection.dart';
import 'package:gymtrack/presentation/shell/app_binding.dart';
import 'package:gymtrack/presentation/shell/shell_page.dart';
import 'package:gymtrack/presentation/workout/workout_controller.dart';

/// Arranca la app con el backend en memoria. Usa un tema sin google_fonts
/// para que la prueba no intente descargar fuentes.
Future<void> pumpApp(WidgetTester tester) async {
  await initDependencies();
  await tester.pumpWidget(GetMaterialApp(
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    initialBinding: AppBinding(),
    home: const ShellPage(),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  tearDown(Get.reset);

  testWidgets('Inicio muestra el saludo y las métricas', (tester) async {
    await pumpApp(tester);

    expect(find.text('Hola, Luis'), findsOneWidget);
    expect(find.text('Racha (días)'), findsOneWidget);
    expect(find.text('Esta semana'), findsWidgets);
    expect(find.text('Volumen'), findsOneWidget);
  });

  testWidgets('Entrenar: elegir rutina, completar una serie y descartar',
      (tester) async {
    await pumpApp(tester);

    // Ir a la pestaña Entrenar.
    await tester.tap(find.text('Entrenar').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Elige una rutina para empezar'), findsOneWidget);

    // Empezar Push Day.
    await tester.tap(find.text('Push Day'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Entrenamiento en curso'), findsOneWidget);
    expect(find.text('Press de banca'), findsOneWidget);

    // Completar la primera serie con los valores sugeridos (vez anterior).
    final c = Get.find<WorkoutController>();
    await tester.tap(find.byIcon(Icons.check_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.doneSets, 1);
    expect(find.text('Descanso'), findsOneWidget);

    // Limpiar timers antes de terminar la prueba.
    c.discard();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Elige una rutina para empezar'), findsOneWidget);
  });

  testWidgets('Progreso muestra peso corporal y volumen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Progreso').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Peso corporal'), findsOneWidget);
    expect(find.text('Volumen por semana'), findsOneWidget);

    // Cambiar a semana.
    await tester.tap(find.text('Sem'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Volumen de la semana'), findsOneWidget);
  });
}
