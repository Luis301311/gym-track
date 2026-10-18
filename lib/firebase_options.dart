// Archivo provisional. Ejecuta `flutterfire configure` para reemplazarlo con
// la configuración real de tu proyecto de Firebase.
// Solo se usa al correr con --dart-define=BACKEND=firebase.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase no está configurado. Ejecuta `flutterfire configure`.',
      );
}
