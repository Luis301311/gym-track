# GymTrack

App en Flutter para registrar entrenamientos y seguir el progreso en el gym.
Diseño: [Figma – GymTrack](https://www.figma.com/design/sMak9OBfPfxPM9bnshsOhh)

## Correr el proyecto

```bash
cd gymtrack
flutter create . --org com.luisvega --project-name gymtrack   # genera android/, ios/, web/…
flutter pub get
flutter test          # pruebas del dominio
flutter run           # usa datos de ejemplo en memoria
```

Si `pub get` se queja de versiones, ejecuta `flutter pub upgrade --major-versions`.

### Con Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure            # reemplaza lib/firebase_options.dart
flutter run --dart-define=BACKEND=firebase
```

Estructura en Firestore:

```
users/{uid}                 name, goal, weeklyGoal
users/{uid}/routines/{id}   name, focus, estimatedMinutes, weekdays[], exercises[]
users/{uid}/sessions/{id}   routineName, startedAt, finishedAt, logs[{exercise, sets[]}]
users/{uid}/body_weights/{id}  date, kg
```

## Arquitectura (Clean Architecture + Open/Closed)

```
lib/
├─ domain/          Dart puro: no conoce Flutter ni Firebase
│  ├─ entities/       Exercise, WorkoutSet, WorkoutSession, Routine, UserProfile
│  ├─ repositories/   contratos abstractos (WorkoutRepository, …)
│  ├─ metrics/        ProgressMetric + Racha, Entrenos semana, Volumen
│  └─ usecases/       GetHomeSummary
├─ data/
│  ├─ mappers/        entidad <-> Map (reutilizable para Firestore o REST)
│  └─ repositories/   Firestore y en memoria
├─ core/
│  ├─ di/             ÚNICO lugar donde se elige la implementación
│  └─ theme/          tokens del diseño de Figma
└─ presentation/      páginas, controladores GetX y widgets
```

**Cambiar de backend** (p. ej. a NestJS + PostgreSQL): crear
`ApiWorkoutRepository implements WorkoutRepository` (y las demás), agregar
`Backend.api` en `core/di/dependency_injection.dart`. Nada más cambia.

**Pantalla Entrenar**: elige una rutina (la de hoy aparece primero) o
toca "Empezar entrenamiento" en Inicio. Cada serie muestra lo que hiciste la
vez anterior; si dejas kg/reps vacíos y marcas ✓, se usan esos valores.
Al marcar una serie arranca el descanso del ejercicio (±15 s o saltar).
Mantén presionada una serie para eliminarla. Al terminar se guardan solo las
series completadas y se detectan récords personales.

**Agregar una tarjeta de estadística**: crear una clase que extienda
`ProgressMetric` y añadirla a la lista en la inyección de dependencias.

## Siguiente

- [x] Pantalla Entrenar (sesión activa con series, descanso y guardado)
- [x] Pantalla Progreso (peso corporal, volumen semanal, récords)
- [ ] Perfil y medidas corporales
- [ ] Autenticación con Firebase Auth (hoy usa `demo-user`)
