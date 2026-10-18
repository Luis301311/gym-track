import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';

/// Componentes del diseño en Figma: StatCard, ExerciseRow, SectionTitle,
/// Button/Primary. Cada uno equivale a un componente de la librería.

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  /// Si se pasa, la tarjeta es tocable y muestra un "+" (p. ej. registrar peso).
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.accent = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: onTap == null
            ? null
            : Border.all(color: AppColors.soft(accent, 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Stack(children: [
          card,
          Positioned(
            top: 10,
            right: 10,
            child: Icon(Icons.add_circle_rounded, size: 18, color: accent),
          ),
        ]),
      ),
    );
  }
}

class ExerciseRow extends StatelessWidget {
  final String name;
  final String detail;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  /// Si hay fotos del ejercicio, se muestra la miniatura en vez del ícono.
  final List<String> imageUrls;

  const ExerciseRow({
    super.key,
    required this.name,
    required this.detail,
    this.icon = Icons.fitness_center_rounded,
    this.iconColor = AppColors.primary,
    this.onTap,
    this.imageUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (imageUrls.isNotEmpty)
                ExerciseThumb(urls: imageUrls, size: 44)
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor == AppColors.primary
                        ? AppColors.surface2
                        : AppColors.soft(iconColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool dark;
  final IconData? trailingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.dark = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.primary : AppColors.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: dark ? 48 : 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: dark ? AppColors.bg : AppColors.primary,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(dark ? 14 : 16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: dark ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: fg)),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 18, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Etiqueta pequeña con fondo tintado ("HOY", "+12%", "−1.6 kg").
class Pill extends StatelessWidget {
  final String text;
  final Color color;

  const Pill(this.text, {super.key, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.soft(color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

/// Aviso breve en la parte inferior.
void showToast(String message) {
  Get.closeAllSnackbars();
  Get.snackbar(
    'GymTrack',
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    colorText: AppColors.text,
    backgroundColor: AppColors.surface2,
    duration: const Duration(seconds: 2),
  );
}

/// Campo de texto con el estilo de la app.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization capitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.capitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: capitalization,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        autofillHints: autofillHints,
        autocorrect: !obscureText,
        enableSuggestions: !obscureText,
        cursorColor: AppColors.primary,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          suffixIcon: suffixIcon,
          labelStyle: const TextStyle(color: AppColors.muted),
          floatingLabelStyle: const TextStyle(color: AppColors.primary),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );
}

/// Logo de la app: mancuerna sobre círculo verde lima.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.fitness_center_rounded,
            size: size * 0.5, color: AppColors.onPrimary),
      );
}

/// Hoja inferior con formulario. El espacio del teclado se reserva FUERA del
/// panel: el panel sube completo sobre el teclado y su contenido hace scroll,
/// así el campo que estás escribiendo siempre queda a la vista.
class AppSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const AppSheet({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final maxHeight =
        (mq.size.height - keyboard - mq.padding.top - 24).clamp(160.0, double.infinity);
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          bottom: keyboard == 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre la hoja ocupando lo necesario (y subiendo con el teclado).
  ///
  /// En la versión web (PWA en el teléfono) el navegador mueve la pantalla al
  /// abrir el teclado y los paneles inferiores quedan tapados. Ahí se abre
  /// como pantalla completa, que maneja el teclado de forma confiable.
  /// `Get.back()` cierra cualquiera de las dos.
  static Future<T?> show<T>({required String title, required Widget child}) {
    if (kIsWeb) {
      return Get.to<T>(() => _FormPage(title: title, child: child),
          fullscreenDialog: true)!;
    }
    return Get.bottomSheet<T>(
      AppSheet(title: title, child: child),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/// Pantalla completa para formularios (usada en web por [AppSheet.show]).
class _FormPage extends StatelessWidget {
  final String title;
  final Widget child;
  const _FormPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Get.back<void>(),
          ),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: child,
          ),
        ),
      );
}

/// Miniatura de un ejercicio (primera foto). Si no hay foto o no carga
/// (p. ej. sin señal la primera vez), muestra el ícono de mancuerna.
class ExerciseThumb extends StatelessWidget {
  final List<String> urls;
  final double size;
  const ExerciseThumb({super.key, required this.urls, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.surface2,
      child: Icon(Icons.fitness_center_rounded,
          size: size * 0.5, color: AppColors.primary),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: urls.isEmpty
          ? fallback
          : Image.network(
              urls.first,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * dpr).round(),
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}

/// Hoja "Cómo se hace": posición inicial y final del ejercicio.
void showExerciseHowTo(Exercise e, List<String> urls) {
  Widget photo(String url, String label) => Expanded(
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.white,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: AppColors.muted),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      );

  AppSheet.show<void>(
    title: e.name,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [e.muscleGroup, if (e.equipment.isNotEmpty) e.equipment].join(' · '),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        if (urls.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Este ejercicio aún no tiene fotos.',
                  style: TextStyle(color: AppColors.muted)),
            ),
          )
        else
          Row(children: [
            photo(urls.first, 'Inicio'),
            if (urls.length > 1) ...[
              const SizedBox(width: 10),
              photo(urls[1], 'Final'),
            ],
          ]),
        const SizedBox(height: 14),
        if (urls.isNotEmpty)
          const Text('Fotos: free-exercise-db (dominio público).',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    ),
  );
}
