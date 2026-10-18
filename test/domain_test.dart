import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/data/repositories/memory_repositories.dart';
import 'package:gymtrack/domain/entities/entities.dart';
import 'package:gymtrack/domain/metrics/progress_metrics.dart';
import 'package:gymtrack/domain/usecases/get_home_summary.dart';

WorkoutSession _session(DateTime day, {double kg = 100, int reps = 10}) =>
    WorkoutSession(
      id: day.toIso8601String(),
      routineName: 'Test',
      startedAt: day.add(const Duration(hours: 18)),
      logs: [
        ExerciseLog(
          exercise: const Exercise(id: 'x', name: 'X', muscleGroup: 'X'),
          sets: [WorkoutSet(reps: reps, weightKg: kg)],
        ),
      ],
    );

void main() {
  // Jueves 15 de octubre de 2026
  final now = DateTime(2026, 10, 15, 10);
  const profile = UserProfile(id: 'u', name: 'Luis Vega', goal: '', weeklyGoal: 5);

  group('Métricas', () {
    test('racha cuenta días seguidos aunque hoy no se haya entrenado', () {
      final sessions = [
        _session(DateTime(2026, 10, 14)),
        _session(DateTime(2026, 10, 13)),
        _session(DateTime(2026, 10, 12)),
        _session(DateTime(2026, 10, 10)), // hueco el 11
      ];
      expect(
        StreakMetric().compute(sessions: sessions, profile: profile, now: now),
        '3',
      );
    });

    test('entrenos de la semana contra la meta', () {
      final sessions = [
        _session(DateTime(2026, 10, 12)),
        _session(DateTime(2026, 10, 13)),
        _session(DateTime(2026, 10, 11)), // domingo de la semana pasada
      ];
      expect(
        WeeklyCountMetric()
            .compute(sessions: sessions, profile: profile, now: now),
        '2/5',
      );
    });

    test('volumen en toneladas', () {
      final sessions = [
        _session(DateTime(2026, 10, 12), kg: 100, reps: 50), // 5000 kg
        _session(DateTime(2026, 10, 13), kg: 100, reps: 34), // 3400 kg
      ];
      expect(
        WeeklyVolumeMetric()
            .compute(sessions: sessions, profile: profile, now: now),
        '8.4 t',
      );
    });

    test('las series no completadas no suman volumen', () {
      const set = WorkoutSet(reps: 10, weightKg: 50, completed: false);
      expect(set.volume, 0);
    });
  });

  group('GetHomeSummary', () {
    test('arma el resumen con la implementación en memoria', () async {
      final useCase = GetHomeSummary(
        workouts: InMemoryWorkoutRepository(),
        routines: InMemoryRoutineRepository(),
        profiles: InMemoryProfileRepository(),
        metrics: [StreakMetric(), WeeklyCountMetric(), WeeklyVolumeMetric()],
      );
      final summary = await useCase('demo').first;

      expect(summary.profile.initials, 'LV');
      expect(summary.metrics, hasLength(3));
      expect(summary.week, hasLength(7));
      expect(summary.lastSession, isNotNull);
    });

    test('agregar una métrica nueva no exige cambiar el caso de uso', () async {
      final useCase = GetHomeSummary(
        workouts: InMemoryWorkoutRepository(),
        routines: InMemoryRoutineRepository(),
        profiles: InMemoryProfileRepository(),
        metrics: [_TotalSessionsMetric()],
      );
      final summary = await useCase('demo').first;
      expect(summary.metrics.single.label, 'Total');
    });
  });
}

class _TotalSessionsMetric extends ProgressMetric {
  @override
  String get label => 'Total';
  @override
  MetricAccent get accent => MetricAccent.blue;
  @override
  String compute({
    required List<WorkoutSession> sessions,
    required UserProfile profile,
    required DateTime now,
  }) =>
      '${sessions.length}';
}
