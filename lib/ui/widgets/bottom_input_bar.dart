// 🔄 Final Razorpay integration with OTP update trigger using Riverpod

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/otp_provider.dart';
import 'package:nexabill/ui/screens/customer_home_screen.dart';
import 'package:nexabill/ui/screens/qr_scanner_screen.dart';
import 'package:nexabill/ui/screens/microphone_input_screen.dart';
import 'package:nexabill/ui/screens/text_input_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BottomInputBar extends ConsumerStatefulWidget {
  const BottomInputBar({super.key});

  @override
  ConsumerState<BottomInputBar> createState() => _BottomInputBarState();
}

class _BottomInputBarState extends ConsumerState<BottomInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showExtraIcons = false;
  bool _isTyping = false;
  int _quantity = 1;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    // _focusNode.addListener(() {
    //   debugPrint("📌 Focus changed: hasFocus = ${_focusNode.hasFocus}");
    //   if (!_focusNode.hasFocus && mounted) {
    //     setState(() => _isTyping = false);
    //   }
    // });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Payment Successful")));

    final scannedProducts = ref.read(scannedProductsProvider);
    double totalFinalAmount = 0.0;
    for (var item in scannedProducts) {
      final price = item["finalPrice"] ?? item["price"] ?? 0.0;
      final quantity = item["quantity"] ?? 1;
      totalFinalAmount += (price as double) * (quantity as int);
    }

    final otp = (100000 + Random().nextInt(900000)).toString();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (BillData.billNo.isNotEmpty && uid != null) {
      await FirebaseFirestore.instance
          .collection("otps")
          .doc(BillData.billNo)
          .set({
            'otp': otp,
            'amountPaid': totalFinalAmount,
            'timestamp': FieldValue.serverTimestamp(),
            'expiresAt':
                DateTime.now()
                    .add(const Duration(minutes: 10))
                    .toIso8601String(),
          });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("my_bills")
          .doc(BillData.billNo)
          .set({
            'billNo': BillData.billNo,
            'products': scannedProducts,
            'customerName': BillData.customerName,
            'customerMobile': BillData.customerMobile,
            'martName': BillData.martName,
            'martAddress': BillData.martAddress,
            'amountPaid': totalFinalAmount,
            'otp': otp,
            'timestamp': DateTime.now().toIso8601String(),
            'paymentId': response.paymentId,
            'orderId': response.orderId,
            'signature': response.signature,
          });

      BillData.amountPaid = totalFinalAmount;
      BillData.otp = otp;
      ref.read(otpRefreshProvider.notifier).state =
          !ref.read(otpRefreshProvider);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("💼 Wallet: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget buildQuantityBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.whiteColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.red),
            onPressed:
                () => setState(
                  () => _quantity = (_quantity > 1) ? _quantity - 1 : 1,
                ),
          ),
          Text(
            "$_quantity",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 20,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Text(
                "Choose Payment Method",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.money),
                label: const Text("Cash Payment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("💵 Cash Payment Selected")),
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text("Pay with Razorpay"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  final scannedProducts = ref.read(scannedProductsProvider);
                  double totalFinalAmount = 0.0;
                  for (var item in scannedProducts) {
                    final price = item["finalPrice"] ?? item["price"] ?? 0.0;
                    final quantity = item["quantity"] ?? 1;
                    totalFinalAmount += (price as double) * (quantity as int);
                  }
                  final int amountPaise = (totalFinalAmount * 100).toInt();

                  _razorpay.open({
                    'key': 'rzp_test_CYtWPQqiG0GETR',
                    'amount': amountPaise,
                    'name': "Rohit Arer",
                    'description': 'Bill Payment',
                    'prefill': {
                      'contact': '9999999999',
                      'email': 'test@example.com',
                    },
                    'external': {
                      'wallets': ['paytm'],
                    },
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void updateTypingState(String value) {
    final shouldType = value.trim().isNotEmpty;
    debugPrint("⌨️ onChanged: '$value' | typing: $shouldType");
    if (_isTyping != shouldType && mounted) {
      setState(() {
        debugPrint("⌨️ updateTypingState: typing = $shouldType");
        _isTyping = shouldType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scannedProducts = ref.watch(scannedProductsProvider);
    // final isPayButtonEnabled = scannedProducts.isNotEmpty;
    final basketCount = ref.watch(bluetoothItemCountProvider);
    // ✅ Calculate total quantity in bill
    int totalBillQuantity = scannedProducts.fold<int>(
      0,
      (sum, item) => sum + ((item["quantity"] ?? 1) as int),
    );

    // ✅ Enable pay button only if total items == basket count
    final isPayButtonEnabled =
        totalBillQuantity > 0 && totalBillQuantity == basketCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isTyping) buildQuantityBox(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: false,
            textInputAction: TextInputAction.done,
            onChanged: updateTypingState,
            onTap: () => debugPrint("🖱️ TextField tapped"),
            // onFieldSubmitted: (_) {
            //   debugPrint("🔚 onFieldSubmitted");
            //   if (mounted) setState(() => _isTyping = false);
            // },
            onFieldSubmitted: (_) => updateTypingState(''),
            decoration: InputDecoration(
              hintText: "Enter amount or message...",
              hintStyle: TextStyle(color: theme.hintColor),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isTyping)
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          final text = _controller.text.trim();
                          debugPrint("📤 Send tapped: '$text'");
                          if (text.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => TextInputScreen(
                                      initialText: text,
                                      quantity: _quantity,
                                    ),
                              ),
                            );
                            _controller.clear();
                            setState(() => _isTyping = false);
                          }
                        },
                      )
                    else
                      ElevatedButton(
                        onPressed:
                            isPayButtonEnabled ? _showPaymentOptions : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blueColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: const Text("Pay"),
                      ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                      child:
                          _showExtraIcons
                              ? Row(
                                key: const ValueKey("icons"),
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    color: theme.iconTheme.color,
                                    onPressed: () async {
                                      final status =
                                          await Permission.camera.request();
                                      if (status.isGranted) {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => const Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                insetPadding: EdgeInsets.all(
                                                  20,
                                                ),
                                                child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: QRScannerScreen(),
                                                ),
                                              ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Camera permission required.",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.mic),
                                    color: theme.iconTheme.color,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  const MicrophoneInputScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                              : const SizedBox(key: ValueKey("empty")),
                    ),
                    IconButton(
                      icon: Icon(_showExtraIcons ? Icons.remove : Icons.add),
                      color: theme.iconTheme.color,
                      onPressed:
                          () => setState(
                            () => _showExtraIcons = !_showExtraIcons,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// // 🔄 Final Razorpay integration with OTP update trigger using Riverpod

// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/data/bill_data.dart';
// import 'package:nexabill/providers/customer_home_provider.dart';
// import 'package:nexabill/providers/otp_provider.dart';
// import 'package:nexabill/services/razorpay_service.dart';
// import 'package:nexabill/ui/screens/customer_home_screen.dart';
// import 'package:nexabill/ui/screens/qr_scanner_screen.dart';
// import 'package:nexabill/ui/screens/microphone_input_screen.dart';
// import 'package:nexabill/ui/screens/text_input_screen.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// class BottomInputBar extends ConsumerStatefulWidget {
//   const BottomInputBar({super.key});

//   @override
//   ConsumerState<BottomInputBar> createState() => _BottomInputBarState();
// }

// class _BottomInputBarState extends ConsumerState<BottomInputBar> {
//   final TextEditingController _controller = TextEditingController();
//   bool _showExtraIcons = false;
//   bool _isTyping = false;
//   late Razorpay _razorpay;

//   @override
//   void initState() {
//     super.initState();
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) async {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("✅ Payment Successful")));

//     final scannedProducts = ref.read(scannedProductsProvider);
//     double totalFinalAmount = 0.0;
//     for (var item in scannedProducts) {
//       final price = item["finalPrice"] ?? item["price"] ?? 0.0;
//       final quantity = item["quantity"] ?? 1;
//       totalFinalAmount += (price as double) * (quantity as int);
//     }

//     final otp = (100000 + Random().nextInt(900000)).toString();
//     final uid = FirebaseAuth.instance.currentUser?.uid;

//     if (BillData.billNo.isNotEmpty && uid != null) {
//       await FirebaseFirestore.instance
//           .collection("otps")
//           .doc(BillData.billNo)
//           .set({
//             'otp': otp,
//             'amountPaid': totalFinalAmount,
//             'timestamp': FieldValue.serverTimestamp(),
//             'expiresAt':
//                 DateTime.now()
//                     .add(const Duration(minutes: 10))
//                     .toIso8601String(),
//           });

//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(uid)
//           .collection("my_bills")
//           .doc(BillData.billNo)
//           .set({
//             'billNo': BillData.billNo,
//             'products': scannedProducts,
//             'customerName': BillData.customerName,
//             'customerMobile': BillData.customerMobile,
//             'martName': BillData.martName,
//             'martAddress': BillData.martAddress,
//             'amountPaid': totalFinalAmount,
//             'otp': otp,
//             'timestamp': DateTime.now().toIso8601String(),
//             'paymentId': response.paymentId,
//             'orderId': response.orderId,
//             'signature': response.signature,
//           });

//       BillData.amountPaid = totalFinalAmount;
//       BillData.otp = otp;
//       ref.read(otpRefreshProvider.notifier).state =
//           !ref.read(otpRefreshProvider);

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
//         );
//       }
//     }
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("❌ Payment Failed: ${response.message}")),
//     );
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("💼 Wallet: ${response.walletName}")),
//     );
//   }

//   @override
//   void dispose() {
//     _razorpay.clear();
//     _controller.dispose();
//     super.dispose();
//   }

//   void _showPaymentOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         return Padding(
//           padding: const EdgeInsets.all(20),
//           child: Wrap(
//             runSpacing: 20,
//             children: [
//               Center(
//                 child: Container(
//                   height: 4,
//                   width: 40,
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[400],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               Text(
//                 "Choose Payment Method",
//                 style: Theme.of(
//                   context,
//                 ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//               ),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.money),
//                 label: const Text("Cash Payment"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   minimumSize: const Size.fromHeight(50),
//                 ),
//                 onPressed: () {
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("💵 Cash Payment Selected")),
//                   );
//                 },
//               ),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.payment),
//                 label: const Text("Pay with Razorpay"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.deepPurple,
//                   minimumSize: const Size.fromHeight(50),
//                 ),
//                 onPressed: () {
//                   final scannedProducts = ref.read(scannedProductsProvider);
//                   double totalFinalAmount = 0.0;
//                   for (var item in scannedProducts) {
//                     final price = item["finalPrice"] ?? item["price"] ?? 0.0;
//                     final quantity = item["quantity"] ?? 1;
//                     totalFinalAmount += (price as double) * (quantity as int);
//                   }
//                   final int amountPaise = (totalFinalAmount * 100).toInt();

//                   _razorpay.open({
//                     'key': 'rzp_test_CYtWPQqiG0GETR',
//                     'amount': amountPaise,
//                     'name': "Rohit Arer",
//                     'description': 'Bill Payment',
//                     'prefill': {
//                       'contact': '9999999999',
//                       'email': 'test@example.com',
//                     },
//                     'external': {
//                       'wallets': ['paytm'],
//                     },
//                   });
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final scannedProducts = ref.watch(scannedProductsProvider);
//     final isPayButtonEnabled = scannedProducts.isNotEmpty;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: theme.scaffoldBackgroundColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 5,
//             spreadRadius: 2,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: _controller,
//         onChanged: (value) {
//           setState(() => _isTyping = value.trim().isNotEmpty);
//         },
//         onFieldSubmitted: (_) {
//           setState(() => _isTyping = false);
//         },
//         decoration: InputDecoration(
//           hintText: "Enter amount or message...",
//           hintStyle: TextStyle(color: theme.hintColor),
//           filled: true,
//           fillColor: theme.cardColor,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: theme.dividerColor),
//           ),
//           suffixIcon: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 6),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (_isTyping)
//                   IconButton(
//                     icon: const Icon(Icons.send),
//                     color: AppTheme.primaryColor,
//                     onPressed: () {
//                       final text = _controller.text.trim();
//                       if (text.isNotEmpty) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (_) => TextInputScreen(
//                                   // userInput: text,
//                                   // quantity:
//                                   //     1, // Set default or dynamic quantity here
//                                 ),
//                           ),
//                         );

//                         _controller.clear();
//                         setState(() => _isTyping = false);
//                       }
//                     },
//                   )
//                 else
//                   ElevatedButton(
//                     onPressed: isPayButtonEnabled ? _showPaymentOptions : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.blueColor,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       minimumSize: const Size(0, 35),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       textStyle: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       disabledBackgroundColor: Colors.grey,
//                     ),
//                     child: const Text("Pay"),
//                   ),
//                 const SizedBox(width: 8),
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   transitionBuilder:
//                       (child, anim) =>
//                           FadeTransition(opacity: anim, child: child),
//                   child:
//                       _showExtraIcons
//                           ? Row(
//                             key: const ValueKey("icons"),
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.qr_code_scanner),
//                                 color: theme.iconTheme.color,
//                                 onPressed: () async {
//                                   final status =
//                                       await Permission.camera.request();
//                                   if (status.isGranted) {
//                                     showDialog(
//                                       context: context,
//                                       builder:
//                                           (_) => const Dialog(
//                                             backgroundColor: Colors.transparent,
//                                             insetPadding: EdgeInsets.all(20),
//                                             child: AspectRatio(
//                                               aspectRatio: 1,
//                                               child: QRScannerScreen(),
//                                             ),
//                                           ),
//                                     );
//                                   } else {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text(
//                                           "Camera permission required.",
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.mic),
//                                 color: theme.iconTheme.color,
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder:
//                                           (_) => const MicrophoneInputScreen(),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           )
//                           : const SizedBox(key: ValueKey("empty")),
//                 ),
//                 IconButton(
//                   icon: Icon(_showExtraIcons ? Icons.remove : Icons.add),
//                   color: theme.iconTheme.color,
//                   onPressed:
//                       () => setState(() => _showExtraIcons = !_showExtraIcons),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
