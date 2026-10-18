import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gymtrack/core/di/dependency_injection.dart';
import 'package:gymtrack/data/repositories/memory_repositories.dart';
import 'package:gymtrack/domain/catalog/starter_routines.dart';
import 'package:gymtrack/domain/entities/entities.dart';
import 'package:gymtrack/domain/repositories/auth_repository.dart';
import 'package:gymtrack/domain/repositories/repositories.dart';
import 'package:gymtrack/domain/usecases/account_usecases.dart';
import 'package:gymtrack/presentation/auth/auth_controller.dart';
import 'package:gymtrack/presentation/auth/auth_gate.dart';

/// Repositorio de rutinas que arranca vacío, como una cuenta nueva.
class _EmptyRoutines implements RoutineRepository, RoutineWriteRepository {
  final saved = <Routine>[];

  @override
  Future<List<Routine>> getRoutines(String userId) async => saved;

  @override
  Future<void> saveRoutine(String userId, Routine routine) async =>
      saved.add(routine);

  @override
  Future<void> deleteRoutine(String userId, String routineId) async =>
      saved.removeWhere((r) => r.id == routineId);
}

void main() {
  group('EnsureStarterData', () {
    test('por defecto la cuenta nueva arranca sin rutinas', () async {
      final routines = _EmptyRoutines();
      final profiles = InMemoryProfileRepository();
      await EnsureStarterData(
        routines: routines,
        routineWriter: routines,
        profileWriter: profiles,
      )('u1', newAccountName: 'Ana');
      expect(routines.saved, isEmpty);
      expect((await profiles.getProfile('u1')).name, 'Ana');
    });

    test('con rutinas de inicio configuradas, las siembra', () async {
      final routines = _EmptyRoutines();
      final profiles = InMemoryProfileRepository();
      final ensure = EnsureStarterData(
        routines: routines,
        routineWriter: routines,
        profileWriter: profiles,
        starter: kStarterRoutines,
      );

      await ensure('u1', newAccountName: 'Ana');

      expect(routines.saved.map((r) => r.id),
          kStarterRoutines.map((r) => r.id));
      expect((await profiles.getProfile('u1')).name, 'Ana');
    });

    test('cuenta existente: no duplica rutinas', () async {
      final routines = _EmptyRoutines()..saved.add(kStarterRoutines.first);
      final ensure = EnsureStarterData(
        routines: routines,
        routineWriter: routines,
        profileWriter: InMemoryProfileRepository(),
        starter: kStarterRoutines,
      );
      await ensure('u1');
      expect(routines.saved, hasLength(1));
    });
  });

  group('AuthController', () {
    late InMemoryAuthRepository auth;
    late _EmptyRoutines routines;
    late InMemoryProfileRepository profiles;
    late AuthController c;

    setUp(() async {
      auth = InMemoryAuthRepository(signedIn: false);
      routines = _EmptyRoutines();
      profiles = InMemoryProfileRepository();
      c = AuthController(
        auth: auth,
        ensureStarterData: EnsureStarterData(
          routines: routines,
          routineWriter: routines,
          profileWriter: profiles,
        ),
      )..onInit();
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => c.onClose());

    test('arranca sin sesión', () {
      expect(c.status.value, AuthStatus.signedOut);
    });

    test('valida antes de llamar al backend', () async {
      expect(await c.signIn('no-es-correo', '123456'), isNotNull);
      expect(await c.signIn('luis@test.com', '123'), isNotNull);
      expect(await c.signUp('', 'luis@test.com', '123456'), isNotNull);
      expect(c.status.value, AuthStatus.signedOut);
    });

    test('registro: guarda el perfil con el nombre y entra', () async {
      expect(await c.signUp('Luis', 'luis@test.com', '123456'), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(c.status.value, AuthStatus.signedIn);
      expect(routines.saved, isEmpty); // la persona arma o pide su rutina
      expect((await profiles.getProfile(c.user.value!.uid)).name, 'Luis');
    });

    test('cerrar sesión vuelve al login', () async {
      await c.signIn('luis@test.com', '123456');
      await Future<void>.delayed(Duration.zero);
      expect(c.status.value, AuthStatus.signedIn);

      await c.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(c.status.value, AuthStatus.signedOut);
      expect(c.user.value, isNull);
    });
  });

  testWidgets('login → Inicio → cerrar sesión', (tester) async {
    await initDependencies();
    final auth = InMemoryAuthRepository(signedIn: false);
    Get.replace<AuthRepository>(auth);
    Get.put(AuthController(auth: auth, ensureStarterData: Get.find()),
        permanent: true);

    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const AuthGate(),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Entra para seguir con tu progreso'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'luis@test.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Iniciar sesión').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Hola, Luis'), findsOneWidget);

    await auth.signOut();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Entra para seguir con tu progreso'), findsOneWidget);

    Get.reset();
  });
}
