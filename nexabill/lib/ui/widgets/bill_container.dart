import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/providers/customer_home_provider.dart';
import 'package:nexabill/providers/otp_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/screens/customer_home_screen.dart';
import 'package:nexabill/ui/widgets/bill_otp_handler.dart';
import 'package:nexabill/ui/widgets/verification_stamp.dart';

class BillContainer extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> billItems;
  final bool isKeyboardOpen;

  const BillContainer({
    super.key,
    required this.scrollController,
    required this.billItems,
    required this.isKeyboardOpen,
  });

  @override
  _BillContainerState createState() => _BillContainerState();
}

class _BillContainerState extends ConsumerState<BillContainer> {
  bool _initialized = false;
  String? _billOtp;
  bool _paymentVerified = false;
  // bool _newOtpReceived = false;
  bool _waitingForOtp = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _resetPaymentState();
      await _loadBillData();
    });
  }

  void _resetPaymentState() {
    BillData.amountPaid = 0.0;
    _billOtp = null;
    _paymentVerified = false;
    _waitingForOtp = true;
    if (mounted) setState(() {});
  }

  // Future<void> _loadBillData(WidgetRef ref) async {
  Future<void> _loadBillData() async {
    try {
      print("🚀 Starting bill data load...");

      final customerProfile = await ref.read(profileFutureProvider.future);
      final adminUid = ref.read(selectedAdminUidProvider) as String?;

      print("🔐 Admin UID: $adminUid");
      print("👤 Customer Profile: $customerProfile");

      if (adminUid == null || customerProfile.isEmpty) {
        print("⚠️ Missing admin UID or empty customer profile.");
        return;
      }

      final adminDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(adminUid)
              .get();

      final adminProfile = adminDoc.data();
      print("📦 Admin Profile: $adminProfile");

      if (adminProfile == null) {
        print("❌ Admin profile not found for UID: $adminUid");
        return;
      }

      // ✅ Fill bill data
      BillData.customerName = customerProfile["fullName"] ?? "";
      BillData.customerMobile = customerProfile["phoneNumber"] ?? "";
      BillData.cashier = "";

      final martAddress = adminProfile["martAddress"] ?? "";
      final martState = adminProfile["martState"] ?? "";
      BillData.martName = adminProfile["martName"] ?? "";
      BillData.martAddress = "$martAddress, $martState, India";
      BillData.martContact = adminProfile["martContact"] ?? "";
      BillData.martGSTIN = adminProfile["martGstin"] ?? "";
      BillData.martCIN = adminProfile["martCin"] ?? "";

      final now = DateTime.now();
      BillData.billDate = DateFormat('dd-MM-yyyy').format(now);
      BillData.session = DateFormat('hh:mm a').format(now);
      BillData.counterNo = "Counter No:";

      final billSnap =
          await FirebaseFirestore.instance
              .collection("bills")
              .doc(adminUid)
              .collection("all_bills")
              .get();

      BillData.billNo = "BILL#${billSnap.docs.length + 1}";

      print("✅ Bill generated: ${BillData.billNo}");

      /// Now fetch OTP separately after frame render
      // _startOtpPolling();
      if (mounted) setState(() {});
    } catch (e, st) {
      print("❌ Error in _loadBillData: $e");
      print("📍 StackTrace: $st");
    }
  }

  // This function should be called from outside (e.g. after payment success)
  // void startOtpPollingAfterPayment() {
  //   _waitingForOtp = true;
  //   if (mounted) setState(() {});
  //   _pollForOtpUntilAvailable(clearPrevious: false);
  // }

  // Future<void> _pollForOtpUntilAvailable({bool clearPrevious = false}) async {
  //   debugPrint("📡 Polling for OTP after payment...");
  //   if (clearPrevious) _resetPaymentState();

  //   const maxTries = 8;
  //   const delay = Duration(milliseconds: 400);

  //   for (int i = 0; i < maxTries; i++) {
  //     final doc =
  //         await FirebaseFirestore.instance
  //             .collection("otps")
  //             .doc(BillData.billNo)
  //             .get();
  //     if (doc.exists) {
  //       final data = doc.data();
  //       final otp = data?["otp"]?.toString();
  //       final amount = double.tryParse("\\${data?["amountPaid"] ?? "0.0"}");

  //       if (otp != null && otp.length == 6) {
  //         if (_billOtp != otp) {
  //           _billOtp = otp;
  //           BillData.amountPaid = amount ?? 0.0;
  //           _paymentVerified = true;
  //           _newOtpReceived = true;
  //           _waitingForOtp = false;
  //           debugPrint("✅ OTP updated: \$_billOtp");
  //           if (mounted) setState(() {});
  //         }
  //         return;
  //       }
  //     }
  //     debugPrint("⏳ Waiting for OTP... Try \$i");
  //     await Future.delayed(delay);
  //   }
  //   _waitingForOtp = false;
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (!_initialized) {
  //     _initialized = true;
  //     _loadBillData(ref);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sealStatus = ref.watch(billVerificationProvider).sealStatus;

    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double bottomPadding = widget.isKeyboardOpen ? keyboardHeight : 0;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          left: 0,
          right: 0,
          bottom: bottomPadding,
          child: SizedBox(
            height: screenHeight * 0.95,
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.4,
              maxChildSize: 0.98,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 50),
                            _buildHeader(isDarkMode),
                            const Divider(thickness: 1.5),
                            _buildCustomerDetails(),
                            const Divider(thickness: 1.5),
                            _buildProductList(isDarkMode),
                            const Divider(thickness: 1.5),
                            _buildBillSummary(isDarkMode),
                            const Divider(thickness: 1.5),
                            _buildPaymentDetails(isDarkMode),
                            const Divider(thickness: 1.5),
                            // _buildVerificationCode(isDarkMode),
                            const Divider(thickness: 1.5),
                            _buildFooterQuote(isDarkMode),
                            const SizedBox(height: 40),
                          ],
                        ),
                        if (sealStatus != BillSealStatus.none)
                          Center(
                            child: VerificationStamp(
                              type:
                                  sealStatus == BillSealStatus.sealed
                                      ? StampType.verified
                                      : StampType.rejected,
                              martName: BillData.martName,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "🛒 ${BillData.martName.toUpperCase()} 🛒",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          "${BillData.martAddress}, ${BillData.martState}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 3),
        Text(
          "📞 ${BillData.martContact}  |  🏢 GSTIN: ${BillData.martGSTIN}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Text(
          "🔹 CIN: ${BillData.martCIN}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              30,
              (index) => Text(
                "-",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Text(
          "**** CUSTOMER COPY ****",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "TXN ID: #${BillData.billNo.replaceAll("BILL#", "")}",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "📆 ${BillData.billDate}  |  🕒 ${BillData.session}  |  💼 Counter No:",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              30,
              (index) => Text(
                "-",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails() {
    // Safely parse the session time
    int hour;
    try {
      if (BillData.session.isNotEmpty) {
        final time = DateFormat('hh:mm a').parse(BillData.session);
        hour = time.hour;
      } else {
        hour = DateTime.now().hour;
      }
    } catch (e) {
      debugPrint("❌ Error parsing BillData.session: $e");
      hour = DateTime.now().hour; // fallback
    }

    String sessionLabel;
    if (hour >= 5 && hour < 12) {
      sessionLabel = "🌅 Morning";
    } else if (hour >= 12 && hour < 17) {
      sessionLabel = "☀️ Afternoon";
    } else if (hour >= 17 && hour < 21) {
      sessionLabel = "🌇 Evening";
    } else {
      sessionLabel = "🌙 Night";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${BillData.billNo} | Counter No:",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "${BillData.billDate}  |  🕒 ${BillData.session}  |  Session: $sessionLabel",
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 5),
        Text(
          BillData.customerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(BillData.customerMobile, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 5),
        const Text(
          "Cashier:",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProductList(bool isDarkMode) => Column(
    children:
        widget.billItems.map((item) {
          final serial = item["serial"] ?? 0;
          final name = item["name"] ?? "";
          final qty = item["quantity"] ?? 1;
          final price = item["price"] ?? 0.0;
          final gst = item["gst"] ?? "0%";
          final discount = item["discount"] ?? "0%";
          final finalPrice = item["finalPrice"] ?? price;

          final total = (finalPrice as double) * (qty as int);

          return Dismissible(
            key: ValueKey("$serial-$name"),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() {
                widget.billItems.remove(item);

                // Reassign serials after removal
                for (int i = 0; i < widget.billItems.length; i++) {
                  widget.billItems[i]["serial"] = i + 1;
                }

                // Optional: update scannedProductsProvider if needed
                ref.read(scannedProductsProvider.notifier).state = [
                  ...widget.billItems,
                ];
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("🗑️ '$name' removed from bill")),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "$serial. $name",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        "₹${total.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Qty: $qty | Price/unit: ₹$price | GST: $gst | Discount: $discount",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
  );

  Widget _buildBillSummary(bool isDarkMode) {
    final scannedItems = widget.billItems;

    double totalFinalAmount = 0.0;
    int totalQuantity = 0;

    for (var item in scannedItems) {
      final price = item["finalPrice"] ?? item["price"] ?? 0.0;
      final quantity = item["quantity"] ?? 1;
      totalFinalAmount += (price as double) * (quantity as int);
      totalQuantity += quantity as int;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _billSummaryRow("Total Items:", "$totalQuantity"),
        _billSummaryRow(
          "Total Amount:",
          "₹${totalFinalAmount.toStringAsFixed(2)}",
          isBold: true,
        ),
        // _billSummaryRow(
        //   "GST:",
        //   "₹${BillData.getTotalGST().toStringAsFixed(2)}",
        // ),
        _billSummaryRow(
          "Net Amount Due:",
          "₹${totalFinalAmount.toStringAsFixed(2)}",
          isBold: true,
        ),
      ],
    );
  }

  // Widget _buildVerificationCode() {
  //   debugPrint("👁️ Building Verification Code UI: \$_billOtp");
  //   if (_waitingForOtp) {
  //     return const Text("⏳ Waiting for verification code...");
  //   } else if (_paymentVerified && _billOtp != null && _newOtpReceived) {
  //     return Text("Verification Code: \$_billOtp");
  //   }
  //   return const SizedBox.shrink();
  // }

  Widget _buildPaymentDetails(bool isDarkMode) {
    debugPrint("💰 Building Payment Details");
    double total = widget.billItems.fold(0, (sum, item) {
      final p = item["finalPrice"] ?? item["price"] ?? 0.0;
      final q = item["quantity"] ?? 1;
      return sum + (p as double) * (q as int);
    });
    final balance = total - BillData.amountPaid;
    debugPrint("🔢 Total: ₹$total");
    debugPrint("💳 Paid: ₹${BillData.amountPaid}");
    debugPrint("🧾 Balance: ₹$balance");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _billSummaryRow(
          "Amount Paid:",
          "₹${BillData.amountPaid.toStringAsFixed(2)}",
          isBold: true,
        ),
        _billSummaryRow(
          "Balance Amount:",
          "₹${balance.toStringAsFixed(2)}",
          isBold: true,
        ),
        OtpHandler(
          billNo: BillData.billNo,
          onOtpReceived: (otp, amount) {
            setState(() {
              _billOtp = otp;
              BillData.amountPaid = amount;
              _paymentVerified = true;
              _waitingForOtp = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFooterQuote(bool isDarkMode) => Center(
    child: Column(
      children: [
        const SizedBox(height: 10),
        Text(
          "💡 \"Shop smart, save more!\" 💡",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          BillData.footerMessage,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );

  Widget _billSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.green[800] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:nexabill/data/bill_data.dart';
// import 'package:nexabill/providers/bill_verification_provider.dart';
// import 'package:nexabill/providers/customer_home_provider.dart';
// import 'package:nexabill/providers/otp_provider.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/ui/screens/customer_home_screen.dart';
// import 'package:nexabill/ui/widgets/verification_stamp.dart';

// class BillContainer extends ConsumerStatefulWidget {
//   final ScrollController scrollController;
//   final List<Map<String, dynamic>> billItems;
//   final bool isKeyboardOpen;

//   const BillContainer({
//     super.key,
//     required this.scrollController,
//     required this.billItems,
//     required this.isKeyboardOpen,
//   });

//   @override
//   _BillContainerState createState() => _BillContainerState();
// }

// class _BillContainerState extends ConsumerState<BillContainer> {
//   bool _initialized = false;
//   String? _billOtp;
//   bool _paymentVerified = false;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() async {
//       _resetPaymentState();
//       await _loadBillData();
//       // await _fetchOtpAndAmount();
//     });
//   }

//   @override
//   void didUpdateWidget(covariant BillContainer oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     ref.listenManual(otpRefreshProvider, (prev, next) async {
//       await _fetchOtpAndAmount(force: true);
//       // if (mounted) setState(() {});
//     });
//   }

//   void _resetPaymentState() {
//     BillData.amountPaid = 0.0;
//     _billOtp = null;
//     _paymentVerified = false;
//     if (mounted) setState(() {});
//   }

//   // Future<void> _loadBillData(WidgetRef ref) async {
//   Future<void> _loadBillData() async {
//     try {
//       print("🚀 Starting bill data load...");

//       final customerProfile = await ref.read(profileFutureProvider.future);
//       final adminUid = ref.read(selectedAdminUidProvider) as String?;

//       print("🔐 Admin UID: $adminUid");
//       print("👤 Customer Profile: $customerProfile");

//       if (adminUid == null || customerProfile.isEmpty) {
//         print("⚠️ Missing admin UID or empty customer profile.");
//         return;
//       }

//       final adminDoc =
//           await FirebaseFirestore.instance
//               .collection("users")
//               .doc(adminUid)
//               .get();

//       final adminProfile = adminDoc.data();
//       print("📦 Admin Profile: $adminProfile");

//       if (adminProfile == null) {
//         print("❌ Admin profile not found for UID: $adminUid");
//         return;
//       }

//       // ✅ Fill bill data
//       BillData.customerName = customerProfile["fullName"] ?? "";
//       BillData.customerMobile = customerProfile["phoneNumber"] ?? "";
//       BillData.cashier = "";

//       final martAddress = adminProfile["martAddress"] ?? "";
//       final martState = adminProfile["martState"] ?? "";
//       BillData.martName = adminProfile["martName"] ?? "";
//       BillData.martAddress = "$martAddress, $martState, India";
//       BillData.martContact = adminProfile["martContact"] ?? "";
//       BillData.martGSTIN = adminProfile["martGstin"] ?? "";
//       BillData.martCIN = adminProfile["martCin"] ?? "";

//       final now = DateTime.now();
//       BillData.billDate = DateFormat('dd-MM-yyyy').format(now);
//       BillData.session = DateFormat('hh:mm a').format(now);
//       BillData.counterNo = "Counter No:";

//       final billSnap =
//           await FirebaseFirestore.instance
//               .collection("bills")
//               .doc(adminUid)
//               .collection("all_bills")
//               .get();

//       BillData.billNo = "BILL#${billSnap.docs.length + 1}";

//       print("✅ Bill generated: ${BillData.billNo}");
//       // _resetPaymentState();
//       // await Future.delayed(const Duration(milliseconds: 300));
//       await _fetchOtpAndAmount(force: true);

//       // // 🔄 Rebuild
//       if (mounted) setState(() {});
//     } catch (e, st) {
//       print("❌ Error in _loadBillData: $e");
//       print("📍 StackTrace: $st");
//     }
//   }

//   // Future<void> _fetchOtpAndAmount({bool force = false}) async {
//   //   try {
//   //     final otpDoc =
//   //         await FirebaseFirestore.instance
//   //             .collection("otps")
//   //             .doc(BillData.billNo)
//   //             .get();
//   //     if (otpDoc.exists) {
//   //       final data = otpDoc.data();
//   //       final amount = data?["amountPaid"];
//   //       final otp = data?["otp"];

//   //       if (amount != null)
//   //         BillData.amountPaid = double.tryParse("$amount") ?? 0.0;

//   //       final newOtp = (otp != null && "$otp".length == 6) ? "$otp" : null;
//   //       if (force || newOtp != _billOtp) {
//   //         _billOtp = newOtp;
//   //         _paymentVerified = newOtp != null;
//   //         if (mounted) setState(() {});
//   //       }
//   //     } else {
//   //       _resetPaymentState();
//   //       if (mounted) setState(() {});
//   //     }
//   //   } catch (_) {}
//   // }

//   Future<void> _fetchOtpAndAmount({bool force = false}) async {
//     try {
//       final otpDoc =
//           await FirebaseFirestore.instance
//               .collection("otps")
//               .doc(BillData.billNo)
//               .get();
//       if (otpDoc.exists) {
//         final data = otpDoc.data();
//         final amount = data?["amountPaid"];
//         final otp = data?["otp"];

//         if (amount != null)
//           BillData.amountPaid = double.tryParse("$amount") ?? 0.0;

//         final newOtp = (otp != null && "$otp".length == 6) ? "$otp" : null;
//         _billOtp = newOtp;
//         _paymentVerified = newOtp != null;

//         if (mounted) setState(() {});
//       } else {
//         _resetPaymentState();
//       }
//     } catch (_) {}
//   }

//   // @override
//   // void didChangeDependencies() {
//   //   super.didChangeDependencies();
//   //   if (!_initialized) {
//   //     _initialized = true;
//   //     _loadBillData(ref);
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     final sealStatus = ref.watch(billVerificationProvider).sealStatus;

//     double screenHeight = MediaQuery.of(context).size.height;
//     double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
//     double bottomPadding = widget.isKeyboardOpen ? keyboardHeight : 0;

//     return Stack(
//       children: [
//         AnimatedPositioned(
//           duration: const Duration(milliseconds: 250),
//           left: 0,
//           right: 0,
//           bottom: bottomPadding,
//           child: SizedBox(
//             height: screenHeight * 0.95,
//             child: DraggableScrollableSheet(
//               initialChildSize: 0.4,
//               minChildSize: 0.4,
//               maxChildSize: 0.98,
//               expand: false,
//               builder: (context, scrollController) {
//                 return Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: isDarkMode ? Colors.black : Colors.white,
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(16),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         spreadRadius: 2,
//                         offset: const Offset(0, -4),
//                       ),
//                     ],
//                   ),
//                   child: SingleChildScrollView(
//                     controller: scrollController,
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const SizedBox(height: 50),
//                             _buildHeader(isDarkMode),
//                             const Divider(thickness: 1.5),
//                             _buildCustomerDetails(),
//                             const Divider(thickness: 1.5),
//                             _buildProductList(isDarkMode),
//                             const Divider(thickness: 1.5),
//                             _buildBillSummary(isDarkMode),
//                             const Divider(thickness: 1.5),
//                             _buildPaymentDetails(isDarkMode),
//                             const Divider(thickness: 1.5),
//                             _buildFooterQuote(isDarkMode),
//                             const SizedBox(height: 40),
//                           ],
//                         ),
//                         if (sealStatus != BillSealStatus.none)
//                           Center(
//                             child: VerificationStamp(
//                               type:
//                                   sealStatus == BillSealStatus.sealed
//                                       ? StampType.verified
//                                       : StampType.rejected,
//                               martName: BillData.martName,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader(bool isDarkMode) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           "🛒 ${BillData.martName.toUpperCase()} 🛒",
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: isDarkMode ? Colors.white : Colors.black,
//             letterSpacing: 1.2,
//           ),
//         ),
//         Text(
//           "${BillData.martAddress}, ${BillData.martState}",
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//         ),
//         const SizedBox(height: 3),
//         Text(
//           "📞 ${BillData.martContact}  |  🏢 GSTIN: ${BillData.martGSTIN}",
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//         ),
//         Text(
//           "🔹 CIN: ${BillData.martCIN}",
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(
//               30,
//               (index) => Text(
//                 "-",
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[500],
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Text(
//           "**** CUSTOMER COPY ****",
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: isDarkMode ? Colors.white70 : Colors.black87,
//             letterSpacing: 1.1,
//           ),
//         ),
//         const SizedBox(height: 3),
//         Text(
//           "TXN ID: #${BillData.billNo.replaceAll("BILL#", "")}",
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: Colors.blueAccent,
//           ),
//         ),
//         const SizedBox(height: 3),
//         Text(
//           "📆 ${BillData.billDate}  |  🕒 ${BillData.session}  |  💼 Counter No:",
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(
//               30,
//               (index) => Text(
//                 "-",
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[500],
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCustomerDetails() {
//     // Safely parse the session time
//     int hour;
//     try {
//       if (BillData.session.isNotEmpty) {
//         final time = DateFormat('hh:mm a').parse(BillData.session);
//         hour = time.hour;
//       } else {
//         hour = DateTime.now().hour;
//       }
//     } catch (e) {
//       debugPrint("❌ Error parsing BillData.session: $e");
//       hour = DateTime.now().hour; // fallback
//     }

//     String sessionLabel;
//     if (hour >= 5 && hour < 12) {
//       sessionLabel = "🌅 Morning";
//     } else if (hour >= 12 && hour < 17) {
//       sessionLabel = "☀️ Afternoon";
//     } else if (hour >= 17 && hour < 21) {
//       sessionLabel = "🌇 Evening";
//     } else {
//       sessionLabel = "🌙 Night";
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "${BillData.billNo} | Counter No:",
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           "${BillData.billDate}  |  🕒 ${BillData.session}  |  Session: $sessionLabel",
//           style: const TextStyle(fontSize: 15),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           BillData.customerName,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(BillData.customerMobile, style: const TextStyle(fontSize: 15)),
//         const SizedBox(height: 5),
//         const Text(
//           "Cashier:",
//           style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }

//   Widget _buildProductList(bool isDarkMode) => Column(
//     children:
//         widget.billItems.map((item) {
//           final serial = item["serial"] ?? 0;
//           final name = item["name"] ?? "";
//           final qty = item["quantity"] ?? 1;
//           final price = item["price"] ?? 0.0;
//           final gst = item["gst"] ?? "0%";
//           final discount = item["discount"] ?? "0%";
//           final finalPrice = item["finalPrice"] ?? price;

//           final total = (finalPrice as double) * (qty as int);

//           return Dismissible(
//             key: ValueKey("$serial-$name"),
//             direction: DismissDirection.endToStart,
//             background: Container(
//               color: Colors.redAccent,
//               alignment: Alignment.centerRight,
//               padding: const EdgeInsets.only(right: 20),
//               child: const Icon(Icons.delete, color: Colors.white),
//             ),
//             onDismissed: (_) {
//               setState(() {
//                 widget.billItems.remove(item);

//                 // Reassign serials after removal
//                 for (int i = 0; i < widget.billItems.length; i++) {
//                   widget.billItems[i]["serial"] = i + 1;
//                 }

//                 // Optional: update scannedProductsProvider if needed
//                 ref.read(scannedProductsProvider.notifier).state = [
//                   ...widget.billItems,
//                 ];
//               });

//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text("🗑️ '$name' removed from bill")),
//               );
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: Text(
//                           "$serial. $name",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: isDarkMode ? Colors.white : Colors.black,
//                           ),
//                         ),
//                       ),
//                       Text(
//                         "₹${total.toStringAsFixed(2)}",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green[700],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     "Qty: $qty | Price/unit: ₹$price | GST: $gst | Discount: $discount",
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: isDarkMode ? Colors.white70 : Colors.black54,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//   );

//   Widget _buildBillSummary(bool isDarkMode) {
//     final scannedItems = widget.billItems;

//     double totalFinalAmount = 0.0;
//     int totalQuantity = 0;

//     for (var item in scannedItems) {
//       final price = item["finalPrice"] ?? item["price"] ?? 0.0;
//       final quantity = item["quantity"] ?? 1;
//       totalFinalAmount += (price as double) * (quantity as int);
//       totalQuantity += quantity as int;
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _billSummaryRow("Total Items:", "$totalQuantity"),
//         _billSummaryRow(
//           "Total Amount:",
//           "₹${totalFinalAmount.toStringAsFixed(2)}",
//           isBold: true,
//         ),
//         // _billSummaryRow(
//         //   "GST:",
//         //   "₹${BillData.getTotalGST().toStringAsFixed(2)}",
//         // ),
//         _billSummaryRow(
//           "Net Amount Due:",
//           "₹${totalFinalAmount.toStringAsFixed(2)}",
//           isBold: true,
//         ),
//       ],
//     );
//   }

//   Widget _buildPaymentDetails(bool isDarkMode) {
//     double total = widget.billItems.fold(0, (sum, item) {
//       final p = item["finalPrice"] ?? item["price"] ?? 0.0;
//       final q = item["quantity"] ?? 1;
//       return sum + (p as double) * (q as int);
//     });
//     final balance = total - BillData.amountPaid;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Amount Paid: ₹${BillData.amountPaid.toStringAsFixed(2)}"),
//         Text("Balance: ₹${balance.toStringAsFixed(2)}"),
//         if (_paymentVerified && _billOtp != null)
//           Text("Verification Code: $_billOtp"),
//       ],
//     );
//   }

//   Widget _buildFooterQuote(bool isDarkMode) => Center(
//     child: Column(
//       children: [
//         const SizedBox(height: 10),
//         Text(
//           "💡 \"Shop smart, save more!\" 💡",
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: isDarkMode ? Colors.white70 : Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           BillData.footerMessage,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: isDarkMode ? Colors.white54 : Colors.black54,
//           ),
//         ),
//         const SizedBox(height: 20),
//       ],
//     ),
//   );

//   Widget _billSummaryRow(String label, String value, {bool isBold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               textAlign: TextAlign.end,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//                 color: isBold ? Colors.green[800] : null,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

