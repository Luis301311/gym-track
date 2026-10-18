/// "70" o "72.5" (sin ceros sobrantes).
String formatKg(double kg) =>
    kg % 1 == 0 ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

/// "70 × 8" o "PC × 12" cuando es peso corporal.
String formatSet(double kg, int reps) =>
    '${kg == 0 ? 'PC' : formatKg(kg)} × $reps';

/// "05:07" o "1:05:07" si pasa de una hora.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Acepta "72,5" o "72.5".
double? parseDecimal(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.'));

/// "8.4 t" o "850 kg".
String formatVolume(double kg) =>
    kg >= 1000 ? '${(kg / 1000).toStringAsFixed(1)} t' : '${kg.toStringAsFixed(0)} kg';
