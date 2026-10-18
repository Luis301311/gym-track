import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Deja lista una cuenta: si es nueva guarda su perfil y, si se configuraron
/// rutinas de inicio y no tiene ninguna, se las crea. Por defecto NO crea
/// rutinas: la persona arma la suya o pide una recomendación.
/// Se ejecuta en cada inicio de sesión; si la cuenta ya tiene datos, no cambia nada.
class EnsureStarterData {
  final RoutineRepository routines;
  final RoutineWriteRepository routineWriter;
  final ProfileWriteRepository profileWriter;
  final List<Routine> starter;

  EnsureStarterData({
    required this.routines,
    required this.routineWriter,
    required this.profileWriter,
    this.starter = const [],
  });

  /// [newAccountName] solo se pasa justo después de registrarse.
  Future<void> call(String userId, {String? newAccountName}) async {
    if (newAccountName != null) {
      await profileWriter.saveProfile(UserProfile(
        id: userId,
        name: newAccountName,
        goal: '',
        weeklyGoal: 4,
      ));
    }
    if (starter.isEmpty) return;
    final existing = await routines.getRoutines(userId);
    if (existing.isNotEmpty) return;
    for (final r in starter) {
      await routineWriter.saveRoutine(userId, r);
    }
  }
}
