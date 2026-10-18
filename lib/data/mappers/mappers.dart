import '../../domain/entities/entities.dart';

/// Conversión entidad <-> Map. La reutilizan Firestore hoy y una API REST
/// mañana: lo único que cambia entre backends es cómo se leen y escriben las
/// fechas, por eso se reciben como funciones.
typedef DateReader = DateTime? Function(Object? raw);
typedef DateWriter = Object? Function(DateTime? date);

Map<String, dynamic> exerciseToMap(Exercise e) => {
      'id': e.id,
      'name': e.name,
      'muscleGroup': e.muscleGroup,
      'equipment': e.equipment,
      'restSeconds': e.restSeconds,
      'targetSets': e.targetSets,
      'targetReps': e.targetReps,
    };

Exercise exerciseFromMap(Map<String, dynamic> m) => Exercise(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      muscleGroup: m['muscleGroup'] as String? ?? '',
      equipment: m['equipment'] as String? ?? '',
      restSeconds: (m['restSeconds'] as num?)?.toInt() ?? 90,
      targetSets: (m['targetSets'] as num?)?.toInt() ?? 3,
      targetReps: m['targetReps'] as String? ?? '8-12',
    );

Map<String, dynamic> sessionToMap(WorkoutSession s, DateWriter writeDate) => {
      'routineName': s.routineName,
      'startedAt': writeDate(s.startedAt),
      'finishedAt': writeDate(s.finishedAt),
      'logs': [
        for (final l in s.logs)
          {
            'exercise': exerciseToMap(l.exercise),
            'sets': [
              for (final set in l.sets)
                {
                  'reps': set.reps,
                  'weightKg': set.weightKg,
                  'completed': set.completed,
                },
            ],
          },
      ],
    };

WorkoutSession sessionFromMap(
  String id,
  Map<String, dynamic> m,
  DateReader readDate,
) =>
    WorkoutSession(
      id: id,
      routineName: m['routineName'] as String? ?? '',
      startedAt: readDate(m['startedAt']) ?? DateTime.now(),
      finishedAt: readDate(m['finishedAt']),
      logs: [
        for (final raw in (m['logs'] as List? ?? const []))
          ExerciseLog(
            exercise: exerciseFromMap(
              Map<String, dynamic>.from(raw['exercise'] as Map),
            ),
            sets: [
              for (final s in (raw['sets'] as List? ?? const []))
                WorkoutSet(
                  reps: (s['reps'] as num).toInt(),
                  weightKg: (s['weightKg'] as num).toDouble(),
                  completed: s['completed'] as bool? ?? true,
                ),
            ],
          ),
      ],
    );

Map<String, dynamic> routineToMap(Routine r) => {
      'name': r.name,
      'focus': r.focus,
      'estimatedMinutes': r.estimatedMinutes,
      'weekdays': r.weekdays,
      'exercises': [for (final e in r.exercises) exerciseToMap(e)],
    };

Routine routineFromMap(String id, Map<String, dynamic> m) => Routine(
      id: id,
      name: m['name'] as String? ?? '',
      focus: m['focus'] as String? ?? '',
      estimatedMinutes: (m['estimatedMinutes'] as num?)?.toInt() ?? 0,
      weekdays: [
        for (final d in (m['weekdays'] as List? ?? const [])) (d as num).toInt(),
      ],
      exercises: [
        for (final e in (m['exercises'] as List? ?? const []))
          exerciseFromMap(Map<String, dynamic>.from(e as Map)),
      ],
    );

UserProfile profileFromMap(String id, Map<String, dynamic> m) => UserProfile(
      id: id,
      name: m['name'] as String? ?? 'Atleta',
      goal: m['goal'] as String? ?? '',
      weeklyGoal: (m['weeklyGoal'] as num?)?.toInt() ?? 5,
      heightCm: (m['heightCm'] as num?)?.toDouble(),
    );

Map<String, dynamic> profileToMap(UserProfile p) => {
      'name': p.name,
      'goal': p.goal,
      'weeklyGoal': p.weeklyGoal,
      'heightCm': p.heightCm,
    };

Map<String, dynamic> weightToMap(BodyWeightEntry w, DateWriter writeDate) => {
      'date': writeDate(w.date),
      'kg': w.kg,
    };

BodyWeightEntry weightFromMap(
  String id,
  Map<String, dynamic> m,
  DateReader readDate,
) =>
    BodyWeightEntry(
      id: id,
      date: readDate(m['date']) ?? DateTime.now(),
      kg: (m['kg'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> measurementToMap(BodyMeasurement m, DateWriter writeDate) =>
    {
      'date': writeDate(m.date),
      'valuesCm': m.valuesCm,
    };

BodyMeasurement measurementFromMap(
  String id,
  Map<String, dynamic> m,
  DateReader readDate,
) =>
    BodyMeasurement(
      id: id,
      date: readDate(m['date']) ?? DateTime.now(),
      valuesCm: {
        for (final e in (m['valuesCm'] as Map? ?? const {}).entries)
          e.key as String: (e.value as num).toDouble(),
      },
    );
