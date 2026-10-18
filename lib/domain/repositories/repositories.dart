import '../entities/entities.dart';

/// Contratos de acceso a datos.
///
/// OPEN/CLOSED: la UI y los casos de uso dependen SOLO de estas abstracciones.
/// Para cambiar de Firebase a una API propia (NestJS, etc.) se crea una clase
/// nueva que implemente estos contratos y se registra en
/// `core/di/dependency_injection.dart`. Nada más se modifica.

abstract class WorkoutRepository {
  Stream<List<WorkoutSession>> watchSessions(String userId);
  Future<void> saveSession(String userId, WorkoutSession session);
}

abstract class RoutineRepository {
  Future<List<Routine>> getRoutines(String userId);
}

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String userId);
}

/// Contrato NUEVO para medidas corporales. Agregar una capacidad = agregar un
/// contrato; los que ya existían (y sus implementaciones) no se tocan.
abstract class BodyMetricsRepository {
  Stream<List<BodyWeightEntry>> watchWeights(String userId);
  Future<void> addWeight(String userId, BodyWeightEntry entry);
}

/// Escritura del perfil, separada de la lectura (ProfileRepository): quien
/// solo lee el perfil, como Inicio, no depende de algo que no usa.
abstract class ProfileWriteRepository {
  Future<void> saveProfile(UserProfile profile);
}

abstract class MeasurementsRepository {
  Stream<List<BodyMeasurement>> watchMeasurements(String userId);
  Future<void> addMeasurement(String userId, BodyMeasurement measurement);
}
