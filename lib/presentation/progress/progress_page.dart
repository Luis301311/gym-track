import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/usecases/progress_summary.dart';
import '../../domain/utils/date_utils.dart';
import '../../domain/utils/format.dart';
import '../widgets/common_widgets.dart';
import 'charts.dart';
import 'progress_controller.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProgressController>();
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(children: [
              const Expanded(
                child: Text('Progreso',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              _RangeSelector(value: s.range, onChanged: c.setRange),
            ]),
            const SizedBox(height: 16),
            _WeightCard(summary: s, onAdd: () => _askWeight(c)),
            const SizedBox(height: 16),
            _VolumeCard(summary: s),
            const SizedBox(height: 20),
            _Records(records: s.records),
          ],
        );
      }),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final ProgressRange value;
  final ValueChanged<ProgressRange> onChanged;
  const _RangeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final r in ProgressRange.values)
          GestureDetector(
            onTap: () => onChanged(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: r == value ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(r.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          r == value ? AppColors.onPrimary : AppColors.muted)),
            ),
          ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: child,
      );
}

String _signed(double v, String unit, {int decimals = 1}) {
  final sign = v > 0 ? '+' : (v < 0 ? '−' : '');
  return '$sign${v.abs().toStringAsFixed(decimals)}$unit';
}

class _WeightCard extends StatelessWidget {
  final ProgressSummary summary;
  final VoidCallback onAdd;
  const _WeightCard({required this.summary, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final w = summary.weight;
    final points = w.points;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Peso corporal',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(w.current == null ? '—' : formatKg(w.current!),
                            style: const TextStyle(
                                fontSize: 30, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Text('kg',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (w.change != null)
                    Pill('${_signed(w.change!, ' kg')} ${summary.range.periodName}'),
                  const SizedBox(height: 8),
                  _SmallButton(
                      icon: Icons.add_rounded, label: 'Registrar', onTap: onAdd),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (points.length < 2)
            Container(
              height: 110,
              alignment: Alignment.center,
              child: Text(
                points.isEmpty
                    ? 'Sin registros ${summary.range.periodName}.\nRegistra tu peso para ver la tendencia.'
                    : 'Registra tu peso al menos 2 veces para ver la tendencia.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            )
          else ...[
            LineChart(values: [for (final p in points) p.kg]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final p in [
                  points.first,
                  points[points.length ~/ 2],
                  points.last
                ])
                  Text('${p.date.day}/${p.date.month}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ]),
          ),
        ),
      );
}

class _VolumeCard extends StatelessWidget {
  final ProgressSummary summary;
  const _VolumeCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final v = summary.volume;
    final pct = v.changePct;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${formatVolume(v.total)} · ${summary.sessionsInRange} '
                    '${summary.sessionsInRange == 1 ? 'entreno' : 'entrenos'}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (pct != null)
              Pill(_signed(pct, '%', decimals: 0),
                  color: pct >= 0 ? AppColors.primary : AppColors.orange),
          ]),
          const SizedBox(height: 16),
          BarChart(bars: v.bars),
        ],
      ),
    );
  }
}

class _Records extends StatelessWidget {
  final List<RecordEntry> records;
  const _Records({required this.records});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final shown = records.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Récords personales',
          action: records.length > shown.length ? 'Ver todos' : null,
          onAction: () => _showAllRecords(records),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          const Text('Aún no tienes récords. ¡Completa tu primer entrenamiento!',
              style: TextStyle(color: AppColors.muted))
        else
          for (final r in shown) ...[
            _RecordRow(record: r, now: now),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final RecordEntry record;
  final DateTime now;
  const _RecordRow({required this.record, required this.now});

  @override
  Widget build(BuildContext context) => ExerciseRow(
        name: record.exercise.name,
        detail: 'Récord: ${formatKg(record.set.weightKg)} kg × ${record.set.reps}'
            ' · ${formatRelativeDay(record.date, now)}',
        icon: Icons.emoji_events_rounded,
        iconColor: AppColors.orange,
      );
}

void _showAllRecords(List<RecordEntry> records) {
  final now = DateTime.now();
  Get.bottomSheet(
    Container(
      constraints: BoxConstraints(maxHeight: Get.height * 0.75),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
            const Text('Todos tus récords',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: records.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _RecordRow(record: records[i], now: now),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

Future<void> _askWeight(ProgressController c) async {
  final ctrl = TextEditingController(
    text: c.summary.value?.weight.current == null
        ? ''
        : formatKg(c.summary.value!.weight.current!),
  );
  final error = RxnString();
  final saving = false.obs;

  Future<void> save() async {
    saving.value = true;
    final msg = await c.addWeight(ctrl.text);
    saving.value = false;
    if (msg == null) {
      Get.back();
    } else {
      error.value = msg;
    }
  }

  await Get.dialog<void>(
    AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: const Text('Registrar peso',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Obx(() => TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onSubmitted: (_) => save(),
            cursorColor: AppColors.primary,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              suffixText: 'kg',
              errorText: error.value,
              errorMaxLines: 2,
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          )),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.muted)),
        ),
        Obx(() => TextButton(
              onPressed: saving.value ? null : save,
              child: const Text('Guardar',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            )),
      ],
    ),
  );
  // El controlador del texto no se libera aquí: el diálogo todavía lo usa
  // durante la animación de cierre.
}
