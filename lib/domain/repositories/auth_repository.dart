/// Usuario autenticado, sin depender de Firebase.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;

  const AuthUser({required this.uid, this.email, this.displayName});
}

/// Error de autenticación con un mensaje listo para mostrar.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Contrato de autenticación. Hoy lo implementa Firebase Auth; mañana podría
/// ser tu propio backend (JWT) sin tocar pantallas ni controladores.
abstract class AuthRepository {
  /// Emite el usuario actual y cada cambio (inicio/cierre de sesión).
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
