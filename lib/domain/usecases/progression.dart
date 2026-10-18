import '../catalog/exercise_catalog.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';
import '../utils/format.dart';

/// Rango de repeticiones objetivo: "8-12" → 8..12, "10" → 10..10.
/// Los objetivos por tiempo ("30-45 s") no tienen rango de repeticiones.
class RepRange {
  final int min;
  final int max;
  const RepRange(this.min, this.max);

  static RepRange? parse(String text) {
    final t = text.trim().toLowerCase();
    // "30 s", "45 seg", "1 min" son por tiempo; "10 reps" no.
    if (RegExp(r'\d\s*(s|seg|segundos|min)\b').hasMatch(t)) return null;
    final nums = RegExp(r'\d+').allMatches(t).map((m) => int.parse(m[0]!)).toList();
    if (nums.isEmpty) return null;
    final a = nums.first, b = nums.length > 1 ? nums[1] : nums.first;
    return a <= b ? RepRange(a, b) : RepRange(b, a);
  }
}

enum ProgressionKind {
  /// Primera vez con este ejercicio: elegir un peso de prueba.
  firstTime,

  /// Completaste el tope del rango en todas las series: sube el peso.
  increase,

  /// Mantén el peso y busca una repetición más.
  hold,

  /// Dos sesiones por debajo del rango: baja el peso para recuperar.
  deload,

  /// Peso corporal en el tope: añade lastre o una variante más difícil.
  harderVariant,
}

class ProgressionSuggestion {
  final Exercise exercise;
  final ProgressionKind kind;

  /// Peso sugerido (null si es la primera vez o va por tiempo).
  final double? kg;

  /// Repeticiones a buscar en cada serie (null si va por tiempo).
  final int? reps;

  /// Explicación corta para mostrar.
  final String reason;

  const ProgressionSuggestion({
    required this.exercise,
    required this.kind,
    required this.kg,
    required this.reps,
    required this.reason,
  });

  /// "72.5 kg × 8", "PC × 12" o "8-12".
  String get target {
    if (reps == null) return exercise.targetReps;
    if (kg == null) return '× $reps';
    return formatSet(kg!, reps!);
  }
}

const _lowerMuscles = {'Piernas', 'Femoral', 'Glúteos', 'Espalda baja', 'Cuádriceps'};

/// Progresión doble: primero repeticiones, luego peso.
///
///  - Todas las series en el tope del rango  → sube el peso.
///  - Si no                                  → mismo peso, +1 repetición.
///  - Dos sesiones por debajo del mínimo     → baja ~10 % (descarga).
class ProgressionAdvisor {
  const ProgressionAdvisor();

  /// Cuánto subir según equipo y zona del cuerpo.
  double incrementFor(Exercise e) {
    final eq = e.equipment.toLowerCase();
    MovementPattern? pattern;
    for (final c in kExerciseCatalog) {
      if (c.exercise.id == e.id) {
        pattern = c.pattern;
        break;
      }
    }
    final lower = _lowerMuscles.contains(e.muscleGroup) ||
        const {
          MovementPattern.squat,
          MovementPattern.hinge,
          MovementPattern.lunge,
          MovementPattern.glutes,
        }.contains(pattern);
    if (eq.contains('mancuerna') || eq.contains('kettlebell')) return 2;
    if (eq.contains('máquina') || eq.contains('polea')) return lower ? 5 : 2.5;
    return lower ? 5 : 2.5; // barra y resto
  }

  /// [history]: series completadas del ejercicio por sesión, la más reciente
  /// primero (normalmente las 2 últimas).
  ProgressionSuggestion suggest(Exercise e, List<List<WorkoutSet>> history) {
    final range = RepRange.parse(e.targetReps);
    final sessions = history.where((s) => s.isNotEmpty).toList();

    if (sessions.isEmpty) {
      return ProgressionSuggestion(
        exercise: e,
        kind: ProgressionKind.firstTime,
        kg: null,
        reps: range?.min,
        reason: range == null
            ? 'Primera vez: busca ${e.targetReps} con buena técnica.'
            : 'Primera vez: elige un peso con el que llegues a ${range.min}-${range.max} reps con buena técnica.',
      );
    }

    final last = sessions.first;
    final kg = last.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
    final top = last.where((s) => s.weightKg == kg).toList();
    final minReps = top.map((s) => s.reps).reduce((a, b) => a < b ? a : b);

    if (range == null) {
      return ProgressionSuggestion(
        exercise: e,
        kind: ProgressionKind.hold,
        kg: kg,
        reps: null,
        reason: 'Intenta sostener un poco más que la vez anterior.',
      );
    }

    final reachedTop = top.length >= e.targetSets && minReps >= range.max;

    if (kg == 0) {
      return reachedTop
          ? ProgressionSuggestion(
              exercise: e,
              kind: ProgressionKind.harderVariant,
              kg: 0,
              reps: range.max,
              reason: 'Llegaste al tope con tu peso: añade lastre o pasa a una variante más difícil.',
            )
          : ProgressionSuggestion(
              exercise: e,
              kind: ProgressionKind.hold,
              kg: 0,
              reps: (minReps + 1).clamp(range.min, range.max),
              reason: 'Busca una repetición más por serie.',
            );
    }

    if (reachedTop) {
      final next = _round(kg + incrementFor(e));
      return ProgressionSuggestion(
        exercise: e,
        kind: ProgressionKind.increase,
        kg: next,
        reps: range.min,
        reason: 'La vez pasada hiciste ${top.length} × ${range.max} con ${formatKg(kg)} kg: sube a ${formatKg(next)} kg.',
      );
    }

    // ¿Estancado? Dos sesiones seguidas por debajo del mínimo con este peso.
    if (sessions.length > 1 && minReps < range.min) {
      final prev = sessions[1];
      final prevKg = prev.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
      final prevMin = prev
          .where((s) => s.weightKg == prevKg)
          .map((s) => s.reps)
          .reduce((a, b) => a < b ? a : b);
      if (prevKg >= kg && prevMin < range.min) {
        final lighter = _round(kg * 0.9);
        return ProgressionSuggestion(
          exercise: e,
          kind: ProgressionKind.deload,
          kg: lighter,
          reps: range.max,
          reason: 'Dos sesiones por debajo de ${range.min} reps: baja a ${formatKg(lighter)} kg y vuelve a subir desde ahí.',
        );
      }
    }

    final reps = (minReps + 1).clamp(range.min, range.max);
    return ProgressionSuggestion(
      exercise: e,
      kind: ProgressionKind.hold,
      kg: kg,
      reps: reps,
      reason: 'Mantén ${formatKg(kg)} kg y busca $reps reps en cada serie.',
    );
  }

  double _round(double kg) => (kg * 2).round() / 2; // múltiplos de 0.5 kg
}

/// Series completadas de un ejercicio en las últimas [take] sesiones.
List<List<WorkoutSet>> exerciseHistory(
  List<WorkoutSession> sessions,
  String exerciseId, {
  int take = 2,
}) {
  final sorted = [...sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final out = <List<WorkoutSet>>[];
  for (final s in sorted) {
    for (final log in s.logs) {
      if (log.exercise.id == exerciseId && log.completedSets.isNotEmpty) {
        out.add(log.completedSets);
        break;
      }
    }
    if (out.length >= take) break;
  }
  return out;
}

/// Sugerencias para la sesión de hoy, por id de ejercicio.
class GetProgressionSuggestions {
  final WorkoutRepository workouts;
  final ProgressionAdvisor advisor;

  GetProgressionSuggestions(this.workouts,
      {this.advisor = const ProgressionAdvisor()});

  Future<Map<String, ProgressionSuggestion>> call(
    String userId,
    List<Exercise> exercises,
  ) async {
    final sessions = await workouts.watchSessions(userId).first;
    return {
      for (final e in exercises)
        e.id: advisor.suggest(e, exerciseHistory(sessions, e.id)),
    };
  }
}
