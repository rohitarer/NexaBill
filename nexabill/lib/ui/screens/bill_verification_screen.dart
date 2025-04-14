import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/ui/widgets/bill_container.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/ui/widgets/verification_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillVerificationScreen extends ConsumerStatefulWidget {
  const BillVerificationScreen({super.key});

  @override
  ConsumerState<BillVerificationScreen> createState() =>
      _BillVerificationScreenState();
}

class _BillVerificationScreenState
    extends ConsumerState<BillVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _errorText = "";

  Future<void> _checkCode(
    String value,
    WidgetRef ref,
    BuildContext context,
    void Function(String) setErrorText,
    TextEditingController controller,
  ) async {
    if (value.length == 6) {
      FocusScope.of(context).unfocus();
      debugPrint("🔢 6-digit OTP entered: $value");

      try {
        final otpQuery =
            await FirebaseFirestore.instance
                .collection('otps')
                .where('otp', isEqualTo: value)
                .limit(1)
                .get();

        debugPrint(
          "📡 Firestore returned ${otpQuery.docs.length} matching OTP record(s)",
        );

        if (otpQuery.docs.isEmpty) {
          debugPrint("❌ No matching OTP found.");
          setErrorText("Invalid OTP. Please try again.");
          return;
        }

        final otpDoc = otpQuery.docs.first;
        final otpData = otpDoc.data();
        final billNo = otpDoc.id;
        final userId = otpData['uid'] ?? otpData['customerId'];

        debugPrint("✅ OTP matches with billNo: $billNo, userId: $userId");

        if (userId == null || billNo.isEmpty) {
          debugPrint("❌ Missing userId or billNo in OTP document.");
          setErrorText("Invalid OTP record.");
          return;
        }

        // ✅ Assign global values
        BillData.customerId = userId;
        BillData.billNo = billNo;

        final billRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('my_bills')
            .doc(billNo);

        final billSnapshot = await billRef.get();
        if (!billSnapshot.exists) {
          debugPrint(
            "❌ Bill not found for billNo: $billNo under user: $userId",
          );
          setErrorText("Bill not found for this OTP.");
          return;
        }

        final data = billSnapshot.data()!;
        final rawProducts = data['products'];
        if (rawProducts is List) {
          BillData.products = List<Map<String, dynamic>>.from(rawProducts);
        } else if (rawProducts is Map) {
          BillData.products =
              rawProducts.values
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
        } else {
          BillData.products = [];
        }

        // ✅ Assign bill details
        BillData.customerName = data['customerName'] ?? '';
        BillData.customerMobile = data['customerMobile'] ?? '';
        BillData.martName = data['martName'] ?? '';
        BillData.martAddress = data['martAddress'] ?? '';
        BillData.amountPaid = (data['amountPaid'] ?? 0).toDouble();
        BillData.otp = data['otp'] ?? '';
        BillData.billDate = data['billDate'] ?? '';
        BillData.session = data['session'] ?? '';
        BillData.martContact = data['martContact'] ?? '';
        BillData.martGSTIN = data['martGSTIN'] ?? '';
        BillData.martCIN = data['martCIN'] ?? '';
        BillData.sealStatus = data['sealStatus'] ?? 'none';

        final seal = BillSealStatusExtension.fromString(BillData.sealStatus);
        ref.read(billVerificationProvider.notifier).setSealStatus(seal);

        // ✅ Get cashier info
        final cashierUid = FirebaseAuth.instance.currentUser?.uid;
        if (cashierUid != null) {
          final cashierDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(cashierUid)
                  .get();

          final cashierData = cashierDoc.data();
          if (cashierData != null) {
            BillData.cashier = cashierData['fullName'] ?? 'Cashier';
            final counterNo =
                cashierData['counterNumber'] ?? cashierData['counterNo'];
            BillData.counterNo =
                (counterNo?.toString().trim().isNotEmpty ?? false)
                    ? counterNo.toString().trim()
                    : "Counter Unknown";

            final updateData = {
              'cashier': BillData.cashier,
              'counterNo': BillData.counterNo,
            };

            // ✅ Update in customer’s bill
            await billRef.update(updateData);

            // ✅ Mirror data to cashier’s my_bills
            await FirebaseFirestore.instance
                .collection('users')
                .doc(cashierUid)
                .collection('my_bills')
                .doc(billNo)
                .set({
                  ...data,
                  ...updateData,
                  'sealStatus': BillData.sealStatus,
                }, SetOptions(merge: true));
          }
        }

        // ✅ Final logs
        debugPrint(
          "👨‍💼 Cashier: ${BillData.cashier} | Counter: ${BillData.counterNo}",
        );
        debugPrint("📋 Bill Loaded:");
        debugPrint("  - Bill No: ${BillData.billNo}");
        debugPrint(
          "  - Customer: ${BillData.customerName} | ${BillData.customerMobile}",
        );
        debugPrint("  - Mart: ${BillData.martName}, ${BillData.martAddress}");
        debugPrint("  - Amount Paid: ₹${BillData.amountPaid}");
        debugPrint("  - Products Count: ${BillData.products.length}");

        setErrorText("");
        ref
            .read(billVerificationProvider.notifier)
            .showBill(otp: value, userId: userId);
        controller.clear();
      } catch (e, st) {
        debugPrint("❌ Error verifying OTP: $e");
        debugPrint("📍 StackTrace: $st");
        setErrorText("Something went wrong. Try again.");
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billVerificationProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final ScrollController scrollController = ScrollController();

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "“Every bill verified is a step toward trust.”",
                  style: TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Enter 6-digit Verification Code",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 200,
                  child: CustomTextField(
                    controller: _codeController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    hintText: "XXXXXX",
                    onChanged:
                        (value) => _checkCode(
                          value,
                          ref,
                          context,
                          (error) => setState(() => _errorText = error),
                          _codeController,
                        ),
                    isPassword: false,
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (_errorText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorText,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (state.isVisible)
          BillContainer(
            scrollController: scrollController,
            billItems: BillData.products,
            isKeyboardOpen: isKeyboardOpen,
          ),
        if (state.isVisible)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: VerificationButtons(ref: ref, martName: BillData.martName),
          ),
      ],
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/ui/widgets/custom_textfield.dart';
// import 'package:nexabill/providers/bill_verification_provider.dart';
// import 'package:nexabill/ui/widgets/bill_container.dart';
// import 'package:nexabill/data/bill_data.dart';
// import 'package:nexabill/ui/widgets/verification_buttons.dart';

// class BillVerificationScreen extends ConsumerStatefulWidget {
//   const BillVerificationScreen({super.key});

//   @override
//   ConsumerState<BillVerificationScreen> createState() =>
//       _BillVerificationScreenState();
// }

// class _BillVerificationScreenState
//     extends ConsumerState<BillVerificationScreen> {
//   final TextEditingController _codeController = TextEditingController();
//   String _errorText = "";

//   Future<void> _checkCode(String value) async {
//     if (value.length == 6) {
//       FocusScope.of(context).unfocus();
//       debugPrint("🔢 6-digit OTP entered: $value");

//       try {
//         final otpQuery =
//             await FirebaseFirestore.instance
//                 .collection('otps')
//                 .where('otp', isEqualTo: value)
//                 .limit(1)
//                 .get();

//         debugPrint(
//           "📡 Firestore returned ${otpQuery.docs.length} matching OTP record(s)",
//         );

//         if (otpQuery.docs.isEmpty) {
//           debugPrint("❌ No matching OTP found.");
//           setState(() => _errorText = "Invalid OTP. Please try again.");
//           return;
//         }

//         final otpDoc = otpQuery.docs.first;
//         final otpData = otpDoc.data();
//         final billNo = otpDoc.id;
//         final userId = otpData['uid'] ?? otpData['customerId'];

//         debugPrint("✅ OTP matches with billNo: $billNo, userId: $userId");

//         if (userId == null || billNo.isEmpty) {
//           debugPrint("❌ Missing userId or billNo in OTP document.");
//           setState(() => _errorText = "Invalid OTP record.");
//           return;
//         }

//         final billSnapshot =
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(userId)
//                 .collection('my_bills')
//                 .doc(billNo)
//                 .get();

//         if (!billSnapshot.exists) {
//           debugPrint(
//             "❌ Bill not found for billNo: $billNo under user: $userId",
//           );
//           setState(() => _errorText = "Bill not found for this OTP.");
//           return;
//         }

//         final data = billSnapshot.data()!;
//         BillData.billNo = data['billNo'] ?? '';

//         // ✅ Fixed: Handle both Map and List types for products
//         final rawProducts = data['products'];
//         if (rawProducts is List) {
//           BillData.products = List<Map<String, dynamic>>.from(rawProducts);
//         } else if (rawProducts is Map) {
//           BillData.products =
//               rawProducts.values
//                   .map((item) => Map<String, dynamic>.from(item))
//                   .toList();
//         } else {
//           BillData.products = [];
//         }

//         BillData.customerName = data['customerName'] ?? '';
//         BillData.customerMobile = data['customerMobile'] ?? '';
//         BillData.martName = data['martName'] ?? '';
//         BillData.martAddress = data['martAddress'] ?? '';
//         BillData.amountPaid = (data['amountPaid'] ?? 0).toDouble();
//         BillData.otp = data['otp'] ?? '';
//         BillData.billDate = data['billDate'] ?? '';
//         BillData.session = data['session'] ?? '';
//         BillData.counterNo = data['counterNo'] ?? '';
//         BillData.martContact = data['martContact'] ?? '';
//         BillData.martGSTIN = data['martGSTIN'] ?? '';
//         BillData.martCIN = data['martCIN'] ?? '';

//         debugPrint("📋 Bill Loaded:");
//         debugPrint("  - Bill No: ${BillData.billNo}");
//         debugPrint(
//           "  - Customer: ${BillData.customerName} | ${BillData.customerMobile}",
//         );
//         debugPrint("  - Mart: ${BillData.martName}, ${BillData.martAddress}");
//         debugPrint("  - Amount Paid: ₹${BillData.amountPaid}");
//         debugPrint("  - Products Count: ${BillData.products.length}");

//         setState(() => _errorText = "");
//         ref
//             .read(billVerificationProvider.notifier)
//             .showBill(otp: value, userId: userId);
//         _codeController.clear();
//       } catch (e, st) {
//         debugPrint("❌ Error verifying OTP: $e");
//         debugPrint("📍 StackTrace: $st");
//         setState(() => _errorText = "Something went wrong. Try again.");
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _codeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(billVerificationProvider);
//     final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
//     final ScrollController scrollController = ScrollController();

//     return Stack(
//       children: [
//         Center(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 const Text(
//                   "“Every bill verified is a step toward trust.”",
//                   style: TextStyle(
//                     fontFamily: 'Caveat',
//                     fontSize: 20,
//                     fontWeight: FontWeight.w500,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Enter 6-digit Verification Code",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 SizedBox(
//                   width: 200,
//                   child: CustomTextField(
//                     controller: _codeController,
//                     maxLength: 6,
//                     keyboardType: TextInputType.number,
//                     hintText: "XXXXXX",
//                     onChanged: _checkCode,
//                     isPassword: false,
//                     textAlign: TextAlign.center,
//                     textStyle: const TextStyle(
//                       fontSize: 28,
//                       letterSpacing: 10,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ),
//                 if (_errorText.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       _errorText,
//                       style: const TextStyle(color: Colors.red, fontSize: 14),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         if (state.isVisible)
//           BillContainer(
//             scrollController: scrollController,
//             billItems: BillData.products,
//             isKeyboardOpen: isKeyboardOpen,
//           ),
//         if (state.isVisible)
//           Positioned(
//             bottom: 20,
//             left: 0,
//             right: 0,
//             child: VerificationButtons(ref: ref, martName: BillData.martName),
//           ),
//       ],
//     );
//   }
// }
