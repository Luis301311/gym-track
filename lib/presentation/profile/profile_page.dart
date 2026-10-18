import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/profile_summary.dart';
import '../../domain/utils/date_utils.dart';
import '../../domain/utils/format.dart';
import '../auth/auth_controller.dart';
import '../progress/progress_page.dart';
import '../routines/routines_page.dart';
import '../widgets/common_widgets.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        if (c.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.error.value!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Reintentar', onPressed: c.load),
              ]),
            ),
          );
        }
        final s = c.summary.value;
        if (s == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Editar perfil',
                icon: const Icon(Icons.edit_outlined, color: AppColors.muted),
                onPressed: () => _editProfile(c, s.profile),
              ),
            ),
            _Identity(profile: s.profile),
            const SizedBox(height: 20),
            _Stats(summary: s),
            const SizedBox(height: 24),
            SectionTitle(
              'Medidas corporales',
              action: 'Actualizar',
              onAction: () => _addMeasurement(c, s),
            ),
            const SizedBox(height: 10),
            _Measurements(summary: s),
            const SizedBox(height: 18),
            _Settings(c: c),
          ],
        );
      }),
    );
  }
}

class _Identity extends StatelessWidget {
  final UserProfile profile;
  const _Identity({required this.profile});

  @override
  Widget build(BuildContext context) {
    final email = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().user.value?.email
        : null;
    return Column(children: [
      Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        child: Text(profile.initials,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary)),
      ),
      const SizedBox(height: 12),
      Text(profile.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      if (profile.goal.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text('Objetivo: ${profile.goal}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      ],
      if (email != null) ...[
        const SizedBox(height: 2),
        Text(email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    ]);
  }
}

class _Stats extends StatelessWidget {
  final ProfileSummary summary;
  const _Stats({required this.summary});

  @override
  Widget build(BuildContext context) {
    final w = summary.currentWeightKg;
    final h = summary.profile.heightCm;
    return Row(children: [
      Expanded(
        child: StatCard(
          value: w == null ? '—' : '${formatKg(w)} kg',
          label: w == null ? 'Registrar peso' : 'Peso',
          onTap: showRegisterWeight,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatCard(
            value: h == null ? '—' : '${(h / 100).toStringAsFixed(2)} m',
            label: 'Altura',
            accent: AppColors.blue),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatCard(
            value: '${summary.totalWorkouts}',
            label: 'Entrenos',
            accent: AppColors.orange),
      ),
    ]);
  }
}

class _Measurements extends StatelessWidget {
  final ProfileSummary summary;
  const _Measurements({required this.summary});

  @override
  Widget build(BuildContext context) {
    final list = summary.measurements;
    final last = summary.lastMeasuredAt;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: list.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                  'Aún no registras medidas. Toca "Actualizar" para empezar.',
                  style: TextStyle(color: AppColors.muted)),
            )
          : Column(children: [
              for (var i = 0; i < list.length; i++)
                _MeasurementRow(stat: list[i], divider: i < list.length - 1),
              if (last != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Última medición: ${formatRelativeDay(last, DateTime.now())}',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                ),
            ]),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final MeasurementStat stat;
  final bool divider;
  const _MeasurementRow({required this.stat, required this.divider});

  @override
  Widget build(BuildContext context) {
    final d = stat.deltaCm;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.surface2))
            : null,
      ),
      child: Row(children: [
        Expanded(
          child: Text(stat.type.label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        Text('${formatKg(stat.valueCm)} cm',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        if (d != null && d != 0) ...[
          const SizedBox(width: 10),
          Pill(
            '${d > 0 ? '+' : '−'}${d.abs().toStringAsFixed(1)}',
            // Verde si mejora, naranja si empeora, azul si depende del objetivo.
            color: stat.improved
                ? AppColors.primary
                : stat.worsened
                    ? AppColors.orange
                    : AppColors.blue,
          ),
        ],
      ]),
    );
  }
}

class _Settings extends StatelessWidget {
  final ProfileController c;
  const _Settings({required this.c});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.format_list_bulleted_rounded, 'Mis rutinas', AppColors.text,
          () => Get.to<void>(() => const RoutinesPage())),
      (Icons.notifications_none_rounded, 'Recordatorios', AppColors.text,
          () => showToast('Los recordatorios llegan en una próxima versión.')),
      (Icons.logout_rounded, 'Cerrar sesión', AppColors.orange,
          () => _confirmSignOut()),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        for (var i = 0; i < items.length; i++)
          Container(
            decoration: BoxDecoration(
              border: i < items.length - 1
                  ? const Border(bottom: BorderSide(color: AppColors.surface2))
                  : null,
            ),
            child: ListTile(
              leading: Icon(items[i].$1, size: 20, color: items[i].$3),
              title: Text(items[i].$2,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: items[i].$3)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.muted),
              onTap: items[i].$4,
            ),
          ),
      ]),
    );
  }
}

// ============================================================================
// Hojas y diálogos
// ============================================================================

Widget _errorText(RxnString error) => Obx(() => error.value == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(error.value!,
            style: const TextStyle(color: AppColors.orange, fontSize: 13)),
      ));

final _decimalOnly = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  LengthLimitingTextInputFormatter(6),
];

void _editProfile(ProfileController c, UserProfile p) {
  final name = TextEditingController(text: p.name);
  final goal = TextEditingController(text: p.goal);
  final height = TextEditingController(
      text: p.heightCm == null ? '' : formatKg(p.heightCm!));
  final weekly = p.weeklyGoal.obs;
  final sex = p.sex.obs;
  final error = RxnString();
  final saving = false.obs;

  AppSheet.show(
      title: 'Editar perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
              controller: name,
              label: 'Nombre',
              capitalization: TextCapitalization.words),
          const SizedBox(height: 12),
          AppTextField(
              controller: goal,
              label: 'Objetivo',
              capitalization: TextCapitalization.sentences),
          const SizedBox(height: 12),
          AppTextField(
            controller: height,
            label: 'Altura',
            suffix: 'cm',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _decimalOnly,
          ),
          const SizedBox(height: 18),
          const Text('Sexo',
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 8),
          Obx(() => Wrap(spacing: 8, runSpacing: 8, children: [
                for (final option in Sex.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: sex.value == option,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface2,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sex.value == option
                            ? AppColors.onPrimary
                            : AppColors.text),
                    onSelected: (_) => sex.value = option,
                  ),
              ])),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
                'Solo se usa para sugerir el enfoque y los descansos de tus rutinas.',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
          const SizedBox(height: 18),
          const Text('Meta de entrenos por semana',
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 8),
          Obx(() => Row(children: [
                for (var n = 1; n <= 7; n++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: weekly.value == n
                            ? AppColors.primary
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => weekly.value = n,
                          child: SizedBox(
                            height: 40,
                            child: Center(
                              child: Text('$n',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: weekly.value == n
                                          ? AppColors.onPrimary
                                          : AppColors.text)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ])),
          _errorText(error),
          const SizedBox(height: 20),
          Obx(() => PrimaryButton(
                label: saving.value ? 'Guardando…' : 'Guardar',
                onPressed: saving.value
                    ? null
                    : () async {
                        saving.value = true;
                        final msg = await c.saveProfile(
                          name: name.text,
                          goal: goal.text,
                          heightCm: height.text,
                          weeklyGoal: weekly.value,
                          sex: sex.value,
                        );
                        saving.value = false;
                        if (msg == null) {
                          Get.back();
                          showToast('Perfil actualizado.');
                        } else {
                          error.value = msg;
                        }
                      },
              )),
        ],
      ),
  );
}

void _addMeasurement(ProfileController c, ProfileSummary s) {
  final latest = s.latestValues;
  final ctrls = {
    for (final t in kMeasurementTypes)
      t.key: TextEditingController(
          text: latest[t.key] == null ? '' : formatKg(latest[t.key]!)),
  };
  final error = RxnString();
  final saving = false.obs;

  AppSheet.show(
      title: 'Actualizar medidas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Mide en la mañana y en el mismo punto cada vez. Deja vacío lo que no midas hoy.',
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),
          for (final t in kMeasurementTypes) ...[
            AppTextField(
              controller: ctrls[t.key]!,
              label: t.label,
              suffix: 'cm',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: _decimalOnly,
            ),
            const SizedBox(height: 12),
          ],
          _errorText(error),
          const SizedBox(height: 8),
          Obx(() => PrimaryButton(
                label: saving.value ? 'Guardando…' : 'Guardar medidas',
                onPressed: saving.value
                    ? null
                    : () async {
                        saving.value = true;
                        final msg = await c.addMeasurement(
                            {for (final e in ctrls.entries) e.key: e.value.text});
                        saving.value = false;
                        if (msg == null) {
                          Get.back();
                          showToast('Medidas guardadas.');
                        } else {
                          error.value = msg;
                        }
                      },
              )),
        ],
      ),
  );
}

Future<void> _confirmSignOut() async {
  final ok = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: const Text('¿Cerrar sesión?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: const Text(
          'Tus datos quedan guardados en tu cuenta. Si tienes un entrenamiento '
          'en curso sin terminar, se descartará.',
          style: TextStyle(color: AppColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child:
              const Text('Cancelar', style: TextStyle(color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Cerrar sesión',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.orange)),
        ),
      ],
    ),
  );
  if (ok == true) await Get.find<AuthController>().signOut();
}
