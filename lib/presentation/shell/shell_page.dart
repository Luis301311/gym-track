import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_page.dart';
import '../progress/progress_page.dart';
import '../workout/workout_controller.dart';
import '../workout/workout_page.dart';
import 'shell_controller.dart';

class _Tab {
  final String label;
  final IconData icon;
  final Widget page;
  const _Tab(this.label, this.icon, this.page);
}

/// Contenedor con la BottomNav del diseño. Cada pestaña es independiente,
/// así que agregar una nueva no toca las demás.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  static const _tabs = [
    _Tab('Inicio', Icons.home_outlined, HomePage()),
    _Tab('Entrenar', Icons.fitness_center_rounded, WorkoutPage()),
    _Tab('Progreso', Icons.show_chart_rounded, ProgressPage()),
    _Tab('Perfil', Icons.person_outline_rounded, _ComingSoon('Perfil')),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ShellController>();
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: c.index.value,
          children: [for (final t in _tabs) t.page],
        ),
        bottomNavigationBar: _BottomNav(
          tabs: _tabs,
          current: c.index.value,
          onTap: c.goTo,
          // Punto verde en "Entrenar" mientras hay una sesión en curso.
          badgeIndex: Get.find<WorkoutController>().isActive
              ? ShellController.workout
              : null,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<_Tab> tabs;
  final int current;
  final ValueChanged<int> onTap;
  final int? badgeIndex;

  const _BottomNav({
    required this.tabs,
    required this.current,
    required this.onTap,
    this.badgeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surface2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: InkResponse(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          isLabelVisible: i == badgeIndex,
                          smallSize: 8,
                          backgroundColor: AppColors.primary,
                          child: Icon(tabs[i].icon,
                              size: 24,
                              color: i == current
                                  ? AppColors.primary
                                  : AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: i == current
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon(this.title);

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Próximamente',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
}
