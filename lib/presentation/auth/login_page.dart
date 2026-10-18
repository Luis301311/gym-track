import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'auth_controller.dart';

/// Inicio de sesión y registro con correo y contraseña.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = Get.find<AuthController>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final error = _register
        ? await _auth.signUp(_name.text, _email.text, _password.text)
        : await _auth.signIn(_email.text, _password.text);
    // Si todo salió bien, AuthGate cambia de pantalla solo.
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _forgot() async {
    setState(() {
      _error = null;
      _info = null;
    });
    final error = await _auth.sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      if (error == null) {
        _info = 'Te enviamos un enlace a ${_email.text.trim()} para '
            'restablecer tu contraseña.';
      } else {
        _error = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 72)),
                    const SizedBox(height: 20),
                    const Text('GymTrack',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      _register
                          ? 'Crea tu cuenta y empieza a medir tu progreso'
                          : 'Entra para seguir con tu progreso',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 28),
                    _ModeSwitch(
                      register: _register,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() {
                                _register = v;
                                _error = null;
                                _info = null;
                              }),
                    ),
                    const SizedBox(height: 20),
                    if (_register) ...[
                      AppTextField(
                        controller: _name,
                        label: 'Nombre',
                        capitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                      ),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(
                      controller: _email,
                      label: 'Correo',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _password,
                      label: 'Contraseña',
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _busy ? null : _submit(),
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password
                      ],
                      suffixIcon: IconButton(
                        tooltip: _showPassword
                            ? 'Ocultar contraseña'
                            : 'Mostrar contraseña',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.muted,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    if (!_register)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _forgot,
                          child: const Text('¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.primary)),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    if (_error != null) _Message(_error!, color: AppColors.orange),
                    if (_info != null) _Message(_info!, color: AppColors.primary),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: _busy
                          ? 'Un momento…'
                          : (_register ? 'Crear cuenta' : 'Iniciar sesión'),
                      onPressed: _busy ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool register;
  final ValueChanged<bool>? onChanged;
  const _ModeSwitch({required this.register, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool value) {
      final selected = register == value;
      return Expanded(
        child: GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppColors.onPrimary : AppColors.muted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        tab('Iniciar sesión', false),
        tab('Crear cuenta', true),
      ]),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Color color;
  const _Message(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.soft(color, 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(fontSize: 13, color: color)),
      );
}
