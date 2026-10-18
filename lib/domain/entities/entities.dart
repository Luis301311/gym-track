/// Entidades del dominio. Dart puro: no dependen de Flutter ni de Firebase,
/// así que sobreviven a cualquier cambio de backend o de UI.

class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;

  /// Descanso recomendado entre series, en segundos.
  final int restSeconds;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.equipment = '',
    this.restSeconds = 90,
  });
}

class WorkoutSet {
  final int reps;
  final double weightKg;
  final bool completed;

  const WorkoutSet({
    required this.reps,
    required this.weightKg,
    this.completed = true,
  });

  /// Volumen = reps × kg (solo cuenta si la serie se completó).
  double get volume => completed ? reps * weightKg : 0;
}

class ExerciseLog {
  final Exercise exercise;
  final List<WorkoutSet> sets;

  const ExerciseLog({required this.exercise, required this.sets});

  double get volume => sets.fold(0, (acc, s) => acc + s.volume);

  List<WorkoutSet> get completedSets => sets.where((s) => s.completed).toList();

  /// Serie más pesada completada (sirve para récords personales).
  WorkoutSet? get bestSet {
    final done = completedSets;
    if (done.isEmpty) return null;
    return done.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);
  }
}

class WorkoutSession {
  final String id;
  final String routineName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<ExerciseLog> logs;

  const WorkoutSession({
    required this.id,
    required this.routineName,
    required this.startedAt,
    this.finishedAt,
    this.logs = const [],
  });

  double get volume => logs.fold(0, (acc, l) => acc + l.volume);

  Duration get duration =>
      (finishedAt ?? DateTime.now()).difference(startedAt);
}

class Routine {
  final String id;
  final String name;

  /// Texto corto de los músculos que trabaja, p. ej. "Pecho, hombro y tríceps".
  final String focus;
  final List<Exercise> exercises;
  final int estimatedMinutes;

  /// Días de la semana en que toca (1 = lunes … 7 = domingo).
  final List<int> weekdays;

  const Routine({
    required this.id,
    required this.name,
    required this.focus,
    required this.exercises,
    required this.estimatedMinutes,
    required this.weekdays,
  });
}

class UserProfile {
  final String id;
  final String name;
  final String goal;

  /// Entrenamientos que la persona se propone por semana.
  final int weeklyGoal;

  /// Altura en centímetros (opcional).
  final double? heightCm;

  const UserProfile({
    required this.id,
    required this.name,
    required this.goal,
    this.weeklyGoal = 5,
    this.heightCm,
  });

  UserProfile copyWith({
    String? name,
    String? goal,
    int? weeklyGoal,
    double? heightCm,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        goal: goal ?? this.goal,
        weeklyGoal: weeklyGoal ?? this.weeklyGoal,
        heightCm: heightCm ?? this.heightCm,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }
}

/// Récord personal logrado en un entrenamiento: la serie más pesada de un
/// ejercicio supera la mejor marca anterior.
class PersonalRecord {
  final Exercise exercise;
  final WorkoutSet set;
  final double? previousBestKg;

  const PersonalRecord({
    required this.exercise,
    required this.set,
    this.previousBestKg,
  });
}

/// Registro de peso corporal en una fecha.
class BodyWeightEntry {
  final String id;
  final DateTime date;
  final double kg;

  const BodyWeightEntry({required this.id, required this.date, required this.kg});
}

/// Tipo de medida corporal. Agregar una nueva (p. ej. muslo) es agregar una
/// línea a [kMeasurementTypes]: la UI y los cálculos la toman solos.
class MeasurementType {
  final String key;
  final String label;

  /// Si subir es bueno (pecho, brazo) o bajar es bueno (cintura).
  final bool higherIsBetter;

  const MeasurementType(this.key, this.label, {this.higherIsBetter = true});
}

const kMeasurementTypes = [
  MeasurementType('chest', 'Pecho'),
  MeasurementType('arm', 'Brazo'),
  MeasurementType('waist', 'Cintura', higherIsBetter: false),
];

/// Registro de medidas en una fecha. [valuesCm] usa las claves de
/// [MeasurementType.key]; no hace falta registrar todas cada vez.
class BodyMeasurement {
  final String id;
  final DateTime date;
  final Map<String, double> valuesCm;

  const BodyMeasurement({
    required this.id,
    required this.date,
    required this.valuesCm,
  });
}
