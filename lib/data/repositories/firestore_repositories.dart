import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../mappers/mappers.dart';

/// Implementaciones con Cloud Firestore.
///
/// Estructura (plana y con IDs explícitos, fácil de llevar a tablas SQL):
///   users/{uid}                  -> perfil
///   users/{uid}/routines/{id}    -> rutinas
///   users/{uid}/sessions/{id}    -> entrenamientos con sus series
///   users/{uid}/body_weights/{id} -> registros de peso corporal
///   users/{uid}/measurements/{id} -> medidas corporales (pecho, brazo…)

DateTime? _readTimestamp(Object? raw) =>
    raw is Timestamp ? raw.toDate() : null;
Object? _writeTimestamp(DateTime? d) =>
    d == null ? null : Timestamp.fromDate(d);

class FirestoreWorkoutRepository implements WorkoutRepository {
  final FirebaseFirestore _db;
  FirestoreWorkoutRepository(this._db);

  CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  @override
  Stream<List<WorkoutSession>> watchSessions(String userId) => _sessions(userId)
      .orderBy('startedAt', descending: true)
      .limit(200)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              sessionFromMap(d.id, d.data(), _readTimestamp),
          ]);

  @override
  Future<void> saveSession(String userId, WorkoutSession session) {
    final ref = session.id.isEmpty
        ? _sessions(userId).doc()
        : _sessions(userId).doc(session.id);
    return ref.set(sessionToMap(session, _writeTimestamp));
  }
}

class FirestoreRoutineRepository implements RoutineRepository {
  final FirebaseFirestore _db;
  FirestoreRoutineRepository(this._db);

  @override
  Future<List<Routine>> getRoutines(String userId) async {
    final snap =
        await _db.collection('users').doc(userId).collection('routines').get();
    return [for (final d in snap.docs) routineFromMap(d.id, d.data())];
  }
}

class FirestoreProfileRepository
    implements ProfileRepository, ProfileWriteRepository {
  final FirebaseFirestore _db;
  FirestoreProfileRepository(this._db);

  @override
  Future<void> saveProfile(UserProfile profile) => _db
      .collection('users')
      .doc(profile.id)
      .set(profileToMap(profile), SetOptions(merge: true));

  @override
  Future<UserProfile> getProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return profileFromMap(userId, doc.data() ?? const {});
  }
}

class FirestoreBodyMetricsRepository implements BodyMetricsRepository {
  final FirebaseFirestore _db;
  FirestoreBodyMetricsRepository(this._db);

  CollectionReference<Map<String, dynamic>> _weights(String uid) =>
      _db.collection('users').doc(uid).collection('body_weights');

  @override
  Stream<List<BodyWeightEntry>> watchWeights(String userId) => _weights(userId)
      .orderBy('date', descending: true)
      .limit(400)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              weightFromMap(d.id, d.data(), _readTimestamp),
          ]);

  @override
  Future<void> addWeight(String userId, BodyWeightEntry entry) {
    final ref = entry.id.isEmpty
        ? _weights(userId).doc()
        : _weights(userId).doc(entry.id);
    return ref.set(weightToMap(entry, _writeTimestamp));
  }
}

class FirestoreMeasurementsRepository implements MeasurementsRepository {
  final FirebaseFirestore _db;
  FirestoreMeasurementsRepository(this._db);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('measurements');

  @override
  Stream<List<BodyMeasurement>> watchMeasurements(String userId) => _col(userId)
      .orderBy('date', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              measurementFromMap(d.id, d.data(), _readTimestamp),
          ]);

  @override
  Future<void> addMeasurement(String userId, BodyMeasurement m) {
    final ref = m.id.isEmpty ? _col(userId).doc() : _col(userId).doc(m.id);
    return ref.set(measurementToMap(m, _writeTimestamp));
  }
}
