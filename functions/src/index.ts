/**
 * Coach de GymTrack con IA.
 *
 * La app llama a `coachWorkout` al terminar un entrenamiento. Esta función es
 * la única que conoce la llave del modelo (secreto de Firebase), valida lo que
 * recibe, limita el uso por persona y devuelve un mensaje corto en español.
 */
import Anthropic from "@anthropic-ai/sdk";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {defineSecret, defineString} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();

const anthropicKey = defineSecret("ANTHROPIC_API_KEY");
// Modelo configurable sin tocar código (archivo functions/.env).
const coachModel = defineString("COACH_MODEL", {default: "claude-haiku-5-5"});

const DAILY_LIMIT = 20; // mensajes por persona al día

const SYSTEM = `Eres el coach de GymTrack, una app para registrar entrenamientos.
Escribe en español neutro, cercano y motivador, en segunda persona ("tú").
Responde con 2 a 4 frases cortas, sin listas ni emojis excesivos (máximo uno).

Reglas:
- Basa todo SOLO en los datos recibidos. No inventes ejercicios, pesos ni récords.
- Si hay récords, celébralos primero.
- Si "nextSteps" trae "increase", recomienda subir a ese objetivo; si trae
  "deload", explica que bajar una sesión ayuda a recuperar y volver más fuerte.
- Respeta los objetivos de "nextSteps"; no propongas otros pesos.
- Menciona el progreso semanal si "weeklyGoal" es mayor que 0.
- No des consejos médicos ni de nutrición. Si algo sugiere dolor o lesión,
  recomienda bajar la carga y consultar a un profesional.`;

type Payload = {
  routine?: unknown;
  minutes?: unknown;
  goal?: unknown;
  sex?: unknown;
  weeklyDone?: unknown;
  weeklyGoal?: unknown;
  exercises?: unknown;
  records?: unknown;
  nextSteps?: unknown;
};

/** Se queda solo con los campos esperados y recorta tamaños. */
function sanitize(data: Payload) {
  const str = (v: unknown, max = 120) => (typeof v === "string" ? v.slice(0, max) : "");
  const num = (v: unknown) => (typeof v === "number" && isFinite(v) ? v : 0);
  const arr = (v: unknown, max = 15) => (Array.isArray(v) ? v.slice(0, max) : []);
  return {
    routine: str(data.routine),
    minutes: num(data.minutes),
    goal: str(data.goal),
    sex: str(data.sex, 20),
    weeklyDone: num(data.weeklyDone),
    weeklyGoal: num(data.weeklyGoal),
    exercises: arr(data.exercises).map((e: any) => ({
      name: str(e?.name),
      target: str(e?.target, 30),
      sets: arr(e?.sets, 12).map((s: unknown) => str(s, 20)),
    })),
    records: arr(data.records, 5).map((r: unknown) => str(r)),
    nextSteps: arr(data.nextSteps).map((n: any) => ({
      exercise: str(n?.exercise),
      kind: str(n?.kind, 20),
      target: str(n?.target, 30),
    })),
  };
}

/** Cuenta el uso del día; lanza error si se pasó del límite. */
async function checkQuota(uid: string) {
  const day = new Date().toISOString().slice(0, 10);
  const ref = getFirestore().doc(`users/${uid}/ai_usage/${day}`);
  await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = (snap.get("count") as number | undefined) ?? 0;
    if (count >= DAILY_LIMIT) {
      throw new HttpsError("resource-exhausted", "Límite diario del coach alcanzado.");
    }
    tx.set(ref, {count: FieldValue.increment(1)}, {merge: true});
  });
}

export const coachWorkout = onCall(
  {secrets: [anthropicKey], maxInstances: 5, timeoutSeconds: 30, memory: "256MiB"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Inicia sesión para usar el coach.");
    }
    await checkQuota(request.auth.uid);

    const workout = sanitize((request.data ?? {}) as Payload);
    if (workout.exercises.length === 0) {
      throw new HttpsError("invalid-argument", "El entrenamiento está vacío.");
    }

    const client = new Anthropic({apiKey: anthropicKey.value()});
    const response = await client.messages.create({
      model: coachModel.value(),
      max_tokens: 300,
      system: SYSTEM,
      messages: [{
        role: "user",
        content: "Entrenamiento recién terminado (JSON):\n" + JSON.stringify(workout),
      }],
    });

    const message = response.content
      .map((block) => (block.type === "text" ? block.text : ""))
      .join("")
      .trim();
    return {message};
  },
);
