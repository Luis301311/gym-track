import '../entities/entities.dart';

class MeasurementStat {
  final MeasurementType type;
  final double valueCm;

  /// Cambio contra el registro anterior de esta misma medida.
  final double? deltaCm;

  const MeasurementStat(this.type, this.valueCm, this.deltaCm);

  /// El cambio va en la dirección buena para esta medida.
  bool get improved {
    final d = deltaCm;
    if (d == null || d == 0 || type.neutral) return false;
    return type.higherIsBetter ? d > 0 : d < 0;
  }

  /// El cambio va en la dirección contraria a la buena.
  bool get worsened {
    final d = deltaCm;
    if (d == null || d == 0 || type.neutral) return false;
    return !improved;
  }
}

class ProfileSummary {
  final UserProfile profile;
  final double? currentWeightKg;
  final int totalWorkouts;
  final List<MeasurementStat> measurements;
  final DateTime? lastMeasuredAt;

  const ProfileSummary({
    required this.profile,
    required this.currentWeightKg,
    required this.totalWorkouts,
    required this.measurements,
    required this.lastMeasuredAt,
  });

  /// Último valor registrado de cada medida, para prellenar el formulario.
  Map<String, double> get latestValues =>
      {for (final m in measurements) m.type.key: m.valueCm};
}

/// Función pura que arma lo que muestra Perfil.
ProfileSummary buildProfileSummary({
  required UserProfile profile,
  required List<WorkoutSession> sessions,
  required List<BodyWeightEntry> weights,
  required List<BodyMeasurement> measurements,
  List<MeasurementType> types = kMeasurementTypes,
}) {
  final sortedWeights = [...weights]..sort((a, b) => b.date.compareTo(a.date));
  final sortedMeasures = [...measurements]
    ..sort((a, b) => b.date.compareTo(a.date));

  final stats = <MeasurementStat>[];
  for (final t in types) {
    final values = [
      for (final m in sortedMeasures)
        if (m.valuesCm[t.key] != null) m.valuesCm[t.key]!,
    ];
    if (values.isEmpty) continue;
    stats.add(MeasurementStat(
      t,
      values.first,
      values.length > 1 ? values[0] - values[1] : null,
    ));
  }

  return ProfileSummary(
    profile: profile,
    currentWeightKg: sortedWeights.isEmpty ? null : sortedWeights.first.kg,
    totalWorkouts: sessions.length,
    measurements: stats,
    lastMeasuredAt: sortedMeasures.isEmpty ? null : sortedMeasures.first.date,
  );
}
