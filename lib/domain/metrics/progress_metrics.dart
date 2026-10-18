import '../entities/entities.dart';
import '../utils/date_utils.dart';

/// Color de acento de una métrica, sin depender de Flutter.
enum MetricAccent { primary, orange, blue }

/// OPEN/CLOSED aplicado a las tarjetas de estadísticas de Inicio:
/// para mostrar una métrica nueva (p. ej. "Récords este mes") se crea otra
/// clase que extienda [ProgressMetric] y se agrega a la lista registrada en la
/// inyección de dependencias. El controlador y la UI no cambian.
abstract class ProgressMetric {
  String get label;
  MetricAccent get accent;

  String compute({
    required List<WorkoutSession> sessions,
    required UserProfile profile,
    required DateTime now,
  });
}

/// Días seguidos entrenando, contando hacia atrás desde hoy (o ayer si hoy
/// todavía no se ha entrenado).
class StreakMetric extends ProgressMetric {
  @override
  String get label => 'Racha (días)';

  @override
  MetricAccent get accent => MetricAccent.primary;

  @override
  String compute({
    required List<WorkoutSession> sessions,
    required UserProfile profile,
    required DateTime now,
  }) {
    final days = sessions.map((s) => dayOnly(s.startedAt)).toSet();
    var cursor = dayOnly(now);
    if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return '$streak';
  }
}

/// Entrenamientos hechos esta semana frente a la meta semanal.
class WeeklyCountMetric extends ProgressMetric {
  @override
  String get label => 'Esta semana';

  @override
  MetricAccent get accent => MetricAccent.orange;

  @override
  String compute({
    required List<WorkoutSession> sessions,
    required UserProfile profile,
    required DateTime now,
  }) {
    final done = sessionsThisWeek(sessions, now)
        .map((s) => dayOnly(s.startedAt))
        .toSet()
        .length;
    return '$done/${profile.weeklyGoal}';
  }
}

/// Volumen total levantado esta semana (en toneladas si pasa de 1000 kg).
class WeeklyVolumeMetric extends ProgressMetric {
  @override
  String get label => 'Volumen';

  @override
  MetricAccent get accent => MetricAccent.blue;

  @override
  String compute({
    required List<WorkoutSession> sessions,
    required UserProfile profile,
    required DateTime now,
  }) {
    final kg = sessionsThisWeek(sessions, now)
        .fold<double>(0, (acc, s) => acc + s.volume);
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)} t';
    return '${kg.toStringAsFixed(0)} kg';
  }
}
