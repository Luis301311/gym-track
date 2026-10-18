import '../catalog/exercise_catalog.dart';
import '../entities/entities.dart';

enum TrainingGoal { hypertrophy, strength, fatLoss, endurance }

enum ExperienceLevel { beginner, intermediate, advanced }

enum EquipmentAccess { gym, dumbbells, bodyweight }

/// Parte del cuerpo a la que se le da prioridad (más ejercicios y primero).
enum TrainingEmphasis { balanced, lowerBody, upperBody }

extension TrainingEmphasisX on TrainingEmphasis {
  String get label => switch (this) {
        TrainingEmphasis.balanced => 'Equilibrado',
        TrainingEmphasis.lowerBody => 'Glúteos y piernas',
        TrainingEmphasis.upperBody => 'Torso y brazos',
      };

  /// Sugerencia inicial según el sexo (la persona la puede cambiar).
  static TrainingEmphasis suggestedFor(Sex sex) =>
      sex == Sex.female ? TrainingEmphasis.lowerBody : TrainingEmphasis.balanced;
}

extension TrainingGoalX on TrainingGoal {
  String get label => switch (this) {
        TrainingGoal.hypertrophy => 'Ganar músculo',
        TrainingGoal.strength => 'Ganar fuerza',
        TrainingGoal.fatLoss => 'Bajar grasa',
        TrainingGoal.endurance => 'Resistencia',
      };
}

extension ExperienceLevelX on ExperienceLevel {
  String get label => switch (this) {
        ExperienceLevel.beginner => 'Principiante',
        ExperienceLevel.intermediate => 'Intermedio',
        ExperienceLevel.advanced => 'Avanzado',
      };
}

extension EquipmentAccessX on EquipmentAccess {
  String get label => switch (this) {
        EquipmentAccess.gym => 'Gimnasio completo',
        EquipmentAccess.dumbbells => 'Solo mancuernas',
        EquipmentAccess.bodyweight => 'Sin equipo',
      };

  Set<Equipment> get allowed => switch (this) {
        EquipmentAccess.gym => Equipment.values.toSet(),
        EquipmentAccess.dumbbells => {Equipment.dumbbell, Equipment.bodyweight},
        EquipmentAccess.bodyweight => {Equipment.bodyweight},
      };
}

class RecommendationInput {
  final TrainingGoal goal;
  final int daysPerWeek; // 2 a 6
  final ExperienceLevel level;
  final EquipmentAccess access;
  final int minutes; // 45, 60 o 75
  final TrainingEmphasis emphasis;
  final Sex sex;

  const RecommendationInput({
    required this.goal,
    required this.daysPerWeek,
    required this.level,
    required this.access,
    required this.minutes,
    this.emphasis = TrainingEmphasis.balanced,
    this.sex = Sex.unspecified,
  });
}

const _lowerPatterns = {
  MovementPattern.squat,
  MovementPattern.hinge,
  MovementPattern.lunge,
  MovementPattern.glutes,
  MovementPattern.legAccessory,
  MovementPattern.calves,
};

const _upperIsolation = {
  MovementPattern.chestIsolation,
  MovementPattern.shoulderIsolation,
  MovementPattern.biceps,
  MovementPattern.triceps,
};

/// Aplica el enfoque a un día: agrega al inicio un ejercicio extra de la zona
/// prioritaria (para que no se recorte por tiempo) y manda al final lo de la
/// otra zona.
List<MovementPattern> applyEmphasis(
    List<MovementPattern> slots, TrainingEmphasis emphasis) {
  if (emphasis == TrainingEmphasis.balanced) return slots;
  final hasLower = slots.any(_lowerPatterns.contains);
  final hasUpper = slots.any((p) => !_lowerPatterns.contains(p) && p != MovementPattern.core);

  if (emphasis == TrainingEmphasis.lowerBody && hasLower) {
    final out = [...slots];
    final firstLower = out.indexWhere(_lowerPatterns.contains);
    out.insert(firstLower + 1, MovementPattern.glutes);
    // Aislamientos de torso al final (son lo primero que se recorta).
    final iso = out.where(_upperIsolation.contains).toList();
    out.removeWhere(_upperIsolation.contains);
    return [...out, ...iso];
  }
  if (emphasis == TrainingEmphasis.upperBody && hasUpper) {
    final out = [...slots];
    final firstUpper = out.indexWhere(
        (p) => !_lowerPatterns.contains(p) && p != MovementPattern.core);
    out.insert(firstUpper + 1, MovementPattern.shoulderIsolation);
    // En días mixtos se conserva el primer ejercicio de pierna en su lugar y
    // el resto de pierna pasa al final (es lo primero que se recorta).
    final firstLower = out.indexWhere(_lowerPatterns.contains);
    if (firstLower < 0) return out;
    final keep = <MovementPattern>[];
    final moved = <MovementPattern>[];
    for (var i = 0; i < out.length; i++) {
      final p = out[i];
      (i != firstLower && _lowerPatterns.contains(p) ? moved : keep).add(p);
    }
    return [...keep, ...moved];
  }
  return slots;
}

/// Un día del plan: nombre y patrones de movimiento en orden de prioridad.
class DayTemplate {
  final String name;
  final List<MovementPattern> slots;
  const DayTemplate(this.name, this.slots);
}

/// Forma de repartir el entrenamiento en la semana.
///
/// OPEN/CLOSED: para agregar una división nueva (p. ej. "Arnold split") se
/// crea otra clase y se agrega a la lista del recomendador; nada más cambia.
abstract class SplitTemplate {
  String get name;
  bool supports(int daysPerWeek);
  List<DayTemplate> days(int daysPerWeek);
}

class FullBodySplit extends SplitTemplate {
  @override
  String get name => 'Cuerpo completo';

  @override
  bool supports(int d) => d <= 3;

  @override
  List<DayTemplate> days(int d) => [
        DayTemplate('Cuerpo completo A', [
          MovementPattern.squat, MovementPattern.horizontalPush, MovementPattern.horizontalPull,
          MovementPattern.hinge, MovementPattern.shoulderIsolation, MovementPattern.core,
        ]),
        DayTemplate('Cuerpo completo B', [
          MovementPattern.hinge, MovementPattern.verticalPush, MovementPattern.verticalPull,
          MovementPattern.lunge, MovementPattern.biceps, MovementPattern.triceps,
        ]),
        DayTemplate('Cuerpo completo C', [
          MovementPattern.squat, MovementPattern.horizontalPush, MovementPattern.verticalPull,
          MovementPattern.legAccessory, MovementPattern.triceps, MovementPattern.core,
        ]),
      ].take(d).toList();
}

class UpperLowerSplit extends SplitTemplate {
  @override
  String get name => 'Torso / Pierna';

  @override
  bool supports(int d) => d == 4;

  @override
  List<DayTemplate> days(int d) => [
        DayTemplate('Torso A', [
          MovementPattern.horizontalPush, MovementPattern.horizontalPull, MovementPattern.verticalPush,
          MovementPattern.verticalPull, MovementPattern.shoulderIsolation, MovementPattern.triceps, MovementPattern.biceps,
        ]),
        DayTemplate('Pierna A', [
          MovementPattern.squat, MovementPattern.hinge, MovementPattern.lunge,
          MovementPattern.legAccessory, MovementPattern.glutes, MovementPattern.calves,
          MovementPattern.core,
        ]),
        DayTemplate('Torso B', [
          MovementPattern.verticalPull, MovementPattern.horizontalPush, MovementPattern.horizontalPull,
          MovementPattern.chestIsolation, MovementPattern.biceps, MovementPattern.triceps, MovementPattern.shoulderIsolation,
        ]),
        DayTemplate('Pierna B', [
          MovementPattern.hinge, MovementPattern.squat, MovementPattern.lunge,
          MovementPattern.legAccessory, MovementPattern.calves, MovementPattern.core,
        ]),
      ];
}

class PushPullLegsSplit extends SplitTemplate {
  @override
  String get name => 'Empuje / Tirón / Pierna';

  @override
  bool supports(int d) => d >= 5;

  static final _push = DayTemplate('Empuje', [
    MovementPattern.horizontalPush, MovementPattern.verticalPush, MovementPattern.chestIsolation,
    MovementPattern.shoulderIsolation, MovementPattern.triceps, MovementPattern.triceps,
  ]);
  static final _pull = DayTemplate('Tirón', [
    MovementPattern.verticalPull, MovementPattern.horizontalPull, MovementPattern.horizontalPull,
    MovementPattern.shoulderIsolation, MovementPattern.biceps, MovementPattern.biceps,
  ]);
  static final _legs = DayTemplate('Pierna', [
    MovementPattern.squat, MovementPattern.hinge, MovementPattern.lunge,
    MovementPattern.legAccessory, MovementPattern.calves, MovementPattern.core,
  ]);

  @override
  List<DayTemplate> days(int d) {
    if (d == 5) {
      final ul = UpperLowerSplit().days(4);
      return [_push, _pull, _legs, ul[0], ul[1]];
    }
    DayTemplate rename(DayTemplate t, String s) =>
        DayTemplate('${t.name} $s', t.slots);
    return [
      rename(_push, 'A'), rename(_pull, 'A'), rename(_legs, 'A'),
      rename(_push, 'B'), rename(_pull, 'B'), rename(_legs, 'B'),
    ];
  }
}

/// Series, repeticiones y descanso según el objetivo.
class _Prescription {
  final int sets;
  final String reps;
  final int rest;
  const _Prescription(this.sets, this.reps, this.rest);
}

class RoutineRecommendation {
  final String splitName;
  final List<Routine> routines;
  const RoutineRecommendation(this.splitName, this.routines);
}

/// Genera un plan semanal con reglas de entrenamiento conocidas: división
/// según los días, ejercicios según el equipo disponible y volumen según
/// objetivo y experiencia. Es determinista (misma entrada, mismo plan).
class RoutineRecommender {
  final List<SplitTemplate> splits;
  final List<CatalogExercise> catalog;

  RoutineRecommender({
    List<SplitTemplate>? splits,
    List<CatalogExercise>? catalog,
  })  : splits = splits ??
            [FullBodySplit(), UpperLowerSplit(), PushPullLegsSplit()],
        catalog = catalog ?? kExerciseCatalog;

  static const weekdayPlan = {
    2: [1, 4],
    3: [1, 3, 5],
    4: [1, 2, 4, 5],
    5: [1, 2, 3, 5, 6],
    6: [1, 2, 3, 4, 5, 6],
  };

  RoutineRecommendation recommend(
    RecommendationInput input, {
    String idPrefix = 'rec',
  }) {
    final days = input.daysPerWeek.clamp(2, 6);
    final split = splits.firstWhere((s) => s.supports(days));
    final templates = split.days(days);
    final weekdays = weekdayPlan[days]!;
    final allowed = input.access.allowed;

    final maxExercises = switch (input.minutes) {
      <= 45 => 4,
      <= 60 => 5,
      _ => 6,
    };
    final perDay = input.level == ExperienceLevel.beginner
        ? (maxExercises - 1).clamp(3, 6)
        : maxExercises;

    // Cuántas veces se ha usado cada patrón en la semana: sirve para rotar
    // ejercicios (día A press de banca, día B press con mancuernas…).
    final used = <MovementPattern, int>{};
    final routines = <Routine>[];

    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      final picked = <Exercise>[];
      for (final slot in applyEmphasis(t.slots, input.emphasis)) {
        if (picked.length >= perDay) break;
        final options = catalog
            .where((c) => c.pattern == slot && allowed.contains(c.equipment))
            .toList();
        if (options.isEmpty) continue;
        final n = used[slot] ?? 0;
        CatalogExercise? choice;
        for (var k = 0; k < options.length; k++) {
          final c = options[(n + k) % options.length];
          if (!picked.any((e) => e.id == c.exercise.id)) {
            choice = c;
            break;
          }
        }
        if (choice == null) continue;
        used[slot] = n + 1;
        final rx = _prescribe(input, choice.compound);
        picked.add(choice.exercise.copyWith(
          targetSets: rx.sets,
          targetReps: choice.fixedReps ?? rx.reps,
          restSeconds: rx.rest,
        ));
      }
      routines.add(Routine.build(
        id: '$idPrefix-${i + 1}',
        name: t.name,
        exercises: picked,
        weekdays: [weekdays[i]],
      ));
    }
    return RoutineRecommendation(split.name, routines);
  }

  _Prescription _prescribe(RecommendationInput input, bool compound) {
    final base = switch ((input.goal, compound)) {
      (TrainingGoal.strength, true) => const _Prescription(5, '4-6', 180),
      (TrainingGoal.strength, false) => const _Prescription(3, '8-10', 90),
      (TrainingGoal.hypertrophy, true) => const _Prescription(4, '6-10', 120),
      (TrainingGoal.hypertrophy, false) => const _Prescription(3, '10-12', 75),
      (TrainingGoal.fatLoss, true) => const _Prescription(3, '10-12', 75),
      (TrainingGoal.fatLoss, false) => const _Prescription(3, '12-15', 45),
      (TrainingGoal.endurance, true) => const _Prescription(3, '12-15', 60),
      (TrainingGoal.endurance, false) => const _Prescription(2, '15-20', 45),
    };
    final sets = switch (input.level) {
      ExperienceLevel.beginner => (base.sets - 1).clamp(2, 6),
      ExperienceLevel.intermediate => base.sets,
      ExperienceLevel.advanced => compound ? (base.sets + 1).clamp(2, 6) : base.sets,
    };
    // En promedio, las mujeres se recuperan más rápido entre series al mismo
    // esfuerzo relativo: descansos ~15 s más cortos (mínimo 45 s).
    final rest = input.sex == Sex.female
        ? (base.rest - 15).clamp(45, 600)
        : base.rest;
    return _Prescription(sets, base.reps, rest);
  }
}
