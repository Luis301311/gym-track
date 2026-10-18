import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/domain/entities/entities.dart';
import 'package:gymtrack/domain/usecases/progress_summary.dart';
import 'package:gymtrack/domain/utils/date_utils.dart';

const _bench = Exercise(id: 'bench', name: 'Press de banca', muscleGroup: 'Pecho');
const _squat = Exercise(id: 'squat', name: 'Sentadilla', muscleGroup: 'Piernas');

/// Sesión con un solo set de 10 reps cuyo volumen total es [volume].
WorkoutSession _s(DateTime day, double volume, {Exercise e = _bench}) =>
    WorkoutSession(
      id: day.toIso8601String() + e.id,
      routineName: 'Test',
      startedAt: day.add(const Duration(hours: 18)),
      logs: [
        ExerciseLog(exercise: e, sets: [WorkoutSet(reps: 10, weightKg: volume / 10)]),
      ],
    );

BodyWeightEntry _w(DateTime d, double kg) =>
    BodyWeightEntry(id: d.toIso8601String(), date: d, kg: kg);

void main() {
  final now = DateTime(2026, 10, 15, 10); // jueves

  group('Volumen', () {
    final sessions = [
      _s(DateTime(2026, 10, 12), 1000), // lunes
      _s(DateTime(2026, 10, 14), 2000), // miércoles
      _s(DateTime(2026, 10, 5), 1500), // lunes semana pasada
    ];

    test('semana: una barra por día y hoy marcado', () {
      final v = buildProgressSummary(
              sessions: sessions, weights: [], range: ProgressRange.week, now: now)
          .volume;
      expect(v.bars.map((b) => b.label), ['L', 'M', 'M', 'J', 'V', 'S', 'D']);
      expect(v.bars[0].value, 1000);
      expect(v.bars[2].value, 2000);
      expect(v.bars[3].isCurrent, isTrue);
      expect(v.total, 3000);
    });

    test('compara contra el mismo tramo de la semana anterior', () {
      final v = buildProgressSummary(
              sessions: sessions, weights: [], range: ProgressRange.week, now: now)
          .volume;
      expect(v.changePct, closeTo(100, 0.001)); // 3000 vs 1500
    });

    test('sin periodo anterior no hay porcentaje', () {
      final v = buildProgressSummary(
              sessions: sessions.take(2).toList(),
              weights: [],
              range: ProgressRange.week,
              now: now)
          .volume;
      expect(v.changePct, isNull);
    });

    test('mes: 5 semanas; año: 12 meses terminando en el actual', () {
      final month = buildProgressSummary(
          sessions: sessions, weights: [], range: ProgressRange.month, now: now);
      expect(month.volume.bars, hasLength(5));
      expect(month.volume.bars.last.isCurrent, isTrue);
      expect(month.volume.bars.last.value, 3000);

      final year = buildProgressSummary(
          sessions: sessions, weights: [], range: ProgressRange.year, now: now);
      expect(year.volume.bars, hasLength(12));
      expect(year.volume.bars.last.label, 'O');
      expect(year.volume.bars.last.value, 4500);
    });
  });

  group('Peso corporal', () {
    final weights = [
      _w(DateTime(2026, 9, 1), 80),
      _w(DateTime(2026, 10, 14), 78.4),
      _w(DateTime(2026, 10, 1), 79.5),
    ];

    test('cambio dentro del rango y peso actual', () {
      final w = buildProgressSummary(
              sessions: [], weights: weights, range: ProgressRange.month, now: now)
          .weight;
      expect(w.points.map((p) => p.kg), [79.5, 78.4]); // ordenados por fecha
      expect(w.change, closeTo(-1.1, 0.001));
      expect(w.current, 78.4);
    });

    test('con un solo registro en el rango no hay cambio', () {
      final w = buildProgressSummary(
              sessions: [], weights: weights, range: ProgressRange.week, now: now)
          .weight;
      expect(w.points, hasLength(1));
      expect(w.change, isNull);
      expect(w.current, 78.4);
    });
  });

  test('récords: mejor serie por ejercicio, el más reciente primero', () {
    final records = buildProgressSummary(
      sessions: [
        _s(DateTime(2026, 10, 5), 700), // 70 kg
        _s(DateTime(2026, 10, 12), 725), // 72.5 kg
        _s(DateTime(2026, 9, 1), 600), // 60 kg
        _s(DateTime(2026, 10, 14), 1000, e: _squat), // 100 kg
      ],
      weights: [],
      range: ProgressRange.month,
      now: now,
    ).records;

    expect(records.map((r) => r.exercise.id), ['squat', 'bench']);
    expect(records[1].set.weightKg, 72.5);
    expect(dayOnly(records[1].date), DateTime(2026, 10, 12));
  });

  test('fechas relativas', () {
    expect(formatRelativeDay(DateTime(2026, 10, 15), now), 'hoy');
    expect(formatRelativeDay(DateTime(2026, 10, 14), now), 'ayer');
    expect(formatRelativeDay(DateTime(2026, 10, 12), now), 'hace 3 días');
    expect(formatRelativeDay(DateTime(2026, 10, 1), now), 'hace 2 semanas');
    expect(formatRelativeDay(DateTime(2026, 8, 3), now), '03/08');
  });
}
