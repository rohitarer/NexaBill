import 'package:flutter/material.dart';

class BillNavigationHandler {
  static void popIfMounted(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
        debugPrint("🚪 BillNavigationHandler → Navigator.pop() success.");
      } else {
        debugPrint("❗ BillNavigationHandler → Can't pop, context unmounted.");
      }
    });
  }
}
