import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/get_home_summary.dart';
import '../../domain/utils/date_utils.dart';
import '../../domain/utils/format.dart';
import '../shell/shell_controller.dart';
import '../workout/workout_controller.dart';
import '../widgets/common_widgets.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        if (c.error.value != null) {
          return _ErrorView(message: c.error.value!, onRetry: c.load);
        }
        final s = c.summary.value;
        if (s == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            _Header(summary: s),
            const SizedBox(height: 20),
            _TodayCard(summary: s),
            const SizedBox(height: 20),
            _Stats(metrics: s.metrics),
            const SizedBox(height: 20),
            SectionTitle(
              'Esta semana',
              action: '${s.weeklyDone} de ${s.profile.weeklyGoal} entrenos',
            ),
            const SizedBox(height: 12),
            _WeekRow(days: s.week),
            const SizedBox(height: 20),
            _LastWorkout(session: s.lastSession),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final HomeSummary summary;
  const _Header({required this.summary});

  @override
  Widget build(BuildContext context) {
    final firstName = summary.profile.name.split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatLongDateEs(summary.now),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 4),
              Text('Hola, $firstName',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        _CircleButton(
          color: AppColors.surface,
          child: const Icon(Icons.notifications_none_rounded,
              size: 20, color: AppColors.text),
        ),
        const SizedBox(width: 10),
        _CircleButton(
          color: AppColors.primary,
          child: Text(summary.profile.initials,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary)),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Color color;
  final Widget child;
  const _CircleButton({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: child,
      );
}

class _TodayCard extends StatelessWidget {
  final HomeSummary summary;
  const _TodayCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final r = summary.todayRoutine;
    const dim = TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xB30E0F12)); // onPrimary al 70 %

    final String tag, title, subtitle;
    if (r == null) {
      tag = 'HOY · DESCANSO';
      title = 'Día de recuperación';
      subtitle = 'Estira, camina y descansa bien';
    } else {
      tag = 'HOY · ${r.name.toUpperCase()}';
      title = r.focus;
      subtitle = '${r.exercises.length} ejercicios · ~${r.estimatedMinutes} min';
    }
    final workout = Get.find<WorkoutController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag,
              style: dim.copyWith(
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9)),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, style: dim),
          const SizedBox(height: 20),
          Obx(() {
            final active = workout.isActive;
            final String cta;
            if (active) {
              cta = 'Continuar entrenamiento';
            } else if (r == null) {
              cta = 'Entrenar de todas formas';
            } else if (summary.trainedToday) {
              cta = 'Entrenar otra vez';
            } else {
              cta = 'Empezar entrenamiento';
            }
            return PrimaryButton(
              label: cta,
              dark: true,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () {
                // Con rutina para hoy se arranca directo; si no, se abre el
                // selector de rutinas en la pestaña Entrenar.
                if (!active && r != null) workout.start(r);
                Get.find<ShellController>().goTo(ShellController.workout);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final List<MetricValue> metrics;
  const _Stats({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              value: metrics[i].value,
              label: metrics[i].label,
              accent: AppColors.accent(metrics[i].accent),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<WeekDay> days;
  const _WeekRow({required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (final d in days) _DayBubble(day: d)],
    );
  }
}

class _DayBubble extends StatelessWidget {
  final WeekDay day;
  const _DayBubble({required this.day});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Border? border) = switch (day.status) {
      DayStatus.done => (AppColors.primary, AppColors.onPrimary, null),
      DayStatus.today => (
          AppColors.surface,
          AppColors.primary,
          Border.all(color: AppColors.primary, width: 2)
        ),
      DayStatus.upcoming => (AppColors.surface, AppColors.text, null),
      DayStatus.rest => (AppColors.surface, AppColors.muted, null),
    };
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
      child: Text(day.initial,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _LastWorkout extends StatelessWidget {
  final WorkoutSession? session;
  const _LastWorkout({required this.session});

  String _detail(ExerciseLog log) {
    final best = log.bestSet;
    final count = log.completedSets.length;
    if (best == null) return 'Sin series completadas';
    final kg =
        best.weightKg == 0 ? 'peso corporal' : '${formatKg(best.weightKg)} kg';
    return '$count series · ${best.reps} reps · $kg';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Último entrenamiento', action: 'Ver todo'),
        const SizedBox(height: 10),
        if (session == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Aún no registras entrenamientos. ¡Hoy es buen día!',
                style: TextStyle(color: AppColors.muted)),
          )
        else
          for (final log in session!.logs) ...[
            ExerciseRow(name: log.exercise.name, detail: _detail(log)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Reintentar', onPressed: onRetry),
            ],
          ),
        ),
      );
}
