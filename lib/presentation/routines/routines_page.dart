import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/utils/date_utils.dart';
import '../widgets/common_widgets.dart';
import 'recommend_page.dart';
import 'routine_editor_page.dart';
import 'routines_controller.dart';

AppBar gymAppBar(String title, {List<Widget>? actions}) => AppBar(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      actions: actions,
    );

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RoutinesController>();
    return Scaffold(
      appBar: gymAppBar('Mis rutinas'),
      body: Obx(() {
        if (c.loading.value && c.list.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Row(children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Recomiéndame',
                  subtitle: 'Un plan según tu objetivo',
                  highlighted: true,
                  onTap: () => Get.to<void>(() => const RecommendPage()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_rounded,
                  title: 'Crear rutina',
                  subtitle: 'Ármala a tu gusto',
                  onTap: () => Get.to<void>(() => const RoutineEditorPage()),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            if (c.error.value != null)
              Text(c.error.value!,
                  style: const TextStyle(color: AppColors.orange)),
            if (c.list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Aún no tienes rutinas. Pide una recomendación o crea la tuya.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else ...[
              Text('${c.list.length} '
                  '${c.list.length == 1 ? 'rutina' : 'rutinas'}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 10),
              for (final r in c.list) ...[
                _RoutineTile(
                  routine: r,
                  onTap: () =>
                      Get.to<void>(() => RoutineEditorPage(routine: r)),
                  onDelete: () => _confirmDelete(c, r),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        );
      }),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? AppColors.onPrimary : AppColors.text;
    return Material(
      color: highlighted ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: highlighted ? AppColors.onPrimary : AppColors.primary),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: highlighted
                          ? AppColors.onPrimary.withValues(alpha: 0.7)
                          : AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _RoutineTile(
      {required this.routine, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final r = routine;
    final days = r.weekdays.isEmpty ? 'Sin día fijo' : formatWeekdays(r.weekdays);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(r.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Pill(days),
                  ]),
                  if (r.focus.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(r.focus, style: const TextStyle(fontSize: 13)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${r.exercises.length} ejercicios · ~${r.estimatedMinutes} min',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar rutina',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.muted),
              onPressed: onDelete,
            ),
          ]),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(RoutinesController c, Routine r) async {
  final ok = await Get.dialog<bool>(AlertDialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg)),
    title: Text('¿Eliminar "${r.name}"?',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    content: const Text(
        'Tu historial de entrenamientos se conserva; solo se borra la rutina.',
        style: TextStyle(color: AppColors.muted)),
    actions: [
      TextButton(
        onPressed: () => Get.back(result: false),
        child: const Text('Cancelar', style: TextStyle(color: AppColors.muted)),
      ),
      TextButton(
        onPressed: () => Get.back(result: true),
        child: const Text('Eliminar',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.orange)),
      ),
    ],
  ));
  if (ok != true) return;
  final msg = await c.delete(r.id);
  showToast(msg ?? 'Rutina eliminada.');
}
