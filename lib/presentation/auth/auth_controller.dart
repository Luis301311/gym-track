import 'dart:async';

import 'package:get/get.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/account_usecases.dart';

enum AuthStatus { unknown, signedOut, preparing, signedIn }

/// Escucha el estado de autenticación y prepara la cuenta al entrar.
/// Solo conoce el contrato [AuthRepository], no Firebase.
class AuthController extends GetxController {
  final AuthRepository auth;
  final EnsureStarterData ensureStarterData;

  AuthController({required this.auth, required this.ensureStarterData});

  final status = AuthStatus.unknown.obs;
  final user = Rxn<AuthUser>();

  /// Aviso no bloqueante si no se pudo preparar la cuenta (p. ej. sin señal).
  final setupWarning = RxnString();

  String? _pendingName;
  String? _preparedUid;
  StreamSubscription<AuthUser?>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = auth.authStateChanges().listen(_onUser);
  }

  Future<void> _onUser(AuthUser? u) async {
    if (u == null) {
      _preparedUid = null;
      user.value = null;
      status.value = AuthStatus.signedOut;
      return;
    }
    if (u.uid == _preparedUid) return; // mismo usuario, nada que hacer

    user.value = u;
    status.value = AuthStatus.preparing;
    setupWarning.value = null;
    try {
      await ensureStarterData(u.uid, newAccountName: _pendingName);
    } catch (e) {
      // No se bloquea la entrada: se reintenta en el próximo inicio de sesión.
      setupWarning.value = 'No se pudo preparar tu cuenta por completo: $e';
    }
    _pendingName = null;
    _preparedUid = u.uid;
    status.value = AuthStatus.signedIn;
  }

  // --- Acciones. Devuelven un mensaje de error para mostrar, o null.

  Future<String?> signIn(String email, String password) async {
    final invalid = _validate(email: email, password: password);
    if (invalid != null) return invalid;
    return _run(() => auth.signIn(email: email, password: password));
  }

  Future<String?> signUp(String name, String email, String password) async {
    if (name.trim().isEmpty) return 'Escribe tu nombre.';
    final invalid = _validate(email: email, password: password);
    if (invalid != null) return invalid;
    // Se guarda antes: Firebase avisa del nuevo usuario apenas se crea.
    _pendingName = name.trim();
    final error = await _run(
        () => auth.signUp(name: name, email: email, password: password));
    if (error != null) _pendingName = null;
    return error;
  }

  Future<String?> sendPasswordReset(String email) async {
    if (!_looksLikeEmail(email)) {
      return 'Escribe tu correo arriba para enviarte el enlace.';
    }
    return _run(() => auth.sendPasswordReset(email));
  }

  Future<void> signOut() => auth.signOut();

  String? _validate({required String email, required String password}) {
    if (!_looksLikeEmail(email)) return 'Escribe un correo válido.';
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  bool _looksLikeEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  Future<String?> _run(Future<Object?> Function() action) async {
    try {
      await action();
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    } catch (e) {
      return 'Algo salió mal: $e';
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
