import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final paymentsProvider =
    StateNotifierProvider<PaymentsNotifier, List<Map<String, dynamic>>>(
      (ref) => PaymentsNotifier(ref),
    );

class PaymentsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  PaymentsNotifier(this.ref) : super([]);

  void fetchCustomerPayments(String customerUid) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot =
          await firestore
              .collection('users')
              .doc(customerUid)
              .collection('my_bills')
              .get();

      final bills =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final productsRaw = data['products'];

            final List<Map<String, dynamic>> productsList =
                (productsRaw is Map<String, dynamic>)
                    ? productsRaw.values
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList()
                    : [];

            final totalAmount = productsList.fold(0.0, (sum, item) {
              final price = item['finalPrice'] ?? item['price'] ?? 0.0;
              final quantity = item['quantity'] ?? 1;
              return sum + (price as num) * (quantity as num);
            });

            final balanceAmount = totalAmount - (data['amountPaid'] ?? 0.0);

            return {
              'customerId': customerUid,
              'customerName': data['customerName'] ?? '',
              'customerMobile': data['customerMobile'] ?? '',
              'billNo': doc.id,
              'billDate': data['billDate'] ?? '',
              'products': productsList,
              'amountPaid': (data['amountPaid'] ?? 0).toDouble(),
              'balanceAmount': balanceAmount,
              'sealStatus': data['sealStatus'] ?? 'none',
              'martName': data['martName'] ?? '',
            };
          }).toList();

      // Sort bills in descending order of bill number
      bills.sort((a, b) {
        final aNum = int.tryParse(a['billNo'].replaceAll("BILL#", "")) ?? 0;
        final bNum = int.tryParse(b['billNo'].replaceAll("BILL#", "")) ?? 0;
        return bNum.compareTo(aNum);
      });

      state = bills;
      debugPrint("📥 Loaded ${bills.length} bills into paymentsProvider.");
    } catch (e, st) {
      debugPrint("❌ Failed to fetch payments: $e");
      debugPrint("📍 StackTrace: $st");
    }
  }

  void clearPayments() {
    state = [];
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:nexabill/data/bill_data.dart';
// import 'package:nexabill/models/payment_model.dart';
// import 'package:nexabill/providers/bill_verification_provider.dart';

// final paymentsProvider =
//     StateNotifierProvider<PaymentsNotifier, List<PaymentModel>>(
//       (ref) => PaymentsNotifier(ref),
//     );

// class PaymentsNotifier extends StateNotifier<List<PaymentModel>> {
//   final Ref ref;
//   PaymentsNotifier(this.ref) : super([]);

//   void addPaymentFromBillData() {
//     final sealStatus = ref.read(billVerificationProvider).sealStatus;

//     final newPayment = PaymentModel(
//       customerId: BillData.customerId,
//       customerName: BillData.customerName,
//       customerMobile: BillData.customerMobile,
//       txnId: BillData.billNo.replaceAll("BILL#", "TXN"),
//       billDate: BillData.billDate,
//       billItems: BillData.products,
//       amountPaid: BillData.amountPaid,
//       balanceAmount: BillData.getBalanceAmount(),
//       sealStatus: sealStatus,
//       martName: BillData.martName,
//     );
//     state = [...state, newPayment];
//   }

//   void fetchCustomerPayments(String customerUid) async {
//     final firestore = FirebaseFirestore.instance;

//     try {
//       final snapshot =
//           await firestore
//               .collection('users')
//               .doc(customerUid)
//               .collection('my_bills')
//               .get();

//       final payments =
//           snapshot.docs.map((doc) {
//             final data = doc.data();
//             final productsRaw = data['products'];

//             final List<Map<String, dynamic>> productsList =
//                 (productsRaw is Map<String, dynamic>)
//                     ? productsRaw.values
//                         .map((item) => Map<String, dynamic>.from(item))
//                         .toList()
//                     : [];

//             return PaymentModel(
//               customerId: customerUid,
//               customerName: data['customerName'] ?? '',
//               customerMobile: data['customerMobile'] ?? '',
//               txnId: doc.id.replaceAll("BILL#", "TXN"),
//               billDate: data['billDate'] ?? '',
//               billItems: productsList,
//               amountPaid: (data['amountPaid'] ?? 0).toDouble(),
//               balanceAmount:
//                   ((productsList.fold(0.0, (sum, item) {
//                         final price =
//                             item['finalPrice'] ?? item['price'] ?? 0.0;
//                         final quantity = item['quantity'] ?? 1;
//                         return sum + (price as num) * (quantity as num);
//                       })) -
//                       (data['amountPaid'] ?? 0.0)),
//               sealStatus: BillSealStatusExtension.fromString(
//                 data['sealStatus'] ?? 'none',
//               ),
//               martName: data['martName'] ?? '',
//             );
//           }).toList();

//       state = payments;
//       debugPrint(
//         "📥 Loaded \${payments.length} customer bills into paymentsProvider.",
//       );
//     } catch (e, st) {
//       debugPrint("❌ Failed to fetch payments: \$e");
//       debugPrint("📍 StackTrace: \$st");
//     }
//   }

//   void clearPayments() {
//     state = [];
//   }
// }
