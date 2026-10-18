import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/workout_usecases.dart';
import '../../domain/utils/date_utils.dart';
import '../../domain/utils/format.dart';
import '../routines/recommend_page.dart';
import '../routines/routine_editor_page.dart';
import '../routines/routines_page.dart';
import '../shell/shell_controller.dart';
import '../widgets/common_widgets.dart';
import 'workout_controller.dart';
import 'workout_draft.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WorkoutController>();
    return SafeArea(
      bottom: false,
      child: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: c.isActive
              ? _ActiveWorkout(key: const ValueKey('active'), c: c)
              : _RoutinePicker(key: const ValueKey('picker'), c: c),
        ),
      ),
    );
  }
}

// ============================================================================
// Selector de rutina
// ============================================================================

class _RoutinePicker extends StatelessWidget {
  final WorkoutController c;
  const _RoutinePicker({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.loadingRoutines.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (c.routinesError.value != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(c.routinesError.value!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Reintentar', onPressed: c.loadRoutines),
            ]),
          ),
        );
      }

      final today = DateTime.now().weekday;
      final list = [...c.availableRoutines]..sort((a, b) {
          final at = a.weekdays.contains(today) ? 0 : 1;
          final bt = b.weekdays.contains(today) ? 0 : 1;
          return at.compareTo(bt);
        });
      final starting = c.starting.value;

      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Row(children: [
            const Expanded(
              child: Text('Entrenar',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            if (list.isNotEmpty)
              TextButton.icon(
                onPressed: () => Get.to<void>(() => const RoutinesPage()),
                icon: const Icon(Icons.tune_rounded,
                    size: 18, color: AppColors.primary),
                label: const Text('Mis rutinas',
                    style: TextStyle(color: AppColors.primary)),
              ),
          ]),
          const SizedBox(height: 4),
          Text(
              list.isEmpty
                  ? 'Primero necesitas una rutina'
                  : 'Elige una rutina para empezar',
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 20),
          if (list.isEmpty) const _NoRoutines(),
          for (final r in list) ...[
            _RoutineCard(
              routine: r,
              isToday: r.weekdays.contains(today),
              onTap: starting ? null : () => c.start(r),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

/// Estado vacío: armar la rutina o pedir una recomendación.
class _NoRoutines extends StatelessWidget {
  const _NoRoutines();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Column(children: [
              Icon(Icons.fitness_center_rounded,
                  size: 36, color: AppColors.primary),
              SizedBox(height: 12),
              Text('Arma tu plan de entrenamiento',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text(
                  'Créalo a tu gusto o responde unas preguntas y te recomendamos uno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ]),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Recomiéndame una rutina',
            trailingIcon: Icons.auto_awesome_rounded,
            onPressed: () => Get.to<void>(() => const RecommendPage()),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Get.to<void>(() => const RoutineEditorPage()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.surface2, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Crear la mía',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
        ],
      );
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final bool isToday;
  final VoidCallback? onTap;

  const _RoutineCard({
    required this.routine,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: isToday
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.soft(AppColors.primary)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(routine.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        const Pill('HOY'),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(routine.focus,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '${routine.exercises.length} ejercicios · '
                      '~${routine.estimatedMinutes} min · '
                      '${formatWeekdays(routine.weekdays)}',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_circle_fill_rounded,
                  size: 34, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Sesión activa
// ============================================================================

class _ActiveWorkout extends StatelessWidget {
  final WorkoutController c;
  const _ActiveWorkout({super.key, required this.c});

  String _plan(ExerciseDraft d) {
    final prev = d.previousFor(0);
    final base = '${d.sets.length} × ${d.exercise.targetReps}';
    return prev == null ? base : '$base · ${formatSet(prev.weightKg, prev.reps)}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = c.routine.value;
      // Durante la animación de salida la sesión ya pudo cerrarse.
      if (r == null || c.drafts.isEmpty) return const SizedBox.shrink();

      final i = c.current.value;
      final d = c.drafts[i];
      final next = i + 1 < c.drafts.length ? c.drafts[i + 1] : null;

      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _WorkoutHeader(c: c, routine: r),
          const SizedBox(height: 14),
          _Progress(index: i, total: c.drafts.length, progress: c.progress),
          const SizedBox(height: 14),
          _ExerciseCard(c: c, index: i, draft: d),
          _RestCard(c: c),
          const SizedBox(height: 14),
          SectionTitle(
            next == null ? 'Último ejercicio' : 'Siguiente',
            action: 'Ver rutina',
            onAction: () => _showRoutineSheet(c),
          ),
          const SizedBox(height: 10),
          if (next != null) ...[
            ExerciseRow(
              name: next.exercise.name,
              detail: _plan(next),
              onTap: () => c.goTo(i + 1),
            ),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: c.saving.value ? 'Guardando…' : 'Terminar entrenamiento',
            onPressed: c.saving.value ? null : () => _confirmFinish(c),
          ),
        ],
      );
    });
  }
}

class _WorkoutHeader extends StatelessWidget {
  final WorkoutController c;
  final Routine routine;
  const _WorkoutHeader({required this.c, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(routine.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('Entrenamiento en curso',
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.soft(AppColors.primary),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            // Solo este texto se redibuja cada segundo.
            Obx(() => Text(formatDuration(c.elapsed.value),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()]))),
          ]),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Descartar entrenamiento',
          icon: const Icon(Icons.close_rounded, color: AppColors.muted),
          onPressed: () async {
            final ok = await _confirm(
              title: '¿Descartar entrenamiento?',
              message: 'Se perderán las series que registraste en esta sesión.',
              confirm: 'Descartar',
              destructive: true,
            );
            if (ok) c.discard();
          },
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  final int index;
  final int total;
  final double progress;
  const _Progress(
      {required this.index, required this.total, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Ejercicio ${index + 1} de $total',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted)),
          Text('${(progress * 100).round()}%',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: progress),
          duration: const Duration(milliseconds: 300),
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: 8,
            backgroundColor: AppColors.surface2,
            color: AppColors.primary,
          ),
        ),
      ),
    ]);
  }
}

// Anchos de columna de la tabla de series.
const _wSet = 36.0, _wKg = 64.0, _wReps = 56.0, _wCheck = 40.0, _gap = 8.0;

class _ExerciseCard extends StatelessWidget {
  final WorkoutController c;
  final int index;
  final ExerciseDraft draft;
  const _ExerciseCard(
      {required this.c, required this.index, required this.draft});

  @override
  Widget build(BuildContext context) {
    final e = draft.exercise;
    final info = [
      'Objetivo ${e.targetSets} × ${e.targetReps}',
      if (e.equipment.isNotEmpty) e.equipment,
      'Descanso ${e.restSeconds} s',
    ].join(' · ');
    const header = TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted);
    final active = draft.activeIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                draft.isComplete
                    ? Icons.check_rounded
                    : Icons.fitness_center_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(info,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            _NavButton(
              icon: Icons.chevron_left_rounded,
              onTap: index > 0 ? () => c.goTo(index - 1) : null,
            ),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              onTap: index < c.drafts.length - 1
                  ? () => c.goTo(index + 1)
                  : null,
            ),
          ]),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              SizedBox(
                  width: _wSet,
                  child: Text('SERIE', textAlign: TextAlign.center, style: header)),
              SizedBox(width: _gap),
              Expanded(child: Text('ANTERIOR', style: header)),
              SizedBox(width: _gap),
              SizedBox(
                  width: _wKg,
                  child: Text('KG', textAlign: TextAlign.center, style: header)),
              SizedBox(width: _gap),
              SizedBox(
                  width: _wReps,
                  child: Text('REPS', textAlign: TextAlign.center, style: header)),
              SizedBox(width: _gap),
              SizedBox(width: _wCheck),
            ]),
          ),
          for (var si = 0; si < draft.sets.length; si++)
            _SetRow(
              key: ValueKey('${e.id}-$si'),
              draft: draft.sets[si],
              previous: draft.previousFor(si),
              targetReps: e.targetReps,
              number: si + 1,
              active: si == active,
              onKg: (v) => c.updateKg(index, si, v),
              onReps: (v) => c.updateReps(index, si, v),
              onToggle: () {
                FocusScope.of(context).unfocus();
                final msg = c.toggleSet(index, si);
                if (msg != null) _toast(msg);
              },
              onRemove: draft.sets.length > 1
                  ? () async {
                      final ok = await _confirm(
                        title: 'Eliminar serie ${si + 1}',
                        message: '¿Quitar esta serie del ejercicio?',
                        confirm: 'Eliminar',
                        destructive: true,
                      );
                      if (ok) c.removeSet(index, si);
                    }
                  : null,
            ),
          const SizedBox(height: 10),
          Material(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => c.addSet(index),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Añadir serie',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(icon),
        color: AppColors.text,
        disabledColor: AppColors.surface2,
      );
}

class _SetRow extends StatefulWidget {
  final SetDraft draft;
  final WorkoutSet? previous;
  final String targetReps;
  final int number;
  final bool active;
  final ValueChanged<String> onKg;
  final ValueChanged<String> onReps;
  final VoidCallback onToggle;
  final VoidCallback? onRemove;

  const _SetRow({
    super.key,
    required this.draft,
    required this.previous,
    required this.targetReps,
    required this.number,
    required this.active,
    required this.onKg,
    required this.onReps,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final _kg = TextEditingController(text: widget.draft.kg);
  late final _reps = TextEditingController(text: widget.draft.reps);

  @override
  void didUpdateWidget(covariant _SetRow old) {
    super.didUpdateWidget(old);
    // El controlador puede completar los campos (valores de la vez anterior)
    // o reordenar series: se sincroniza el texto con el borrador.
    if (_kg.text != widget.draft.kg) _kg.text = widget.draft.kg;
    if (_reps.text != widget.draft.reps) _reps.text = widget.draft.reps;
  }

  @override
  void dispose() {
    _kg.dispose();
    _reps.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController ctrl, {
    required String hint,
    required bool decimal,
    required ValueChanged<String> onChanged,
  }) {
    final done = widget.draft.done;
    OutlineInputBorder border([Color? color, double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: color == null
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );
    return SizedBox(
      height: 36,
      child: TextField(
        controller: ctrl,
        readOnly: done,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        cursorColor: AppColors.primary,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
          LengthLimitingTextInputFormatter(decimal ? 6 : 3),
        ],
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: done ? Colors.transparent : AppColors.surface2,
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.muted, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          border: border(),
          enabledBorder: widget.active && !done
              ? border(AppColors.soft(AppColors.primary, 0.4))
              : border(),
          focusedBorder: done ? border() : border(AppColors.primary, 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.draft.done;
    final prev = widget.previous;
    return GestureDetector(
      onLongPress: widget.onRemove,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: done
              ? AppColors.soft(AppColors.primary, 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          SizedBox(
            width: _wSet,
            child: Text('${widget.number}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: done || widget.active
                        ? AppColors.text
                        : AppColors.muted)),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: Text(
              prev == null ? '—' : formatSet(prev.weightKg, prev.reps),
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _wKg,
            child: _field(_kg,
                hint: prev == null ? 'kg' : formatKg(prev.weightKg),
                decimal: true,
                onChanged: widget.onKg),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _wReps,
            child: _field(_reps,
                hint: prev == null ? widget.targetReps : '${prev.reps}',
                decimal: false,
                onChanged: widget.onReps),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _wCheck,
            height: 36,
            child: Material(
              color: done ? AppColors.primary : AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.onToggle,
                child: Icon(Icons.check_rounded,
                    size: 18,
                    color: done ? AppColors.onPrimary : AppColors.muted),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RestCard extends StatelessWidget {
  final WorkoutController c;
  const _RestCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final remaining = c.restRemaining.value;
      final total = c.restTotal.value;
      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: remaining <= 0
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Descanso',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted)),
                            Text(
                              formatDuration(Duration(seconds: remaining)),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ]),
                            ),
                          ],
                        ),
                      ),
                      _Chip('−15 s', onTap: () => c.adjustRest(-15)),
                      const SizedBox(width: 8),
                      _Chip('+15 s', onTap: () => c.adjustRest(15)),
                      const SizedBox(width: 8),
                      _Chip('Saltar', primary: true, onTap: c.skipRest),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : remaining / total,
                        minHeight: 4,
                        backgroundColor: AppColors.surface2,
                        color: AppColors.primary,
                      ),
                    ),
                  ]),
                ),
              ),
      );
    });
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _Chip(this.label, {required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) => Material(
        color: primary ? AppColors.primary : AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary ? AppColors.onPrimary : AppColors.text)),
          ),
        ),
      );
}

// ============================================================================
// Hojas, diálogos y avisos
// ============================================================================

void _showRoutineSheet(WorkoutController c) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final r = c.routine.value;
          if (r == null) return const SizedBox.shrink();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(r.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (var i = 0; i < c.drafts.length; i++)
                _RoutineStep(
                  draft: c.drafts[i],
                  isCurrent: i == c.current.value,
                  onTap: () {
                    c.goTo(i);
                    Get.back();
                  },
                ),
            ],
          );
        }),
      ),
    ),
    isScrollControlled: true,
  );
}

class _RoutineStep extends StatelessWidget {
  final ExerciseDraft draft;
  final bool isCurrent;
  final VoidCallback onTap;
  const _RoutineStep(
      {required this.draft, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final complete = draft.isComplete;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: complete ? AppColors.primary : AppColors.surface2,
              border: isCurrent && !complete
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: complete
                ? const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.onPrimary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(draft.exercise.name,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? AppColors.primary : AppColors.text)),
          ),
          Text('${draft.doneCount}/${draft.sets.length} series',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

Future<void> _confirmFinish(WorkoutController c) async {
  if (c.doneSets == 0) {
    final discard = await _confirm(
      title: 'Aún no completas ninguna serie',
      message: 'No hay nada que guardar. ¿Quieres descartar el entrenamiento?',
      confirm: 'Descartar',
      destructive: true,
    );
    if (discard) c.discard();
    return;
  }

  final pending = c.totalSets - c.doneSets;
  if (pending > 0) {
    final ok = await _confirm(
      title: '¿Terminar entrenamiento?',
      message: pending == 1
          ? 'Te falta 1 serie. Se guardará solo lo que completaste.'
          : 'Te faltan $pending series. Se guardará solo lo que completaste.',
      confirm: 'Terminar',
    );
    if (!ok) return;
  }

  try {
    final result = await c.finish();
    Get.find<ShellController>().goTo(ShellController.home);
    await Get.dialog<void>(_ResultDialog(result: result));
  } catch (e) {
    _toast('No se pudo guardar el entrenamiento: $e');
  }
}

Future<bool> _confirm({
  required String title,
  required String message,
  required String confirm,
  bool destructive = false,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text(message, style: const TextStyle(color: AppColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(confirm,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: destructive ? AppColors.orange : AppColors.primary)),
        ),
      ],
    ),
  );
  return result ?? false;
}

void _toast(String message) {
  Get.closeAllSnackbars();
  Get.snackbar(
    'GymTrack',
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    colorText: AppColors.text,
    backgroundColor: AppColors.surface2,
    duration: const Duration(seconds: 2),
  );
}

class _ResultDialog extends StatelessWidget {
  final WorkoutResult result;
  const _ResultDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final s = result.session;
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.soft(AppColors.primary),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text('¡Entrenamiento guardado!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(s.routineName,
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: StatCard(
                      value: formatDuration(s.duration), label: 'Duración')),
              const SizedBox(width: 8),
              Expanded(
                  child: StatCard(
                      value: '${result.completedSets}',
                      label: 'Series',
                      accent: AppColors.orange)),
              const SizedBox(width: 8),
              Expanded(
                  child: StatCard(
                      value: formatVolume(s.volume),
                      label: 'Volumen',
                      accent: AppColors.blue)),
            ]),
            if (result.records.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Nuevos récords',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              for (final r in result.records)
                ExerciseRow(
                  name: r.exercise.name,
                  detail: '${formatKg(r.set.weightKg)} kg × ${r.set.reps}'
                      '${r.previousBestKg == null ? '' : ' · antes ${formatKg(r.previousBestKg!)} kg'}',
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.orange,
                ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Listo', onPressed: () => Get.back()),
          ],
        ),
      ),
    );
  }
}
