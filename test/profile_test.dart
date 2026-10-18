import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/data/repositories/memory_repositories.dart';
import 'package:gymtrack/domain/entities/entities.dart';
import 'package:gymtrack/domain/usecases/profile_summary.dart';
import 'package:gymtrack/presentation/profile/profile_controller.dart';

const _profile = UserProfile(id: 'u', name: 'Luis Vega', goal: 'Masa');

BodyMeasurement _m(int day, Map<String, double> v) =>
    BodyMeasurement(id: 'm$day', date: DateTime(2026, 10, day), valuesCm: v);

void main() {
  group('buildProfileSummary', () {
    test('valor actual y cambio por medida, con dirección buena o mala', () {
      final s = buildProfileSummary(
        profile: _profile,
        sessions: const [],
        weights: [
          BodyWeightEntry(id: 'a', date: DateTime(2026, 10, 1), kg: 79),
          BodyWeightEntry(id: 'b', date: DateTime(2026, 10, 10), kg: 78.4),
        ],
        measurements: [
          _m(10, {'chest': 102, 'arm': 36, 'waist': 82}),
          _m(1, {'chest': 100, 'arm': 36.5, 'waist': 83.5}),
        ],
      );

      expect(s.currentWeightKg, 78.4);
      final byKey = {for (final m in s.measurements) m.type.key: m};
      expect(byKey['chest']!.deltaCm, 2);
      expect(byKey['chest']!.improved, isTrue); // subir pecho es bueno
      expect(byKey['arm']!.improved, isFalse); // bajó el brazo
      expect(byKey['waist']!.deltaCm, -1.5);
      expect(byKey['waist']!.improved, isTrue); // bajar cintura es bueno
      expect(s.lastMeasuredAt, DateTime(2026, 10, 10));
    });

    test('una medida que no se registró en la última toma usa la anterior', () {
      final s = buildProfileSummary(
        profile: _profile,
        sessions: const [],
        weights: const [],
        measurements: [
          _m(10, {'chest': 102}),
          _m(1, {'chest': 100, 'arm': 35}),
        ],
      );
      final arm = s.measurements.firstWhere((m) => m.type.key == 'arm');
      expect(arm.valueCm, 35);
      expect(arm.deltaCm, isNull);
      expect(s.measurements.any((m) => m.type.key == 'waist'), isFalse);
    });
  });

  group('ProfileController', () {
    late InMemoryProfileRepository profiles;
    late InMemoryMeasurementsRepository measurements;
    late ProfileController c;
    var refreshed = 0;

    setUp(() async {
      profiles = InMemoryProfileRepository();
      measurements = InMemoryMeasurementsRepository();
      refreshed = 0;
      c = ProfileController(
        profiles: profiles,
        profileWriter: profiles,
        workouts: InMemoryWorkoutRepository(),
        bodyMetrics: InMemoryBodyMetricsRepository(),
        measurements: measurements,
        routines: InMemoryRoutineRepository(),
        userId: 'u',
        onProfileChanged: () => refreshed++,
      );
      await c.load();
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => c.onClose());

    test('carga el resumen con datos de ejemplo', () {
      final s = c.summary.value!;
      expect(s.profile.name, 'Luis Vega');
      expect(s.profile.heightCm, 175);
      expect(s.measurements, hasLength(3));
      expect(c.routineList, isNotEmpty);
    });

    test('guardar perfil valida, persiste y avisa a Inicio', () async {
      expect(
          await c.saveProfile(
              name: '  ', goal: '', heightCm: '', weeklyGoal: 4),
          isNotNull);
      expect(
          await c.saveProfile(
              name: 'Luis', goal: '', heightCm: '20', weeklyGoal: 4),
          isNotNull);

      final msg = await c.saveProfile(
          name: 'Luis V.', goal: 'Fuerza', heightCm: '176,5', weeklyGoal: 4);
      expect(msg, isNull);
      expect(refreshed, 1);
      final saved = await profiles.getProfile('u');
      expect(saved.name, 'Luis V.');
      expect(saved.heightCm, 176.5);
      expect(saved.weeklyGoal, 4);
      expect(c.summary.value!.profile.goal, 'Fuerza');
    });

    test('agregar medidas ignora campos vacíos y valida valores', () async {
      expect(await c.addMeasurement({'chest': '', 'arm': ''}), isNotNull);
      expect(await c.addMeasurement({'chest': '5'}), isNotNull);

      expect(await c.addMeasurement({'chest': '104', 'waist': '81,5'}), isNull);
      await Future<void>.delayed(Duration.zero);

      final byKey = {
        for (final m in c.summary.value!.measurements) m.type.key: m
      };
      expect(byKey['chest']!.valueCm, 104);
      expect(byKey['chest']!.deltaCm, 2);
      expect(byKey['waist']!.valueCm, 81.5);
      expect(byKey['arm']!.valueCm, 36); // sin cambio: se mantiene la anterior
    });
  });
}
