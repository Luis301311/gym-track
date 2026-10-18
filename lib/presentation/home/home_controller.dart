import 'dart:async';

import 'package:get/get.dart';

import '../../domain/usecases/get_home_summary.dart';

class HomeController extends GetxController {
  final GetHomeSummary _getHomeSummary;
  final String userId;

  HomeController(this._getHomeSummary, {this.userId = 'demo-user'});

  final summary = Rxn<HomeSummary>();
  final error = RxnString();
  StreamSubscription<HomeSummary>? _sub;

  bool get isLoading => summary.value == null && error.value == null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    error.value = null;
    _sub?.cancel();
    _sub = _getHomeSummary(userId).listen(
      (s) => summary.value = s,
      onError: (Object e) => error.value = 'No se pudo cargar tu resumen: $e',
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
