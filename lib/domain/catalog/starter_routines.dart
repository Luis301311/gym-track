import '../entities/entities.dart';

/// Ejercicios y rutinas con las que arranca toda cuenta nueva (Push/Pull/Legs).
/// Se usan para sembrar Firestore y como datos de ejemplo en memoria.

const exBench = Exercise(id: 'bench', name: 'Press de banca', muscleGroup: 'Pecho', equipment: 'Barra', targetSets: 4, targetReps: '6-10', restSeconds: 120);
const exOhp = Exercise(id: 'ohp', name: 'Press militar', muscleGroup: 'Hombro', equipment: 'Barra', targetSets: 4, targetReps: '6-10', restSeconds: 120);
const exDips = Exercise(id: 'dips', name: 'Fondos', muscleGroup: 'Tríceps', equipment: 'Paralelas');
const exRow = Exercise(id: 'row', name: 'Remo con barra', muscleGroup: 'Espalda', equipment: 'Barra', targetSets: 4, targetReps: '8-10', restSeconds: 120);
const exPullup = Exercise(id: 'pullup', name: 'Dominadas', muscleGroup: 'Espalda', equipment: 'Barra fija');
const exCurl = Exercise(id: 'curl', name: 'Curl de bíceps', muscleGroup: 'Bíceps', equipment: 'Mancuernas', restSeconds: 60, targetReps: '10-12');
const exSquat = Exercise(id: 'squat', name: 'Sentadilla', muscleGroup: 'Piernas', equipment: 'Barra', restSeconds: 150, targetSets: 4, targetReps: '5-8');
const exRdl = Exercise(id: 'rdl', name: 'Peso muerto rumano', muscleGroup: 'Femoral', equipment: 'Barra', restSeconds: 120);
const exLunge = Exercise(id: 'lunge', name: 'Zancadas', muscleGroup: 'Piernas', equipment: 'Mancuernas');

const kStarterRoutines = <Routine>[
  Routine(
    id: 'push', name: 'Push Day', focus: 'Pecho, hombro y tríceps',
    exercises: [exBench, exOhp, exDips], estimatedMinutes: 55, weekdays: [1, 4],
  ),
  Routine(
    id: 'pull', name: 'Pull Day', focus: 'Espalda y bíceps',
    exercises: [exRow, exPullup, exCurl], estimatedMinutes: 50, weekdays: [2, 5],
  ),
  Routine(
    id: 'legs', name: 'Leg Day', focus: 'Piernas y glúteos',
    exercises: [exSquat, exRdl, exLunge], estimatedMinutes: 60, weekdays: [3, 6],
  ),
];
