import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/usecases/progress_summary.dart';

/// Línea suave con área rellena (peso corporal). Sin librerías externas.
class LineChart extends StatelessWidget {
  final List<double> values;
  final double height;

  const LineChart({super.key, required this.values, this.height = 110});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _LinePainter(values)),
      );
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  _LinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const padTop = 8.0, padBottom = 6.0, dot = 4.5;
    var minV = values.reduce(math.min), maxV = values.reduce(math.max);
    if (maxV - minV < 1) {
      // Evita que un cambio mínimo se vea exagerado.
      final mid = (maxV + minV) / 2;
      minV = mid - 0.5;
      maxV = mid + 0.5;
    }
    final h = size.height - padTop - padBottom;
    final w = size.width - dot * 2;

    Offset point(int i) {
      final x = values.length == 1 ? size.width / 2 : dot + w * i / (values.length - 1);
      final y = padTop + h * (1 - (values[i] - minV) / (maxV - minV));
      return Offset(x, y);
    }

    final pts = [for (var i = 0; i < values.length; i++) point(i)];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1], p1 = pts[i];
      final cx = (p0.dx + p1.dx) / 2;
      line.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.soft(AppColors.primary, 0.25),
            AppColors.soft(AppColors.primary, 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(pts.last, dot, Paint()..color = AppColors.primary);
    canvas.drawCircle(pts.last, dot + 4, Paint()..color = AppColors.soft(AppColors.primary, 0.2));
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values;
}

/// Barras verticales con etiqueta (volumen por día/semana/mes).
class BarChart extends StatelessWidget {
  final List<ChartBar> bars;
  final double height;

  const BarChart({super.key, required this.bars, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final maxV = bars.fold<double>(0, (m, b) => math.max(m, b.value));
    final narrow = bars.length > 7;
    return SizedBox(
      height: height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final b in bars)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: narrow ? 3 : 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: b.value == 0
                          ? 'Sin entrenar'
                          : '${(b.value / 1000).toStringAsFixed(1)} t',
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            end: maxV == 0
                                ? 6
                                : math.max(6, height * b.value / maxV)),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (_, h, __) => Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: b.value == 0
                                ? AppColors.surface2
                                : b.isCurrent
                                    ? AppColors.primary
                                    : AppColors.soft(AppColors.primary, 0.5),
                            borderRadius: BorderRadius.circular(narrow ? 5 : 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: b.isCurrent ? AppColors.primary : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
