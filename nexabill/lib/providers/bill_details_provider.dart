import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';

final billDetailsProvider = FutureProvider.family<bool, BillDetailsParams>((
  ref,
  BillDetailsParams params,
) async {
  if (params.customerUid.isEmpty || params.billNo.isEmpty) return false;

  try {
    final doc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(params.customerUid)
            .collection("my_bills")
            .doc(params.billNo)
            .get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final billItems =
        (data['products'] as Map?)?.values
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    BillData.customerId = params.customerUid;
    BillData.customerName = data['customerName'] ?? '';
    BillData.customerMobile = data['customerMobile'] ?? '';
    BillData.billNo = params.billNo;
    BillData.billDate = data['billDate'] ?? '';
    BillData.session = data['session'] ?? '';
    BillData.products = billItems;
    BillData.amountPaid = (data['amountPaid'] ?? 0).toDouble();
    BillData.sealStatus = data['sealStatus'] ?? 'none';
    BillData.martName = data['martName'] ?? '';
    BillData.martContact = data['martContact'] ?? '';
    BillData.martGSTIN = data['martGSTIN'] ?? '';
    BillData.martCIN = data['martCIN'] ?? '';
    BillData.martAddress = data['martAddress'] ?? '';
    BillData.martState = data['martState'] ?? '';
    BillData.counterNo = data['counterNo'] ?? '';
    BillData.cashier = data['cashier'] ?? '';
    BillData.otp = data['otp'] ?? '';

    // Update the provider's seal status as well
    final notifier = ref.read(billVerificationProvider.notifier);
    if (BillData.sealStatus == 'sealed') {
      notifier.setSealStatus(BillSealStatus.sealed);
    } else if (BillData.sealStatus == 'rejected') {
      notifier.setSealStatus(BillSealStatus.rejected);
    } else {
      notifier.setSealStatus(BillSealStatus.none);
    }

    return true;
  } catch (e, st) {
    print("❌ Error loading bill details: $e\n📍 $st");
    return false;
  }
});

class BillDetailsParams {
  final String customerUid;
  final String billNo;

  const BillDetailsParams({required this.customerUid, required this.billNo});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillDetailsParams &&
          runtimeType == other.runtimeType &&
          customerUid == other.customerUid &&
          billNo == other.billNo;

  @override
  int get hashCode => customerUid.hashCode ^ billNo.hashCode;
}
