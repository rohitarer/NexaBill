import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main provider to store cashier and counterNo info
final billCashierProvider =
    StateNotifierProvider<BillCashierNotifier, Map<String, String>>(
      (ref) => BillCashierNotifier(ref),
    );

/// Refresh trigger provider (to manually force UI rebuilds if needed)
final billCashierRefreshProvider = StateProvider<bool>((ref) => false);

class BillCashierNotifier extends StateNotifier<Map<String, String>> {
  final Ref ref;

  BillCashierNotifier(this.ref) : super({"cashier": "", "counterNo": ""});

  void update(String cashier, String counterNo) {
    state = {"cashier": cashier, "counterNo": counterNo};

    // 🔄 Optionally toggle refresh state to trigger dependent widgets
    final refreshState = ref.read(billCashierRefreshProvider);
    ref.read(billCashierRefreshProvider.notifier).state = !refreshState;
  }
}
