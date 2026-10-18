import '../entities/entities.dart';
import '../repositories/repositories.dart';
import 'progression.dart';

/// Devuelve, por cada ejercicio, las series de la última vez que se hizo.
/// Alimenta la columna "ANTERIOR" y los valores sugeridos de kg/reps.
///
/// No se agregó un método nuevo al repositorio: se resuelve con el contrato
/// existente, así ninguna implementación (Firestore, memoria, API) cambia.
class GetPreviousPerformance {
  final WorkoutRepository workouts;
  GetPreviousPerformance(this.workouts);

  Future<Map<String, List<WorkoutSet>>> call(
    String userId,
    List<Exercise> exercises,
  ) async {
    final sessions = await workouts.watchSessions(userId).first;
    final sorted = [...sessions]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final result = <String, List<WorkoutSet>>{};
    for (final e in exercises) {
      search:
      for (final s in sorted) {
        for (final log in s.logs) {
          if (log.exercise.id == e.id && log.completedSets.isNotEmpty) {
            result[e.id] = log.completedSets;
            break search;
          }
        }
      }
    }
    return result;
  }
}

class WorkoutResult {
  final WorkoutSession session;
  final List<PersonalRecord> records;

  /// Qué hacer la próxima vez en cada ejercicio (progresión doble).
  final List<ProgressionSuggestion> nextSteps;

  const WorkoutResult(this.session, this.records, [this.nextSteps = const []]);

  int get completedSets =>
      session.logs.fold(0, (acc, l) => acc + l.completedSets.length);
}

/// Detecta récords comparando la sesión nueva contra el historial.
/// Solo cuenta ejercicios con peso (> 0 kg) que ya tenían historial,
/// para no celebrar como "récord" la primera vez que se hace algo.
List<PersonalRecord> detectPersonalRecords(
  List<WorkoutSession> history,
  WorkoutSession session,
) {
  final records = <PersonalRecord>[];
  for (final log in session.logs) {
    final best = log.bestSet;
    if (best == null || best.weightKg <= 0) continue;

    double? previousBest;
    for (final s in history) {
      for (final l in s.logs.where((l) => l.exercise.id == log.exercise.id)) {
        final b = l.bestSet;
        if (b != null && (previousBest == null || b.weightKg > previousBest)) {
          previousBest = b.weightKg;
        }
      }
    }
    if (previousBest != null && best.weightKg > previousBest) {
      records.add(PersonalRecord(
        exercise: log.exercise,
        set: best,
        previousBestKg: previousBest,
      ));
    }
  }
  return records;
}

/// Guarda el entrenamiento y devuelve el resumen con los récords logrados.
class FinishWorkout {
  final WorkoutRepository workouts;
  final ProgressionAdvisor advisor;
  FinishWorkout(this.workouts, {this.advisor = const ProgressionAdvisor()});

  Future<WorkoutResult> call(String userId, WorkoutSession session) async {
    final history = (await workouts.watchSessions(userId).first)
        .where((s) => s.id != session.id)
        .toList();
    final records = detectPersonalRecords(history, session);
    final withToday = [session, ...history];
    final nextSteps = [
      for (final log in session.logs)
        if (log.completedSets.isNotEmpty)
          advisor.suggest(log.exercise, exerciseHistory(withToday, log.exercise.id)),
    ];
    await workouts.saveSession(userId, session);
    return WorkoutResult(session, records, nextSteps);
  }
}
