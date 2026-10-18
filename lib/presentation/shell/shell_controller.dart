import 'package:get/get.dart';

/// Pestaña seleccionada en la barra inferior.
class ShellController extends GetxController {
  static const home = 0, workout = 1, progress = 2, profile = 3;

  final index = 0.obs;

  void goTo(int tab) => index.value = tab;
}
