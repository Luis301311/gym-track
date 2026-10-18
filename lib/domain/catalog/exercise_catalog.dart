import '../entities/entities.dart';

/// Equipo que necesita un ejercicio.
enum Equipment { barbell, machine, dumbbell, bodyweight }

/// Patrón de movimiento: lo que usa el recomendador para armar días
/// equilibrados sin depender de ejercicios concretos.
enum MovementPattern {
  horizontalPush,
  verticalPush,
  horizontalPull,
  verticalPull,
  squat,
  hinge,
  lunge,
  legAccessory,
  chestIsolation,
  shoulderIsolation,
  biceps,
  triceps,
  calves,
  core,
}

class CatalogExercise {
  final Exercise exercise;
  final MovementPattern pattern;
  final Equipment equipment;

  /// Multiarticular (sentadilla, press…) frente a aislamiento (curl…).
  final bool compound;

  /// Repeticiones fijas cuando no aplican rangos normales (p. ej. "30-45 s").
  final String? fixedReps;

  const CatalogExercise(
    this.exercise,
    this.pattern,
    this.equipment, {
    this.compound = false,
    this.fixedReps,
  });
}

const _hp = MovementPattern.horizontalPush, _vp = MovementPattern.verticalPush,
    _hl = MovementPattern.horizontalPull, _vl = MovementPattern.verticalPull,
    _sq = MovementPattern.squat, _hi = MovementPattern.hinge,
    _lu = MovementPattern.lunge, _la = MovementPattern.legAccessory,
    _ci = MovementPattern.chestIsolation, _si = MovementPattern.shoulderIsolation,
    _bi = MovementPattern.biceps, _tr = MovementPattern.triceps,
    _ca = MovementPattern.calves, _co = MovementPattern.core;
const _bb = Equipment.barbell, _ma = Equipment.machine,
    _db = Equipment.dumbbell, _bw = Equipment.bodyweight;

Exercise _e(String id, String name, String muscle, String equipment) =>
    Exercise(id: id, name: name, muscleGroup: muscle, equipment: equipment);

/// Catálogo base. El orden dentro de cada patrón es la preferencia del
/// recomendador (primero los básicos con barra si hay gimnasio).
final kExerciseCatalog = <CatalogExercise>[
  // Empuje horizontal
  CatalogExercise(_e('bench', 'Press de banca', 'Pecho', 'Barra'), _hp, _bb, compound: true),
  CatalogExercise(_e('db_bench', 'Press con mancuernas', 'Pecho', 'Mancuernas'), _hp, _db, compound: true),
  CatalogExercise(_e('incline_db', 'Press inclinado con mancuernas', 'Pecho', 'Mancuernas'), _hp, _db, compound: true),
  CatalogExercise(_e('machine_chest', 'Press de pecho en máquina', 'Pecho', 'Máquina'), _hp, _ma, compound: true),
  CatalogExercise(_e('pushup', 'Flexiones', 'Pecho', 'Peso corporal'), _hp, _bw, compound: true),
  // Empuje vertical
  CatalogExercise(_e('ohp', 'Press militar', 'Hombro', 'Barra'), _vp, _bb, compound: true),
  CatalogExercise(_e('db_ohp', 'Press de hombro con mancuernas', 'Hombro', 'Mancuernas'), _vp, _db, compound: true),
  CatalogExercise(_e('pike_pushup', 'Flexiones pike', 'Hombro', 'Peso corporal'), _vp, _bw, compound: true),
  // Tirón horizontal
  CatalogExercise(_e('row', 'Remo con barra', 'Espalda', 'Barra'), _hl, _bb, compound: true),
  CatalogExercise(_e('db_row', 'Remo con mancuerna', 'Espalda', 'Mancuernas'), _hl, _db, compound: true),
  CatalogExercise(_e('cable_row', 'Remo en polea baja', 'Espalda', 'Máquina'), _hl, _ma, compound: true),
  CatalogExercise(_e('inverted_row', 'Remo invertido', 'Espalda', 'Peso corporal'), _hl, _bw, compound: true),
  // Tirón vertical
  CatalogExercise(_e('pullup', 'Dominadas', 'Espalda', 'Barra fija'), _vl, _bw, compound: true),
  CatalogExercise(_e('lat_pulldown', 'Jalón al pecho', 'Espalda', 'Máquina'), _vl, _ma, compound: true),
  // Sentadilla
  CatalogExercise(_e('squat', 'Sentadilla', 'Piernas', 'Barra'), _sq, _bb, compound: true),
  CatalogExercise(_e('leg_press', 'Prensa de piernas', 'Piernas', 'Máquina'), _sq, _ma, compound: true),
  CatalogExercise(_e('goblet', 'Sentadilla goblet', 'Piernas', 'Mancuernas'), _sq, _db, compound: true),
  CatalogExercise(_e('bw_squat', 'Sentadilla con peso corporal', 'Piernas', 'Peso corporal'), _sq, _bw, compound: true),
  // Bisagra de cadera
  CatalogExercise(_e('rdl', 'Peso muerto rumano', 'Femoral', 'Barra'), _hi, _bb, compound: true),
  CatalogExercise(_e('deadlift', 'Peso muerto', 'Espalda baja', 'Barra'), _hi, _bb, compound: true),
  CatalogExercise(_e('hip_thrust', 'Hip thrust', 'Glúteos', 'Barra'), _hi, _bb, compound: true),
  CatalogExercise(_e('db_rdl', 'Peso muerto rumano con mancuernas', 'Femoral', 'Mancuernas'), _hi, _db, compound: true),
  CatalogExercise(_e('glute_bridge', 'Puente de glúteos', 'Glúteos', 'Peso corporal'), _hi, _bw, compound: true),
  // Zancadas / unilateral
  CatalogExercise(_e('lunge', 'Zancadas', 'Piernas', 'Mancuernas'), _lu, _db, compound: true),
  CatalogExercise(_e('bulgarian', 'Sentadilla búlgara', 'Piernas', 'Mancuernas'), _lu, _db, compound: true),
  CatalogExercise(_e('bw_lunge', 'Zancadas sin peso', 'Piernas', 'Peso corporal'), _lu, _bw, compound: true),
  // Accesorios de pierna
  CatalogExercise(_e('leg_curl', 'Curl femoral', 'Femoral', 'Máquina'), _la, _ma),
  CatalogExercise(_e('leg_ext', 'Extensión de cuádriceps', 'Cuádriceps', 'Máquina'), _la, _ma),
  CatalogExercise(_e('step_up', 'Subidas al banco', 'Piernas', 'Mancuernas'), _la, _db),
  CatalogExercise(_e('wall_sit', 'Sentadilla isométrica en pared', 'Cuádriceps', 'Peso corporal'), _la, _bw, fixedReps: '30-45 s'),
  // Aislamiento de pecho y hombro
  CatalogExercise(_e('cable_fly', 'Cruces en polea', 'Pecho', 'Máquina'), _ci, _ma),
  CatalogExercise(_e('db_fly', 'Aperturas con mancuernas', 'Pecho', 'Mancuernas'), _ci, _db),
  CatalogExercise(_e('lateral_raise', 'Elevaciones laterales', 'Hombro', 'Mancuernas'), _si, _db),
  CatalogExercise(_e('face_pull', 'Face pull', 'Hombro posterior', 'Máquina'), _si, _ma),
  CatalogExercise(_e('rear_fly', 'Pájaros con mancuernas', 'Hombro posterior', 'Mancuernas'), _si, _db),
  // Brazos
  CatalogExercise(_e('bb_curl', 'Curl con barra', 'Bíceps', 'Barra'), _bi, _bb),
  CatalogExercise(_e('curl', 'Curl de bíceps', 'Bíceps', 'Mancuernas'), _bi, _db),
  CatalogExercise(_e('hammer_curl', 'Curl martillo', 'Bíceps', 'Mancuernas'), _bi, _db),
  CatalogExercise(_e('chinup', 'Dominadas supinas', 'Bíceps', 'Barra fija'), _bi, _bw),
  CatalogExercise(_e('pushdown', 'Extensión de tríceps en polea', 'Tríceps', 'Máquina'), _tr, _ma),
  CatalogExercise(_e('dips', 'Fondos', 'Tríceps', 'Paralelas'), _tr, _bw),
  CatalogExercise(_e('oh_ext', 'Extensión de tríceps sobre la cabeza', 'Tríceps', 'Mancuernas'), _tr, _db),
  CatalogExercise(_e('bench_dips', 'Fondos en banco', 'Tríceps', 'Peso corporal'), _tr, _bw),
  // Pantorrilla y core
  CatalogExercise(_e('machine_calf', 'Pantorrilla en máquina', 'Pantorrilla', 'Máquina'), _ca, _ma),
  CatalogExercise(_e('calf_raise', 'Elevación de talones', 'Pantorrilla', 'Peso corporal'), _ca, _bw),
  CatalogExercise(_e('hanging_leg', 'Elevación de piernas colgado', 'Core', 'Barra fija'), _co, _bw),
  CatalogExercise(_e('cable_crunch', 'Crunch en polea', 'Core', 'Máquina'), _co, _ma),
  CatalogExercise(_e('plank', 'Plancha', 'Core', 'Peso corporal'), _co, _bw, fixedReps: '30-45 s'),
  CatalogExercise(_e('crunch', 'Crunch', 'Core', 'Peso corporal'), _co, _bw),
];

/// Grupos musculares del catálogo, para filtrar.
List<String> catalogMuscleGroups() {
  final seen = <String>[];
  for (final c in kExerciseCatalog) {
    if (!seen.contains(c.exercise.muscleGroup)) seen.add(c.exercise.muscleGroup);
  }
  return seen;
}
