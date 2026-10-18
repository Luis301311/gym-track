# GymTrack

App en Flutter para registrar entrenamientos y seguir el progreso en el gym.
Diseño: [Figma – GymTrack](https://www.figma.com/design/sMak9OBfPfxPM9bnshsOhh)

## Correr el proyecto

```bash
flutter pub get
flutter test                 # pruebas de dominio, controladores y widgets
flutter run -d chrome        # datos de ejemplo en memoria (sin login)
```

### Con Firebase

1. En [console.firebase.google.com](https://console.firebase.google.com) crea
   un proyecto (Analytics es opcional).
2. **Authentication → Comenzar → Correo electrónico/contraseña → Habilitar.**
3. **Firestore Database → Crear base de datos** → modo producción → región
   cercana (p. ej. `southamerica-east1` o `us-east1`).
4. En **Firestore → Reglas**, pega el contenido de `firestore.rules` y publica.
5. En la terminal, dentro del proyecto:

```bash
npm install -g firebase-tools        # si no lo tienes
firebase login
dart pub global activate flutterfire_cli
flutterfire configure                # elige el proyecto y las plataformas
flutter pub get
flutter run -d chrome --dart-define=BACKEND=firebase
```

En VS Code también puedes usar la configuración **"GymTrack (Firebase)"**.

Al crear una cuenta, la app guarda tu perfil y arranca sin rutinas: la armas tú
o pides una recomendación. Firestore guarda todo en caché: si en el gym no hay señal, el
entrenamiento se guarda en el teléfono y se sube solo al volver la conexión.

Estructura en Firestore (todo bajo el uid del usuario):

```
users/{uid}                     name, goal, weeklyGoal, heightCm
users/{uid}/routines/{id}       name, focus, estimatedMinutes, weekdays[], exercises[]
users/{uid}/sessions/{id}       routineName, startedAt, finishedAt, logs[{exercise, sets[]}]
users/{uid}/body_weights/{id}   date, kg
users/{uid}/measurements/{id}   date, valuesCm{chest, arm, waist}
```

## Publicar como app web (PWA) para iPhone y Android

```powershell
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

El script compila con Firebase (`--dart-define=BACKEND=firebase`) y publica en
**https://gymtrack-7d27c.web.app** junto con las reglas de Firestore.

Para instalarla:
- **iPhone:** abre el enlace en **Safari** → botón Compartir → **Añadir a
  pantalla de inicio**. (Tiene que ser Safari, no Chrome.)
- **Android:** abre el enlace en Chrome → menú ⋮ → **Instalar app**.

La app instalada guarda su propia sesión: la primera vez inicia sesión dentro
de ella. `web/gymtrack_sw.js` guarda los archivos de la app para que abra sin
señal; los datos ya funcionan sin conexión con la caché de Firestore.

## Arquitectura (Clean Architecture + Open/Closed)

```
lib/
├─ domain/          Dart puro: no conoce Flutter ni Firebase
│  ├─ entities/       Exercise, WorkoutSession, Routine, UserProfile, medidas…
│  ├─ repositories/   contratos (WorkoutRepository, AuthRepository, …)
│  ├─ catalog/        rutinas de inicio
│  ├─ metrics/        tarjetas de Inicio (ProgressMetric)
│  └─ usecases/       resumen de Inicio, entrenar, progreso, perfil, cuenta
├─ data/
│  ├─ mappers/        entidad <-> Map (reutilizable para Firestore o REST)
│  └─ repositories/   Firestore, Firebase Auth y en memoria
├─ core/
│  ├─ di/             ÚNICO lugar donde se elige la implementación
│  └─ theme/          tokens del diseño de Figma
└─ presentation/      auth, shell, home, workout, progress, profile, widgets
```

**Cambiar de backend** (p. ej. NestJS + Postgres): crear clases `Api…Repository`
que implementen los contratos y agregar `Backend.api` en
`core/di/dependency_injection.dart`. Pantallas, controladores y casos de uso no
cambian.

**Sesión:** `AuthGate` muestra login o la app. Al entrar, `SessionBinding` crea
los controladores con el uid real; al cerrar sesión se destruyen.

**Entrenar:** la rutina de hoy aparece primero. Cada serie muestra lo que
hiciste la vez anterior; si dejas kg/reps vacíos y marcas ✓, se usan esos
valores. Al marcar una serie arranca el descanso del ejercicio. Mantén
presionada una serie para eliminarla. Al terminar se detectan récords.

**Rutinas:** en *Mis rutinas* (Entrenar o Perfil) creas, editas, reordenas y
borras rutinas, con series × repeticiones y descanso por ejercicio, desde un
catálogo de ~50 ejercicios o personalizados. *Recomiéndame* genera un plan
con 5 preguntas (objetivo, días, experiencia, equipo, tiempo):
`RoutineRecommender` elige la división (cuerpo completo, torso/pierna o
empuje/tirón/pierna), los ejercicios según tu equipo y el volumen según
objetivo y experiencia. **Agregar una división nueva:** una clase que
extienda `SplitTemplate`.

**Agregar una tarjeta en Inicio:** una clase que extienda `ProgressMetric`.
**Agregar una medida corporal:** una línea en `kMeasurementTypes`.

## Siguiente

- [x] Inicio, Entrenar, Progreso y Perfil
- [x] Firebase Auth + Firestore con caché sin conexión
- [x] Crear/editar rutinas y recomendación de rutina
- [ ] Recordatorios (notificaciones)
