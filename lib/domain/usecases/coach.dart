import 'dart:async';

import '../entities/entities.dart';
import '../utils/format.dart';
import 'progression.dart';
import 'workout_usecases.dart';

/// Lo que el coach necesita para comentar un entrenamiento.
class CoachRequest {
  final WorkoutResult result;
  final UserProfile? profile;
  final int weeklyDone;

  const CoachRequest({
    required this.result,
    this.profile,
    this.weeklyDone = 0,
  });

  /// Resumen compacto para enviar a un modelo de IA. No incluye nombre,
  /// correo ni ids: solo el entrenamiento y el contexto mínimo.
  Map<String, dynamic> toPayload() {
    final s = result.session;
    return {
      'routine': s.routineName,
      'minutes': s.duration.inMinutes,
      'goal': profile?.goal ?? '',
      'sex': profile?.sex.name ?? 'unspecified',
      'weeklyDone': weeklyDone,
      'weeklyGoal': profile?.weeklyGoal ?? 0,
      'exercises': [
        for (final log in s.logs)
          {
            'name': log.exercise.name,
            'target': '${log.exercise.targetSets} × ${log.exercise.targetReps}',
            'sets': [
              for (final set in log.completedSets) formatSet(set.weightKg, set.reps)
            ],
          },
      ],
      'records': [
        for (final r in result.records)
          '${r.exercise.name}: ${formatSet(r.set.weightKg, r.set.reps)}'
              '${r.previousBestKg == null ? '' : ' (antes ${formatKg(r.previousBestKg!)} kg)'}',
      ],
      'nextSteps': [
        for (final n in result.nextSteps)
          {'exercise': n.exercise.name, 'kind': n.kind.name, 'target': n.target},
      ],
    };
  }
}

/// Coach que comenta el entrenamiento al terminar.
///
/// OPEN/CLOSED: hoy hay un coach local (reglas) y uno con IA (Cloud Function).
/// Otro proveedor de IA = otra implementación; la pantalla no cambia.
abstract class AiCoach {
  Future<String> workoutFeedback(CoachRequest request);
}

/// Coach sin IA: arma el mensaje con reglas. Gratis, instantáneo y sin señal.
class LocalCoach implements AiCoach {
  const LocalCoach();

  @override
  Future<String> workoutFeedback(CoachRequest r) async {
    final s = r.result.session;
    final parts = <String>[];
    final done = r.result.session.logs
        .fold<int>(0, (a, l) => a + l.completedSets.length);
    final planned =
        s.logs.fold<int>(0, (a, l) => a + l.exercise.targetSets);

    if (r.result.records.isNotEmpty) {
      final rec = r.result.records.first;
      parts.add('¡Nuevo récord en ${rec.exercise.name}: '
          '${formatSet(rec.set.weightKg, rec.set.reps)}!');
    } else if (planned > 0 && done >= planned) {
      parts.add('Sesión completa: $done series en ${s.duration.inMinutes} min.');
    } else {
      parts.add('Buen trabajo: $done series en ${s.duration.inMinutes} min.');
    }

    final ups = r.result.nextSteps
        .where((n) => n.kind == ProgressionKind.increase)
        .toList();
    if (ups.isNotEmpty) {
      final names = ups.take(2).map((n) => '${n.exercise.name} a ${formatKg(n.kg!)} kg');
      parts.add('La próxima vez sube ${names.join(' y ')}.');
    }
    final deload = r.result.nextSteps
        .where((n) => n.kind == ProgressionKind.deload)
        .firstOrNullSafe;
    if (deload != null) {
      parts.add('En ${deload.exercise.name} baja a ${formatKg(deload.kg!)} kg '
          'una sesión para recuperar y volver a subir.');
    } else if (ups.isEmpty) {
      final hold = r.result.nextSteps
          .where((n) => n.kind == ProgressionKind.hold && n.reps != null)
          .firstOrNullSafe;
      if (hold != null) {
        parts.add('En ${hold.exercise.name} mantén el peso y busca '
            '${hold.reps} reps por serie.');
      }
    }

    final goal = r.profile?.weeklyGoal ?? 0;
    if (goal > 0) {
      parts.add(r.weeklyDone >= goal
          ? '¡Cumpliste tu meta de $goal entrenos esta semana!'
          : 'Llevas ${r.weeklyDone} de $goal entrenos esta semana.');
    }
    return parts.join(' ');
  }
}

/// Usa [primary] (IA) y, si falla o tarda, [fallback] (local).
class FallbackCoach implements AiCoach {
  final AiCoach primary;
  final AiCoach fallback;
  final Duration timeout;

  const FallbackCoach(
    this.primary,
    this.fallback, {
    this.timeout = const Duration(seconds: 15),
  });

  @override
  Future<String> workoutFeedback(CoachRequest r) async {
    try {
      final text = await primary.workoutFeedback(r).timeout(timeout);
      if (text.trim().isNotEmpty) return text.trim();
    } catch (_) {
      // Sin señal, sin cuota o error del servicio: seguimos con el local.
    }
    return fallback.workoutFeedback(r);
  }
}

extension _FirstOrNullSafe<T> on Iterable<T> {
  T? get firstOrNullSafe {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
