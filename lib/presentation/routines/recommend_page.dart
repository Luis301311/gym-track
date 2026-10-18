import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/routine_recommender.dart';
import '../../domain/utils/date_utils.dart';
import '../widgets/common_widgets.dart';
import '../profile/profile_controller.dart';
import 'routines_controller.dart';
import 'routines_page.dart' show gymAppBar;

/// Cuestionario corto -> plan semanal recomendado -> guardar.
class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final _c = Get.find<RoutinesController>();

  TrainingGoal _goal = TrainingGoal.hypertrophy;
  int _days = 3;
  ExperienceLevel _level = ExperienceLevel.beginner;
  EquipmentAccess _access = EquipmentAccess.gym;
  int _minutes = 60;

  ProfileController? get _profileCtrl => Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : null;
  late Sex _sex = _profileCtrl?.profile?.sex ?? Sex.unspecified;
  late TrainingEmphasis _emphasis = TrainingEmphasisX.suggestedFor(_sex);
  bool _emphasisTouched = false;

  RoutineRecommendation? _plan;
  late bool _replace = _c.list.isNotEmpty;
  bool _saving = false;

  void _generate() => setState(() {
        _plan = _c.recommend(RecommendationInput(
          goal: _goal,
          daysPerWeek: _days,
          level: _level,
          access: _access,
          minutes: _minutes,
          emphasis: _emphasis,
          sex: _sex,
        ));
      });

  Future<void> _save() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _saving = true);
    final msg = await _c.saveRecommendation(plan, replace: _replace);
    // Si eligió su sexo aquí, queda guardado en el perfil.
    if (msg == null) await _profileCtrl?.updateSex(_sex);
    if (!mounted) return;
    setState(() => _saving = false);
    if (msg != null) {
      showToast(msg);
      return;
    }
    Get.back<void>();
    showToast('¡Listo! Tu plan quedó guardado. Puedes ajustarlo cuando quieras.');
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      appBar: gymAppBar(plan == null ? 'Recomiéndame una rutina' : 'Tu plan'),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: plan == null ? _questions() : _preview(plan),
      ),
    );
  }

  // ------------------------------------------------------------ preguntas
  Widget _questions() => ListView(
        key: const ValueKey('q'),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const Text(
            'Responde 7 preguntas y te armo un plan semanal con ejercicios, '
            'series, repeticiones y descansos. Después puedes editar todo.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          _Question(
            title: '¿Cuál es tu objetivo?',
            options: {for (final g in TrainingGoal.values) g: g.label},
            value: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _Question(
            title: 'Sexo',
            options: {for (final x in Sex.values) x: x.label},
            value: _sex,
            onChanged: (v) => setState(() {
              _sex = v;
              // Mientras no haya elegido un enfoque, se sugiere según el sexo.
              if (!_emphasisTouched) {
                _emphasis = TrainingEmphasisX.suggestedFor(v);
              }
            }),
          ),
          _Question(
            title: '¿En qué quieres enfocarte?',
            options: {for (final e in TrainingEmphasis.values) e: e.label},
            value: _emphasis,
            onChanged: (v) => setState(() {
              _emphasis = v;
              _emphasisTouched = true;
            }),
          ),
          _Question(
            title: '¿Cuántos días por semana puedes entrenar?',
            options: {for (var d = 2; d <= 6; d++) d: '$d días'},
            value: _days,
            onChanged: (v) => setState(() => _days = v),
          ),
          _Question(
            title: '¿Qué experiencia tienes?',
            options: {for (final l in ExperienceLevel.values) l: l.label},
            value: _level,
            onChanged: (v) => setState(() => _level = v),
          ),
          _Question(
            title: '¿Con qué equipo cuentas?',
            options: {for (final a in EquipmentAccess.values) a: a.label},
            value: _access,
            onChanged: (v) => setState(() => _access = v),
          ),
          _Question(
            title: '¿Cuánto tiempo tienes por sesión?',
            options: const {45: '45 min', 60: '1 hora', 75: '1 h 15'},
            value: _minutes,
            onChanged: (v) => setState(() => _minutes = v),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Generar mi plan',
            trailingIcon: Icons.auto_awesome_rounded,
            onPressed: _generate,
          ),
        ],
      );

  // --------------------------------------------------------- vista previa
  Widget _preview(RoutineRecommendation plan) => ListView(
        key: const ValueKey('p'),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.soft(AppColors.primary, 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.splitName,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  '${_goal.label} · ${_emphasis.label} · $_days días · '
                  '${_level.label} · ${_access.label}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(_tip(),
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final r in plan.routines) ...[
            _PlanDay(routine: r),
            const SizedBox(height: 12),
          ],
          if (_c.list.isNotEmpty)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _replace,
              activeTrackColor: AppColors.primary,
              title: const Text('Reemplazar mis rutinas actuales',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                _replace
                    ? 'Se borrarán tus ${_c.list.length} rutinas (tu historial se conserva).'
                    : 'Las nuevas se sumarán a las que ya tienes.',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              onChanged: (v) => setState(() => _replace = v),
            ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: _saving ? 'Guardando…' : 'Guardar este plan',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _saving ? null : () => setState(() => _plan = null),
            child: const Text('Cambiar respuestas',
                style: TextStyle(color: AppColors.muted)),
          ),
        ],
      );

  String _tip() => switch (_goal) {
        TrainingGoal.hypertrophy =>
          'Sube el peso cuando completes todas las series en el tope del rango de repeticiones.',
        TrainingGoal.strength =>
          'Descansa completo entre series pesadas y prioriza la técnica sobre el peso.',
        TrainingGoal.fatLoss =>
          'Descansos cortos para mantener el ritmo; combínalo con alimentación y pasos diarios.',
        TrainingGoal.endurance =>
          'Repeticiones altas y descansos cortos; aumenta las repeticiones antes que el peso.',
      };
}

class _Question<T> extends StatelessWidget {
  final String title;
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  const _Question({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: e.key == value,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: e.key == value
                          ? AppColors.onPrimary
                          : AppColors.text),
                  onSelected: (_) => onChanged(e.key),
                ),
            ]),
          ],
        ),
      );
}

class _PlanDay extends StatelessWidget {
  final Routine routine;
  const _PlanDay({required this.routine});

  @override
  Widget build(BuildContext context) {
    final r = routine;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(r.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Pill(formatWeekdays(r.weekdays)),
          ]),
          const SizedBox(height: 2),
          Text('${r.focus} · ~${r.estimatedMinutes} min',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 10),
          for (final e in r.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(
                  child: Text(e.name, style: const TextStyle(fontSize: 14)),
                ),
                Text('${e.targetSets} × ${e.targetReps}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ]),
            ),
        ],
      ),
    );
  }
}
