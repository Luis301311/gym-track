import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gymtrack/core/di/dependency_injection.dart';
import 'package:gymtrack/presentation/shell/session_binding.dart';
import 'package:gymtrack/presentation/shell/shell_page.dart';
import 'package:gymtrack/presentation/workout/workout_controller.dart';

/// Arranca la app con el backend en memoria. Usa un tema sin google_fonts
/// para que la prueba no intente descargar fuentes.
Future<void> pumpApp(WidgetTester tester) async {
  await initDependencies();
  SessionBinding('demo-user').dependencies();
  await tester.pumpWidget(GetMaterialApp(
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
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

    // Completar la primera serie con el objetivo de hoy (campos vacíos).
    final c = Get.find<WorkoutController>();
    await tester.tap(find.byIcon(Icons.check_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.doneSets, 1);
    expect(c.isResting, isTrue);
    // La tarjeta de descanso puede quedar más abajo del área visible de la
    // prueba (800×600), por eso se busca también fuera de pantalla.
    expect(find.text('Descanso', skipOffstage: false), findsOneWidget);

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

  testWidgets('Perfil muestra datos, estadísticas y medidas', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Perfil').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Luis Vega'), findsOneWidget);
    expect(find.text('1.75 m'), findsOneWidget);
    expect(find.text('Medidas corporales'), findsOneWidget);
    expect(find.text('Pecho'), findsOneWidget);
    expect(find.text('102 cm'), findsOneWidget);
  });
}
