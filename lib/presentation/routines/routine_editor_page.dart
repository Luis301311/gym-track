import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/catalog/exercise_catalog.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../widgets/common_widgets.dart';
import 'routines_controller.dart';
import 'routines_page.dart' show gymAppBar;

/// L, M, X (miércoles), J, V, S, D: la X evita confundir martes y miércoles.
const kWeekdayChips = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// Crear o editar una rutina.
class RoutineEditorPage extends StatefulWidget {
  final Routine? routine;
  const RoutineEditorPage({super.key, this.routine});

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  final _c = Get.find<RoutinesController>();
  late final _name = TextEditingController(text: widget.routine?.name ?? '');
  late final Set<int> _days = {...?widget.routine?.weekdays};
  late final List<Exercise> _exercises = [...?widget.routine?.exercises];
  bool _saving = false;

  bool get _isNew => widget.routine == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final routine = Routine.build(
      id: widget.routine?.id ?? _c.newId(),
      name: _name.text.trim(),
      exercises: _exercises,
      weekdays: _days.toList(),
    );
    final msg = await _c.save(routine);
    if (!mounted) return;
    setState(() => _saving = false);
    if (msg != null) {
      showToast(msg);
      return;
    }
    Get.back<void>();
    showToast(_isNew ? 'Rutina creada.' : 'Rutina actualizada.');
  }

  void _addExercise() {
    AppSheet.show<void>(
      title: 'Añadir ejercicio',
      child: _ExercisePicker(
        alreadyAdded: _exercises.map((e) => e.id).toSet(),
        onPick: (e) {
          setState(() => _exercises.add(e));
          Get.back<void>();
        },
      ),
    );
  }

  void _editTargets(int index) {
    AppSheet.show<void>(
      title: _exercises[index].name,
      child: _TargetsForm(
        exercise: _exercises[index],
        onSave: (e) {
          setState(() => _exercises[index] = e);
          Get.back<void>();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = Routine.build(
        id: '', name: '', exercises: _exercises, weekdays: const []);
    return Scaffold(
      appBar: gymAppBar(
        _isNew ? 'Nueva rutina' : 'Editar rutina',
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Guardando…' : 'Guardar',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        buildDefaultDragHandles: false,
        itemCount: _exercises.length,
        onReorder: (from, to) => setState(() {
          if (to > from) to--;
          _exercises.insert(to, _exercises.removeAt(from));
        }),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _name,
              label: 'Nombre (p. ej. Torso A, Pierna, Push Day)',
              capitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 18),
            const Text('¿Qué días la haces?',
                style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 8),
            Row(children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayChip(
                      label: kWeekdayChips[d - 1],
                      selected: _days.contains(d),
                      onTap: () => setState(() =>
                          _days.contains(d) ? _days.remove(d) : _days.add(d)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 22),
            Row(children: [
              const Expanded(
                child: Text('Ejercicios',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              if (_exercises.isNotEmpty)
                Text(
                  '~${preview.estimatedMinutes} min',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
            ]),
            if (_exercises.length > 1)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Arrastra ≡ para cambiar el orden. Toca para editar series.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            const SizedBox(height: 10),
          ],
        ),
        itemBuilder: (_, i) {
          final e = _exercises[i];
          return Padding(
            key: ValueKey('${e.id}-$i'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => _editTargets(i),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                  child: Row(children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_indicator_rounded,
                            color: AppColors.muted),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showExerciseHowTo(e, exerciseImages(e)),
                      child: ExerciseThumb(urls: exerciseImages(e), size: 44),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${e.targetSets} × ${e.targetReps} · '
                            'descanso ${e.restSeconds} s · ${e.muscleGroup}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar',
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: AppColors.muted),
                      onPressed: () => setState(() => _exercises.removeAt(i)),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
        footer: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Material(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: _addExercise,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Añadir ejercicio',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.onPrimary : AppColors.text)),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Selector de ejercicios
// ---------------------------------------------------------------------------

class _ExercisePicker extends StatefulWidget {
  final Set<String> alreadyAdded;
  final ValueChanged<Exercise> onPick;
  const _ExercisePicker({required this.alreadyAdded, required this.onPick});

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  late final Future<List<CatalogExercise>> _library =
      Get.find<ExerciseLibraryRepository>().getAll();
  static const _maxShown = 60;
  final _search = TextEditingController();
  String? _muscle;
  bool _custom = false;
  final _customName = TextEditingController();
  final _customMuscle = TextEditingController();
  final _customEquipment = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _customName.dispose();
    _customMuscle.dispose();
    _customEquipment.dispose();
    super.dispose();
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');

  /// Valores iniciales razonables al añadir desde el catálogo.
  Exercise _withDefaults(CatalogExercise c) => c.exercise.copyWith(
        targetSets: 3,
        targetReps: c.fixedReps ?? (c.compound ? '8-10' : '10-12'),
        restSeconds: c.compound ? 120 : 75,
      );

  @override
  Widget build(BuildContext context) {
    if (_custom) return _customForm();
    return FutureBuilder<List<CatalogExercise>>(
      future: _library,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        return _list(snap.data!);
      },
    );
  }

  Widget _list(List<CatalogExercise> all) {
    final muscles = <String>[];
    for (final c in all) {
      if (!muscles.contains(c.exercise.muscleGroup)) {
        muscles.add(c.exercise.muscleGroup);
      }
    }
    final q = _norm(_search.text.trim());
    final results = all.where((c) {
      final e = c.exercise;
      if (_muscle != null && e.muscleGroup != _muscle) return false;
      if (q.isEmpty) return true;
      return _norm('${e.name} ${e.muscleGroup} ${e.equipment}').contains(q);
    }).toList();
    final shown = results.take(_maxShown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: _search, label: 'Buscar entre ${all.length} ejercicios'),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final m in [null, ...muscles])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(m ?? 'Todos'),
                    selected: _muscle == m,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface2,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muscle == m
                            ? AppColors.onPrimary
                            : AppColors.text),
                    onSelected: (_) => setState(() => _muscle = m),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => setState(() => _custom = true),
          icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
          label: const Text('Crear ejercicio personalizado',
              style: TextStyle(color: AppColors.primary)),
        ),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Sin resultados. Puedes crearlo como personalizado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          ),
        for (final c in shown)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: GestureDetector(
              onTap: () => showExerciseHowTo(c.exercise, c.exercise.imageUrls),
              child: ExerciseThumb(urls: c.exercise.imageUrls, size: 48),
            ),
            title: Text(c.exercise.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text('${c.exercise.muscleGroup} · ${c.exercise.equipment}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            trailing: widget.alreadyAdded.contains(c.exercise.id)
                ? const Pill('Añadido')
                : const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primary),
            onTap: () => widget.onPick(_withDefaults(c)),
          ),
        if (results.length > shown.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Mostrando $_maxShown de ${results.length}. '
              'Escribe o filtra por músculo para encontrar más.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
      ],
    );
  }

  Widget _customForm() {
    return StatefulBuilder(
      builder: (context, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _customName,
            label: 'Nombre del ejercicio',
            capitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _customMuscle,
            label: 'Músculo principal (p. ej. Pecho)',
            capitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _customEquipment,
            label: 'Equipo (opcional)',
            capitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Añadir',
            onPressed: () {
              final name = _customName.text.trim();
              if (name.isEmpty) {
                showToast('Escribe el nombre del ejercicio.');
                return;
              }
              widget.onPick(Exercise(
                id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                muscleGroup: _customMuscle.text.trim().isEmpty
                    ? 'Otro'
                    : _customMuscle.text.trim(),
                equipment: _customEquipment.text.trim(),
                targetSets: 3,
                targetReps: '8-12',
                restSeconds: 90,
              ));
            },
          ),
          TextButton(
            onPressed: () => setState(() => _custom = false),
            child: const Text('Volver al catálogo',
                style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }
}

// ---------------------------------------------------------------------------
// Series, repeticiones y descanso
// ---------------------------------------------------------------------------

class _TargetsForm extends StatefulWidget {
  final Exercise exercise;
  final ValueChanged<Exercise> onSave;
  const _TargetsForm({required this.exercise, required this.onSave});

  @override
  State<_TargetsForm> createState() => _TargetsFormState();
}

class _TargetsFormState extends State<_TargetsForm> {
  late int _sets = widget.exercise.targetSets;
  late int _rest = widget.exercise.restSeconds;
  late final _reps = TextEditingController(text: widget.exercise.targetReps);

  static const _restOptions = [45, 60, 75, 90, 120, 150, 180];

  @override
  void dispose() {
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontSize: 13, color: AppColors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Series', style: label),
        const SizedBox(height: 8),
        Row(children: [
          _RoundButton(
              icon: Icons.remove_rounded,
              onTap: _sets > 1 ? () => setState(() => _sets--) : null),
          Expanded(
            child: Text('$_sets',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          ),
          _RoundButton(
              icon: Icons.add_rounded,
              onTap: _sets < 10 ? () => setState(() => _sets++) : null),
        ]),
        const SizedBox(height: 18),
        AppTextField(
          controller: _reps,
          label: 'Repeticiones (p. ej. 8-12, 10 o 30 s)',
          inputFormatters: [LengthLimitingTextInputFormatter(10)],
        ),
        const SizedBox(height: 18),
        const Text('Descanso entre series', style: label),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in _restOptions)
            ChoiceChip(
              label: Text(s < 60 || s % 60 != 0 ? '$s s' : '${s ~/ 60} min'),
              selected: _rest == s,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface2,
              side: BorderSide.none,
              labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _rest == s ? AppColors.onPrimary : AppColors.text),
              onSelected: (_) => setState(() => _rest = s),
            ),
        ]),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Listo',
          onPressed: () => widget.onSave(widget.exercise.copyWith(
            targetSets: _sets,
            targetReps:
                _reps.text.trim().isEmpty ? '8-12' : _reps.text.trim(),
            restSeconds: _rest,
          )),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon,
                color: onTap == null ? AppColors.muted : AppColors.primary),
          ),
        ),
      );
}
