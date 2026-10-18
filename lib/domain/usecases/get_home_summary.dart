import '../entities/entities.dart';
import '../metrics/progress_metrics.dart';
import '../repositories/repositories.dart';
import '../utils/date_utils.dart';

enum DayStatus { done, today, upcoming, rest }

class WeekDay {
  final String initial;
  final DayStatus status;
  const WeekDay(this.initial, this.status);
}

class MetricValue {
  final String label;
  final String value;
  final MetricAccent accent;
  const MetricValue(this.label, this.value, this.accent);
}

class HomeSummary {
  final UserProfile profile;
  final DateTime now;
  final Routine? todayRoutine;
  final bool trainedToday;
  final List<MetricValue> metrics;
  final List<WeekDay> week;
  final int weeklyDone;
  final WorkoutSession? lastSession;

  const HomeSummary({
    required this.profile,
    required this.now,
    required this.todayRoutine,
    required this.trainedToday,
    required this.metrics,
    required this.week,
    required this.weeklyDone,
    required this.lastSession,
  });
}

/// Caso de uso de la pantalla de Inicio. Solo conoce contratos
/// (repositorios y métricas), nunca una implementación concreta.
class GetHomeSummary {
  final WorkoutRepository workouts;
  final RoutineRepository routines;
  final ProfileRepository profiles;
  final List<ProgressMetric> metrics;
  final DateTime Function() clock;

  GetHomeSummary({
    required this.workouts,
    required this.routines,
    required this.profiles,
    required this.metrics,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  Stream<HomeSummary> call(String userId) async* {
    final profile = await profiles.getProfile(userId);
    final allRoutines = await routines.getRoutines(userId);

    await for (final sessions in workouts.watchSessions(userId)) {
      yield _build(profile, allRoutines, sessions, clock());
    }
  }

  HomeSummary _build(
    UserProfile profile,
    List<Routine> allRoutines,
    List<WorkoutSession> sessions,
    DateTime now,
  ) {
    final sorted = [...sessions]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final today = dayOnly(now);
    final trainedDays = sorted.map((s) => dayOnly(s.startedAt)).toSet();
    final plannedDays = allRoutines.expand((r) => r.weekdays).toSet();

    Routine? todayRoutine;
    for (final r in allRoutines) {
      if (r.weekdays.contains(now.weekday)) {
        todayRoutine = r;
        break;
      }
    }

    final monday = startOfWeek(now);
    final week = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final DayStatus status;
      if (trainedDays.contains(day)) {
        status = DayStatus.done;
      } else if (day == today) {
        status = DayStatus.today;
      } else if (plannedDays.contains(day.weekday) && day.isAfter(today)) {
        status = DayStatus.upcoming;
      } else {
        status = DayStatus.rest;
      }
      return WeekDay(weekdayInitials[i], status);
    });

    return HomeSummary(
      profile: profile,
      now: now,
      todayRoutine: todayRoutine,
      trainedToday: trainedDays.contains(today),
      metrics: [
        for (final m in metrics)
          MetricValue(
            m.label,
            m.compute(sessions: sorted, profile: profile, now: now),
            m.accent,
          ),
      ],
      week: week,
      weeklyDone: week.where((d) => d.status == DayStatus.done).length,
      lastSession: sorted.isEmpty ? null : sorted.first,
    );
  }
}
