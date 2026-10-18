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
  glutes,
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

  /// Patrón de movimiento (solo el catálogo curado lo tiene; la biblioteca
  /// ampliada no, porque el recomendador usa únicamente el curado).
  final MovementPattern? pattern;
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
    _lu = MovementPattern.lunge, _gl = MovementPattern.glutes,
    _la = MovementPattern.legAccessory,
    _ci = MovementPattern.chestIsolation, _si = MovementPattern.shoulderIsolation,
    _bi = MovementPattern.biceps, _tr = MovementPattern.triceps,
    _ca = MovementPattern.calves, _co = MovementPattern.core;
const _bb = Equipment.barbell, _ma = Equipment.machine,
    _db = Equipment.dumbbell, _bw = Equipment.bodyweight;

/// Imágenes de free-exercise-db (dominio público):
/// https://github.com/yuhonas/free-exercise-db
const kExerciseImageBase =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

/// Posición inicial y final de un ejercicio del dataset.
List<String> datasetImages(String datasetId) =>
    ['$kExerciseImageBase$datasetId/0.jpg', '$kExerciseImageBase$datasetId/1.jpg'];

Exercise _e(String id, String name, String muscle, String equipment,
        [String? image]) =>
    Exercise(
      id: id,
      name: name,
      muscleGroup: muscle,
      equipment: equipment,
      imageUrls: image == null ? const [] : datasetImages(image),
    );

/// Catálogo base. El orden dentro de cada patrón es la preferencia del
/// recomendador (primero los básicos con barra si hay gimnasio).
final kExerciseCatalog = <CatalogExercise>[
  // Empuje horizontal
  CatalogExercise(_e('bench', 'Press de banca', 'Pecho', 'Barra', 'Barbell_Bench_Press_-_Medium_Grip'), _hp, _bb, compound: true),
  CatalogExercise(_e('db_bench', 'Press con mancuernas', 'Pecho', 'Mancuernas', 'Dumbbell_Bench_Press'), _hp, _db, compound: true),
  CatalogExercise(_e('incline_db', 'Press inclinado con mancuernas', 'Pecho', 'Mancuernas', 'Incline_Dumbbell_Press'), _hp, _db, compound: true),
  CatalogExercise(_e('machine_chest', 'Press de pecho en máquina', 'Pecho', 'Máquina', 'Machine_Bench_Press'), _hp, _ma, compound: true),
  CatalogExercise(_e('pushup', 'Flexiones', 'Pecho', 'Peso corporal', 'Pushups'), _hp, _bw, compound: true),
  // Empuje vertical
  CatalogExercise(_e('ohp', 'Press militar', 'Hombro', 'Barra', 'Standing_Military_Press'), _vp, _bb, compound: true),
  CatalogExercise(_e('db_ohp', 'Press de hombro con mancuernas', 'Hombro', 'Mancuernas', 'Dumbbell_Shoulder_Press'), _vp, _db, compound: true),
  CatalogExercise(_e('pike_pushup', 'Flexiones pike', 'Hombro', 'Peso corporal'), _vp, _bw, compound: true),
  // Tirón horizontal
  CatalogExercise(_e('row', 'Remo con barra', 'Espalda', 'Barra', 'Bent_Over_Barbell_Row'), _hl, _bb, compound: true),
  CatalogExercise(_e('db_row', 'Remo con mancuerna', 'Espalda', 'Mancuernas', 'One-Arm_Dumbbell_Row'), _hl, _db, compound: true),
  CatalogExercise(_e('cable_row', 'Remo en polea baja', 'Espalda', 'Máquina', 'Seated_Cable_Rows'), _hl, _ma, compound: true),
  CatalogExercise(_e('inverted_row', 'Remo invertido', 'Espalda', 'Peso corporal', 'Inverted_Row'), _hl, _bw, compound: true),
  // Tirón vertical
  CatalogExercise(_e('pullup', 'Dominadas', 'Espalda', 'Barra fija', 'Pullups'), _vl, _bw, compound: true),
  CatalogExercise(_e('lat_pulldown', 'Jalón al pecho', 'Espalda', 'Máquina', 'Wide-Grip_Lat_Pulldown'), _vl, _ma, compound: true),
  // Sentadilla
  CatalogExercise(_e('squat', 'Sentadilla', 'Piernas', 'Barra', 'Barbell_Full_Squat'), _sq, _bb, compound: true),
  CatalogExercise(_e('leg_press', 'Prensa de piernas', 'Piernas', 'Máquina', 'Leg_Press'), _sq, _ma, compound: true),
  CatalogExercise(_e('goblet', 'Sentadilla goblet', 'Piernas', 'Mancuernas', 'Goblet_Squat'), _sq, _db, compound: true),
  CatalogExercise(_e('bw_squat', 'Sentadilla con peso corporal', 'Piernas', 'Peso corporal', 'Bodyweight_Squat'), _sq, _bw, compound: true),
  // Bisagra de cadera
  CatalogExercise(_e('rdl', 'Peso muerto rumano', 'Femoral', 'Barra', 'Romanian_Deadlift'), _hi, _bb, compound: true),
  CatalogExercise(_e('deadlift', 'Peso muerto', 'Espalda baja', 'Barra', 'Barbell_Deadlift'), _hi, _bb, compound: true),
  CatalogExercise(_e('db_rdl', 'Peso muerto rumano con mancuernas', 'Femoral', 'Mancuernas', 'Stiff-Legged_Dumbbell_Deadlift'), _hi, _db, compound: true),
  CatalogExercise(_e('sl_rdl', 'Peso muerto a una pierna', 'Femoral', 'Peso corporal', 'Kettlebell_One-Legged_Deadlift'), _hi, _bw, compound: true),
  // Glúteos
  CatalogExercise(_e('hip_thrust', 'Hip thrust', 'Glúteos', 'Barra', 'Barbell_Hip_Thrust'), _gl, _bb, compound: true),
  CatalogExercise(_e('abduction', 'Abducción de cadera en máquina', 'Glúteos', 'Máquina', 'Thigh_Abductor'), _gl, _ma),
  CatalogExercise(_e('cable_kickback', 'Patada de glúteo en polea', 'Glúteos', 'Máquina', 'Glute_Kickback'), _gl, _ma),
  CatalogExercise(_e('db_hip_thrust', 'Hip thrust con mancuerna', 'Glúteos', 'Mancuernas', 'Barbell_Hip_Thrust'), _gl, _db, compound: true),
  CatalogExercise(_e('glute_bridge', 'Puente de glúteos', 'Glúteos', 'Peso corporal', 'Butt_Lift_Bridge'), _gl, _bw, compound: true),
  CatalogExercise(_e('frog_pump', 'Frog pumps', 'Glúteos', 'Peso corporal'), _gl, _bw),
  // Zancadas / unilateral
  CatalogExercise(_e('lunge', 'Zancadas', 'Piernas', 'Mancuernas', 'Dumbbell_Lunges'), _lu, _db, compound: true),
  CatalogExercise(_e('bulgarian', 'Sentadilla búlgara', 'Piernas', 'Mancuernas', 'Split_Squat_with_Dumbbells'), _lu, _db, compound: true),
  CatalogExercise(_e('bw_lunge', 'Zancadas sin peso', 'Piernas', 'Peso corporal', 'Bodyweight_Walking_Lunge'), _lu, _bw, compound: true),
  // Accesorios de pierna
  CatalogExercise(_e('leg_curl', 'Curl femoral', 'Femoral', 'Máquina', 'Lying_Leg_Curls'), _la, _ma),
  CatalogExercise(_e('leg_ext', 'Extensión de cuádriceps', 'Cuádriceps', 'Máquina', 'Leg_Extensions'), _la, _ma),
  CatalogExercise(_e('step_up', 'Subidas al banco', 'Piernas', 'Mancuernas', 'Dumbbell_Step_Ups'), _la, _db),
  CatalogExercise(_e('wall_sit', 'Sentadilla isométrica en pared', 'Cuádriceps', 'Peso corporal'), _la, _bw, fixedReps: '30-45 s'),
  // Aislamiento de pecho y hombro
  CatalogExercise(_e('cable_fly', 'Cruces en polea', 'Pecho', 'Máquina', 'Cable_Crossover'), _ci, _ma),
  CatalogExercise(_e('db_fly', 'Aperturas con mancuernas', 'Pecho', 'Mancuernas', 'Dumbbell_Flyes'), _ci, _db),
  CatalogExercise(_e('lateral_raise', 'Elevaciones laterales', 'Hombro', 'Mancuernas', 'Side_Lateral_Raise'), _si, _db),
  CatalogExercise(_e('face_pull', 'Face pull', 'Hombro posterior', 'Máquina', 'Face_Pull'), _si, _ma),
  CatalogExercise(_e('rear_fly', 'Pájaros con mancuernas', 'Hombro posterior', 'Mancuernas', 'Seated_Bent-Over_Rear_Delt_Raise'), _si, _db),
  // Brazos
  CatalogExercise(_e('bb_curl', 'Curl con barra', 'Bíceps', 'Barra', 'Barbell_Curl'), _bi, _bb),
  CatalogExercise(_e('curl', 'Curl de bíceps', 'Bíceps', 'Mancuernas', 'Dumbbell_Bicep_Curl'), _bi, _db),
  CatalogExercise(_e('hammer_curl', 'Curl martillo', 'Bíceps', 'Mancuernas', 'Hammer_Curls'), _bi, _db),
  CatalogExercise(_e('chinup', 'Dominadas supinas', 'Bíceps', 'Barra fija', 'Chin-Up'), _bi, _bw),
  CatalogExercise(_e('pushdown', 'Extensión de tríceps en polea', 'Tríceps', 'Máquina', 'Triceps_Pushdown'), _tr, _ma),
  CatalogExercise(_e('dips', 'Fondos', 'Tríceps', 'Paralelas', 'Dips_-_Triceps_Version'), _tr, _bw),
  CatalogExercise(_e('oh_ext', 'Extensión de tríceps sobre la cabeza', 'Tríceps', 'Mancuernas', 'Standing_Dumbbell_Triceps_Extension'), _tr, _db),
  CatalogExercise(_e('bench_dips', 'Fondos en banco', 'Tríceps', 'Peso corporal', 'Bench_Dips'), _tr, _bw),
  // Pantorrilla y core
  CatalogExercise(_e('machine_calf', 'Pantorrilla en máquina', 'Pantorrilla', 'Máquina', 'Standing_Calf_Raises'), _ca, _ma),
  CatalogExercise(_e('calf_raise', 'Elevación de talones', 'Pantorrilla', 'Peso corporal', 'Standing_Dumbbell_Calf_Raise'), _ca, _bw),
  CatalogExercise(_e('hanging_leg', 'Elevación de piernas colgado', 'Core', 'Barra fija', 'Hanging_Leg_Raise'), _co, _bw),
  CatalogExercise(_e('cable_crunch', 'Crunch en polea', 'Core', 'Máquina', 'Cable_Crunch'), _co, _ma),
  CatalogExercise(_e('plank', 'Plancha', 'Core', 'Peso corporal', 'Plank'), _co, _bw, fixedReps: '30-45 s'),
  CatalogExercise(_e('crunch', 'Crunch', 'Core', 'Peso corporal', 'Crunches'), _co, _bw),
];

/// Grupos musculares del catálogo, para filtrar.
List<String> catalogMuscleGroups() {
  final seen = <String>[];
  for (final c in kExerciseCatalog) {
    if (!seen.contains(c.exercise.muscleGroup)) seen.add(c.exercise.muscleGroup);
  }
  return seen;
}

final _curatedById = {for (final c in kExerciseCatalog) c.exercise.id: c};

/// Imágenes de un ejercicio. Las rutinas guardadas antes de que existieran
/// las imágenes las recuperan por id desde el catálogo curado.
List<String> exerciseImages(Exercise e) =>
    e.imageUrls.isNotEmpty ? e.imageUrls : (_curatedById[e.id]?.exercise.imageUrls ?? const []);
