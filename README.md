# 🏋️ GymTrack

> App para registrar tus entrenamientos y ver tu progreso en el gym. Funciona sin señal, en Android, iPhone (como app web instalable) y escritorio.

![Flutter](https://img.shields.io/badge/Flutter-3.35-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Hosting-FFCA28?logo=firebase)
![GetX](https://img.shields.io/badge/Estado-GetX-8A2BE2)

**App:** https://gymtrack-7d27c.web.app · **Diseño:** [Figma](https://www.figma.com/design/sMak9OBfPfxPM9bnshsOhh)

---

## Contenido

1. [Qué hace](#qué-hace)
2. [Tecnologías](#tecnologías)
3. [Arquitectura](#arquitectura)
4. [Estructura del proyecto](#estructura-del-proyecto)
5. [Modelo de datos](#modelo-de-datos)
6. [Cómo correrla](#cómo-correrla)
7. [Pruebas](#pruebas)
8. [Publicar (PWA)](#publicar-pwa)
9. [Cómo extenderla](#cómo-extenderla)
10. [Hoja de ruta](#hoja-de-ruta)

---

## Qué hace

### 🏠 Inicio
- El entrenamiento que toca hoy, con un botón para empezarlo.
- Métricas: **racha** de días seguidos, **entrenos de la semana** frente a tu meta y **volumen** levantado.
- La semana de un vistazo (días entrenados, hoy, próximos) y tu último entrenamiento.

### 💪 Entrenar
- Eliges una rutina (la de hoy aparece primero) y arranca un **cronómetro**.
- Tabla de series con **lo que hiciste la vez anterior**. Si marcas ✓ con los campos vacíos, usa esos valores.
- **Descanso automático** al marcar cada serie (±15 s o saltar) y vibración al terminar (en Android).
- Al finalizar: resumen con duración, series, volumen y **récords personales** nuevos.
- La sesión sigue activa aunque cambies de pestaña.

### 📋 Rutinas
- **Arma la tuya:** nombre, días, ejercicios de un catálogo de ~50 (o personalizados), series × repeticiones y descanso. Se reordenan arrastrando.
- **Recomiéndame:** 5 preguntas (objetivo, días, experiencia, equipo, tiempo) y genera un plan semanal completo.

| Días por semana | División |
|---|---|
| 2–3 | Cuerpo completo (A/B/C) |
| 4 | Torso / Pierna |
| 5–6 | Empuje / Tirón / Pierna |

Los ejercicios se eligen según tu equipo (gimnasio, mancuernas o sin equipo) y el volumen según tu objetivo y experiencia.

### 📈 Progreso
- Vista por **semana, mes o año**.
- Curva de **peso corporal** y botón para registrarlo.
- **Volumen** por día, semana o mes, con % de cambio frente al periodo anterior.
- **Récords personales** por ejercicio.

### 👤 Perfil
- Nombre, objetivo, altura y meta semanal (editables).
- **Medidas corporales** (pecho, brazo, cintura) con su cambio y color según si mejoran.
- Mis rutinas y cerrar sesión.

### 🔐 Cuenta y modo sin conexión
- Registro e inicio de sesión con correo y recuperación de contraseña.
- Cada usuario solo ve sus datos (reglas de Firestore).
- **Funciona sin señal**: los datos se guardan en el teléfono y se sincronizan al volver la conexión. El service worker permite abrir la app web offline.

---

## Tecnologías

| Capa | Tecnología |
|---|---|
| App | Flutter 3.35 · Dart 3.9 |
| Estado y dependencias | GetX |
| Autenticación | Firebase Auth (correo y contraseña) |
| Base de datos | Cloud Firestore con caché sin conexión |
| Hosting | Firebase Hosting (PWA) |
| Gráficas | `CustomPaint` propio (sin librerías) |
| Tipografía | Inter (`google_fonts`) |

---

## Arquitectura

**Clean Architecture** en tres capas. El dominio no conoce Flutter ni Firebase, así que el backend se puede cambiar sin tocar pantallas ni lógica.

```mermaid
flowchart LR
  subgraph Presentación
    P[Páginas] --> C[Controladores GetX]
  end
  subgraph Dominio
    U[Casos de uso] --> R[(Contratos<br/>repositorios)]
    E[Entidades]
  end
  subgraph Datos
    F[Firestore / Firebase Auth]
    M[En memoria]
  end
  C --> U
  F -. implementa .-> R
  M -. implementa .-> R
  DI[core/di] -. elige .-> F
  DI -. elige .-> M
```

### Principio Open/Closed en la práctica

| Si quieres… | Haces… | No tocas… |
|---|---|---|
| Cambiar Firebase por tu API (NestJS + Postgres) | Clases `Api…Repository` que implementen los contratos + un `case` en `core/di` | Pantallas, controladores, casos de uso |
| Nueva tarjeta en Inicio | Clase que extienda `ProgressMetric` | `GetHomeSummary`, `HomePage` |
| Nueva medida corporal (muslo…) | Una línea en `kMeasurementTypes` | Formulario, lista, cálculos |
| Nueva división de rutina | Clase que extienda `SplitTemplate` | `RoutineRecommender` |
| Nuevo ejercicio en el catálogo | Una línea en `kExerciseCatalog` | Selector y recomendador |

Además, los contratos de **lectura y escritura están separados** (`ProfileRepository` / `ProfileWriteRepository`). Así, quien solo lee no depende de algo que no usa.

### Sesión

`AuthGate` decide qué mostrar: carga, login o la app. Al iniciar sesión, `SessionBinding` crea los controladores con el **uid** del usuario; al cerrarla los destruye. Así nunca se mezclan datos entre cuentas.

---

## Estructura del proyecto

```
lib/
├── main.dart
├── firebase_options.dart          # generado por flutterfire configure
├── core/
│   ├── di/                        # ÚNICO lugar donde se elige la implementación
│   └── theme/                     # colores y estilos (tokens del diseño en Figma)
├── domain/                        # Dart puro
│   ├── entities/                  # Exercise, Routine, WorkoutSession, UserProfile…
│   ├── repositories/              # contratos (WorkoutRepository, AuthRepository…)
│   ├── catalog/                   # catálogo de ejercicios y rutinas de ejemplo
│   ├── metrics/                   # métricas de Inicio
│   ├── usecases/                  # resumen de Inicio, entrenar, progreso,
│   │                              # perfil, cuenta y recomendador de rutinas
│   └── utils/                     # fechas y formatos
├── data/
│   ├── mappers/                   # entidad ↔ Map (sirve para Firestore o REST)
│   └── repositories/              # Firestore, Firebase Auth y en memoria
└── presentation/
    ├── auth/                      # login, registro, AuthGate
    ├── shell/                     # barra inferior y SessionBinding
    ├── home/  workout/  progress/  profile/  routines/
    └── widgets/                   # componentes compartidos
web/
├── index.html  manifest.json      # PWA: nombre, íconos, iOS
├── gymtrack_sw.js                 # service worker (abrir sin señal)
└── icons/
test/                              # pruebas de dominio, controladores y widgets
firestore.rules                    # seguridad: cada usuario solo accede a lo suyo
firebase.json · .firebaserc        # Hosting, reglas y emuladores
deploy.ps1                         # compilar y publicar en un paso
```

---

## Modelo de datos

Todo vive bajo el uid del usuario en Firestore:

```
users/{uid}                       name, goal, weeklyGoal, heightCm
├── routines/{id}                 name, focus, estimatedMinutes, weekdays[],
│                                 exercises[{id, name, muscleGroup, equipment,
│                                            targetSets, targetReps, restSeconds}]
├── sessions/{id}                 routineName, startedAt, finishedAt,
│                                 logs[{exercise, sets[{reps, weightKg, completed}]}]
├── body_weights/{id}             date, kg
└── measurements/{id}             date, valuesCm{chest, arm, waist}
```

Es plano y con IDs explícitos, para poder llevarlo a tablas SQL sin dolor si algún día cambia el backend.

---

## Cómo correrla

### Requisitos
- Flutter 3.35+
- Para Firebase: Node.js y `firebase-tools` (`npm i -g firebase-tools`) y `flutterfire_cli` (`dart pub global activate flutterfire_cli`)
- Para los emuladores: Java JDK 21

```bash
flutter pub get
```

### Modos

| Modo | Comando | Para qué |
|---|---|---|
| **Datos de ejemplo** | `flutter run -d chrome` | Revisar pantallas rápido. Sin login ni Firebase. |
| **Emuladores locales** | Terminal 1: `firebase emulators:start --import ./emu-data --export-on-exit`<br>Terminal 2: `flutter run -d chrome --dart-define=BACKEND=firebase --dart-define=EMULATORS=true` | Probar todo (login, datos) sin tocar la nube. Panel en http://localhost:4000 |
| **Firebase real** | `flutter run -d chrome --dart-define=BACKEND=firebase` | Usar tus datos reales. |

En VS Code están las tres configuraciones en *Ejecutar y depurar* (F5).

### Configurar Firebase (una sola vez)
1. Crea el proyecto en la [consola de Firebase](https://console.firebase.google.com).
2. **Authentication** → habilita *Correo electrónico/contraseña*.
3. **Firestore Database** → crea la base en modo producción.
4. En la carpeta del proyecto:
   ```bash
   firebase login
   flutterfire configure
   ```

### Opciones de compilación

| `--dart-define` | Valores | Efecto |
|---|---|---|
| `BACKEND` | `memory` (por defecto) · `firebase` | Fuente de datos |
| `EMULATORS` | `true` · `false` (por defecto) | Usa Auth/Firestore locales |

---

## Pruebas

```bash
flutter test
```

Hay unas 50 pruebas que cubren:
- **Dominio:** métricas, récords, progreso por rango, medidas y el recomendador de rutinas (división, equipo, rotación, volumen).
- **Controladores:** entrenamiento, perfil, rutinas y autenticación.
- **Widgets:** Inicio, Entrenar, Progreso, Perfil y el flujo login → Inicio → cerrar sesión.

---

## Publicar (PWA)

```powershell
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

Compila con Firebase y publica en **https://gymtrack-7d27c.web.app** junto con las reglas de Firestore.

**Instalarla:**
- **iPhone:** abre el enlace en **Safari** → Compartir → *Añadir a pantalla de inicio*.
- **Android:** Chrome → ⋮ → *Instalar app*.

**Actualizar:** vuelve a correr `deploy.ps1`. En el teléfono, abre la app con señal, ciérrala del todo y vuelve a abrirla.

**Probar en el iPhone sin publicar:** `firebase hosting:channel:deploy pruebas` crea una URL temporal.

---

## Cómo extenderla

**Otro backend (p. ej. NestJS + Postgres):**
1. Crea `ApiWorkoutRepository implements WorkoutRepository` (y los demás contratos) en `data/repositories/`.
2. Reutiliza los mappers de `data/mappers/` para el JSON.
3. Agrega `Backend.api` y su `case` en `core/di/dependency_injection.dart`.
4. Para el login, verifica el token de Firebase en el backend (`firebase-admin`).

**Otra métrica en Inicio:**
```dart
class TotalWorkoutsMetric extends ProgressMetric {
  @override
  String get label => 'Entrenos totales';

  @override
  MetricAccent get accent => MetricAccent.orange;

  @override
  String compute({
    required List<WorkoutSession> sessions,
    required UserProfile profile,
    required DateTime now,
  }) =>
      '${sessions.length}';
}
// y agrégala a la lista de métricas en core/di/dependency_injection.dart
```

---

## Hoja de ruta

- [x] Inicio, Entrenar, Progreso y Perfil
- [x] Firebase Auth + Firestore con caché sin conexión
- [x] Crear/editar rutinas y recomendación de rutina
- [x] PWA instalable en iPhone y Android
- [ ] Recordatorios (notificaciones)
- [ ] Gráfica de progreso por ejercicio
- [ ] App nativa para iOS (TestFlight)
- [ ] Backend propio (NestJS + Postgres)

---

## Autor

**Luis Vega** — Ingeniería de Sistemas, Universidad Popular del Cesar.
