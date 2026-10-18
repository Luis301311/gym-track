import '../entities/entities.dart';
import '../utils/date_utils.dart';

enum ProgressRange { week, month, year }

extension ProgressRangeX on ProgressRange {
  String get label => switch (this) {
        ProgressRange.week => 'Sem',
        ProgressRange.month => 'Mes',
        ProgressRange.year => 'Año',
      };

  /// "esta semana", "este mes", "este año".
  String get periodName => switch (this) {
        ProgressRange.week => 'esta semana',
        ProgressRange.month => 'este mes',
        ProgressRange.year => 'este año',
      };

  int get days => switch (this) {
        ProgressRange.week => 7,
        ProgressRange.month => 30,
        ProgressRange.year => 365,
      };
}

class ChartBar {
  final String label;
  final double value;
  final bool isCurrent;
  const ChartBar(this.label, this.value, {this.isCurrent = false});
}

class WeightTrend {
  /// Registros dentro del rango, del más antiguo al más reciente.
  final List<BodyWeightEntry> points;

  /// Último peso registrado (aunque sea anterior al rango).
  final double? current;

  /// Diferencia entre el primer y el último registro del rango.
  final double? change;

  const WeightTrend({required this.points, this.current, this.change});
}

class VolumeTrend {
  final String title;
  final List<ChartBar> bars;
  final double total;

  /// Variación porcentual contra el periodo anterior equivalente.
  final double? changePct;

  const VolumeTrend({
    required this.title,
    required this.bars,
    required this.total,
    this.changePct,
  });
}

class RecordEntry {
  final Exercise exercise;
  final WorkoutSet set;
  final DateTime date;
  const RecordEntry(this.exercise, this.set, this.date);
}

class ProgressSummary {
  final ProgressRange range;
  final WeightTrend weight;
  final VolumeTrend volume;
  final List<RecordEntry> records;
  final int sessionsInRange;

  const ProgressSummary({
    required this.range,
    required this.weight,
    required this.volume,
    required this.records,
    required this.sessionsInRange,
  });
}

const _monthInitials = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

/// Calcula todo lo que muestra la pantalla Progreso. Función pura: recibe los
/// datos ya cargados y no depende de ningún backend, por eso es fácil de probar.
ProgressSummary buildProgressSummary({
  required List<WorkoutSession> sessions,
  required List<BodyWeightEntry> weights,
  required ProgressRange range,
  required DateTime now,
}) {
  final today = dayOnly(now);
  final rangeStart = today.subtract(Duration(days: range.days - 1));

  // --- Peso corporal
  final sortedWeights = [...weights]..sort((a, b) => a.date.compareTo(b.date));
  final inRange =
      sortedWeights.where((w) => !dayOnly(w.date).isBefore(rangeStart)).toList();
  final weight = WeightTrend(
    points: inRange,
    current: sortedWeights.isEmpty ? null : sortedWeights.last.kg,
    change: inRange.length < 2 ? null : inRange.last.kg - inRange.first.kg,
  );

  // --- Volumen por periodos
  double volumeBetween(DateTime from, DateTime to) => sessions
      .where((s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to))
      .fold(0.0, (acc, s) => acc + s.volume);

  final List<ChartBar> bars;
  final DateTime periodStart;
  final DateTime previousStart;
  final String title;

  switch (range) {
    case ProgressRange.week:
      final monday = startOfWeek(now);
      title = 'Volumen de la semana';
      bars = List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        return ChartBar(
          weekdayInitials[i],
          volumeBetween(day, day.add(const Duration(days: 1))),
          isCurrent: day == today,
        );
      });
      periodStart = monday;
      previousStart = monday.subtract(const Duration(days: 7));
    case ProgressRange.month:
      const weeks = 5;
      final thisMonday = startOfWeek(now);
      final first = thisMonday.subtract(const Duration(days: 7 * (weeks - 1)));
      title = 'Volumen por semana';
      bars = List.generate(weeks, (i) {
        final start = first.add(Duration(days: 7 * i));
        return ChartBar(
          '${start.day}/${start.month}',
          volumeBetween(start, start.add(const Duration(days: 7))),
          isCurrent: i == weeks - 1,
        );
      });
      periodStart = first;
      previousStart = first.subtract(const Duration(days: 7 * weeks));
    case ProgressRange.year:
      final firstMonth = DateTime(now.year, now.month - 11);
      title = 'Volumen por mes';
      bars = List.generate(12, (i) {
        final start = DateTime(firstMonth.year, firstMonth.month + i);
        final end = DateTime(start.year, start.month + 1);
        return ChartBar(
          _monthInitials[start.month - 1],
          volumeBetween(start, end),
          isCurrent: i == 11,
        );
      });
      periodStart = firstMonth;
      previousStart = DateTime(firstMonth.year - 1, firstMonth.month);
  }

  final periodEnd = today.add(const Duration(days: 1));
  final total = volumeBetween(periodStart, periodEnd);
  // Periodo anterior del mismo largo, hasta el mismo punto relativo.
  final previous =
      volumeBetween(previousStart, previousStart.add(periodEnd.difference(periodStart)));
  final volume = VolumeTrend(
    title: title,
    bars: bars,
    total: total,
    changePct: previous > 0 ? (total - previous) / previous * 100 : null,
  );

  // --- Récords: la serie más pesada de cada ejercicio (en todo el historial)
  final best = <String, RecordEntry>{};
  for (final s in sessions) {
    for (final log in s.logs) {
      final set = log.bestSet;
      if (set == null || set.weightKg <= 0) continue;
      final current = best[log.exercise.id];
      final better = current == null ||
          set.weightKg > current.set.weightKg ||
          (set.weightKg == current.set.weightKg && set.reps > current.set.reps);
      if (better) best[log.exercise.id] = RecordEntry(log.exercise, set, s.startedAt);
    }
  }
  final records = best.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  return ProgressSummary(
    range: range,
    weight: weight,
    volume: volume,
    records: records,
    sessionsInRange:
        sessions.where((s) => !s.startedAt.isBefore(rangeStart)).length,
  );
}
