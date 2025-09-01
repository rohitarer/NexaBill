// lib/utils/clear_bill_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/home_provider.dart';

// Providers used on Customer Home
import 'package:nexabill/ui/screens/customer_home_screen.dart'
  show scannedProductsProvider,
       selectedMartProvider,
       selectedAdminUidProvider,
       bluetoothItemCountProvider,
       basketNumberProvider,
       bluetoothDeviceProvider,
       productsProvider;

// Toggles / verification
import 'package:nexabill/providers/cam_verification_provider.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';

Future<void> clearAllBillState(WidgetRef ref) async {
  // ✳ Set explicit states
  ref.read(scannedProductsProvider.notifier).state = [];
  ref.read(selectedMartProvider.notifier).state = null;
  ref.read(selectedAdminUidProvider.notifier).state = null;
  ref.read(bluetoothItemCountProvider.notifier).state = 0;
  ref.read(basketNumberProvider.notifier).state = '';
  ref.read(bluetoothDeviceProvider.notifier).state = null;

  // ✳ Reset toggles
  ref.read(camVerificationProvider.notifier).state = false;
  // If your billVerificationProvider has a reset:
  ref.read(billVerificationProvider.notifier).reset();

  // ✳ Invalidate caches so dependents refetch cleanly
  ref.invalidate(productsProvider);
  ref.invalidate(scannedProductsProvider);
  ref.invalidate(selectedMartProvider);
  ref.invalidate(selectedAdminUidProvider);
  ref.invalidate(bluetoothItemCountProvider);
  ref.invalidate(basketNumberProvider);
  ref.invalidate(bluetoothDeviceProvider);

  // ✳ Clear static singletons
  BillData.resetBillData();
}
