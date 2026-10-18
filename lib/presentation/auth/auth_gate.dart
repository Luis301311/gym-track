import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../shell/session_binding.dart';
import '../shell/shell_page.dart';
import '../widgets/common_widgets.dart';
import 'auth_controller.dart';
import 'login_page.dart';

/// Decide qué mostrar según la sesión: carga, login o la app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final Widget child = switch (auth.status.value) {
        AuthStatus.unknown => const _Splash(),
        AuthStatus.preparing => const _Splash(message: 'Preparando tu cuenta…'),
        AuthStatus.signedOut => const LoginPage(),
        AuthStatus.signedIn => _SessionScope(
            key: ValueKey(auth.user.value!.uid),
            userId: auth.user.value!.uid,
          ),
      };
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: child,
      );
    });
  }
}

/// Crea los controladores de la sesión al montarse y los destruye al
/// desmontarse (cierre de sesión), siguiendo el ciclo de vida del widget.
class _SessionScope extends StatefulWidget {
  final String userId;
  const _SessionScope({super.key, required this.userId});

  @override
  State<_SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<_SessionScope> {
  @override
  void initState() {
    super.initState();
    SessionBinding(widget.userId).dependencies();
  }

  @override
  void dispose() {
    SessionBinding.dispose(widget.userId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ShellPage();
}

class _Splash extends StatelessWidget {
  final String? message;
  const _Splash({this.message});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const AppLogo(size: 72),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(message!,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ]),
        ),
      );
}
