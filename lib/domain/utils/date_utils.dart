import '../entities/entities.dart';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lunes de la semana de [now], a las 00:00.
DateTime startOfWeek(DateTime now) =>
    dayOnly(now).subtract(Duration(days: now.weekday - DateTime.monday));

List<WorkoutSession> sessionsThisWeek(
  List<WorkoutSession> sessions,
  DateTime now,
) {
  final start = startOfWeek(now);
  final end = start.add(const Duration(days: 7));
  return sessions
      .where((s) => !s.startedAt.isBefore(start) && s.startedAt.isBefore(end))
      .toList();
}

const _weekdays = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];
const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const weekdayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// "Jueves, 15 de octubre" (sin depender de intl ni de inicializar locales).
String formatLongDateEs(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} de ${_months[d.month - 1]}';

const _weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

/// [1, 4] -> "Lun, Jue"
String formatWeekdays(List<int> days) =>
    ([...days]..sort()).map((d) => _weekdayShort[d - 1]).join(', ');

/// "hoy", "ayer", "hace 3 días", "hace 2 semanas" o "12/08".
String formatRelativeDay(DateTime date, DateTime now) {
  final days = dayOnly(now).difference(dayOnly(date)).inDays;
  if (days <= 0) return 'hoy';
  if (days == 1) return 'ayer';
  if (days < 7) return 'hace $days días';
  if (days < 30) {
    final w = days ~/ 7;
    return w == 1 ? 'hace 1 semana' : 'hace $w semanas';
  }
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
