import '../../domain/entities/entities.dart';
import '../../domain/utils/format.dart';

/// Estado editable de una serie mientras se entrena (lo que hay en los campos).
class SetDraft {
  String kg;
  String reps;
  bool done;

  SetDraft({this.kg = '', this.reps = '', this.done = false});
}

/// Ejercicio en curso: sus series editables y lo que se hizo la vez anterior.
class ExerciseDraft {
  final Exercise exercise;
  final List<WorkoutSet> previous;
  final List<SetDraft> sets;

  ExerciseDraft({
    required this.exercise,
    required this.previous,
    required this.sets,
  });

  factory ExerciseDraft.fromHistory(Exercise e, List<WorkoutSet> previous) =>
      ExerciseDraft(
        exercise: e,
        previous: previous,
        // Las series las define el plan de la rutina; la vez anterior solo
        // sugiere kg y reps.
        sets: List.generate(
          e.targetSets < 1 ? 1 : e.targetSets,
          (_) => SetDraft(),
        ),
      );

  /// Serie de referencia para la fila [i]: la misma serie de la vez anterior
  /// o, si hoy se hacen más series, la última que se hizo.
  WorkoutSet? previousFor(int i) {
    if (previous.isEmpty) return null;
    return previous[i < previous.length ? i : previous.length - 1];
  }

  int get doneCount => sets.where((s) => s.done).length;
  bool get isComplete => doneCount == sets.length;

  /// Índice de la primera serie pendiente (la "activa"), o -1.
  int get activeIndex => sets.indexWhere((s) => !s.done);

  ExerciseLog toLog() => ExerciseLog(
        exercise: exercise,
        sets: [
          for (final s in sets.where((s) => s.done))
            WorkoutSet(
              reps: int.parse(s.reps),
              weightKg: parseDecimal(s.kg) ?? 0,
            ),
        ],
      );
}
