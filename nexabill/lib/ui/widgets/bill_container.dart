import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/providers/customer_home_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/screens/customer_home_screen.dart';
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

  Future<void> _loadBillData(WidgetRef ref) async {
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

      // 🔄 Rebuild
      if (mounted) setState(() {});
    } catch (e, st) {
      print("❌ Error in _loadBillData: $e");
      print("📍 StackTrace: $st");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadBillData(ref);
    }
  }

  Future<void> waitForAdminUidAndLoad(WidgetRef ref) async {
    int retries = 0;
    while (retries < 6) {
      final adminUid = ref.read(selectedAdminUidProvider);
      print("⏳ Waiting for admin UID... Attempt $retries: $adminUid");

      if (adminUid != null) {
        print("✅ Admin UID available: $adminUid");
        await _loadBillData(ref);
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));
      retries++;
    }

    print("❌ Admin UID still null after retries.");
  }

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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${item["serial"]}. ${item["name"]}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        "Qty: ${item["quantity"]} | Price/unit: ₹${item["price"]} | GST: ${item["gst"]} | Discount: ${item["discount"]}",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    "₹${(item["price"] as double) * (item["quantity"] as int)}",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
  );

  Widget _buildBillSummary(bool isDarkMode) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _billSummaryRow("Total Items:", "${BillData.getTotalQuantity()}"),
      _billSummaryRow(
        "Total Amount:",
        "₹${BillData.getTotalAmount().toStringAsFixed(2)}",
        isBold: true,
      ),
      _billSummaryRow(
        "GST (5%):",
        "₹${BillData.getTotalGST().toStringAsFixed(2)}",
      ),
      _billSummaryRow(
        "Net Amount Due:",
        "₹${BillData.getNetAmountDue().toStringAsFixed(2)}",
        isBold: true,
      ),
    ],
  );

  Widget _buildPaymentDetails(bool isDarkMode) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _billSummaryRow(
        "Amount Paid:",
        "₹${BillData.amountPaid.toStringAsFixed(2)}",
        isBold: true,
      ),
      _billSummaryRow(
        "Balance Amount:",
        "₹${BillData.getBalanceAmount().toStringAsFixed(2)}",
        isBold: true,
      ),
    ],
  );

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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green[800] : null,
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
// import 'package:nexabill/providers/profile_provider.dart';
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

//   Future<void> _loadBillData(WidgetRef ref) async {
//     try {
//       print("🚀 Starting bill data load...");

//       final customerProfile = await ref.read(profileFutureProvider.future);
//       final adminUidAsync = ref.watch(selectedAdminUidProvider);

//       // ✅ If selectedAdminUidProvider is an AsyncValue<String?>
//       final adminUid = adminUidAsync.asData?.value;
//       print("🆗 selectedAdminUidProvider resolved: $adminUid");

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

//       // ✅ Customer Info
//       BillData.customerName = customerProfile["fullName"] ?? "";
//       BillData.customerMobile = customerProfile["phoneNumber"] ?? "";
//       BillData.cashier = ""; // blank

//       // ✅ Admin Mart Info
//       final martAddress = adminProfile["martAddress"] ?? "";
//       final martState = adminProfile["martState"] ?? "";
//       BillData.martName = adminProfile["martName"] ?? "";
//       BillData.martAddress = "$martAddress, $martState, India";
//       BillData.martContact = adminProfile["martContact"] ?? "";
//       BillData.martGSTIN = adminProfile["martGstin"] ?? "";
//       BillData.martCIN = adminProfile["martCin"] ?? "";

//       // ✅ Date & Session
//       final now = DateTime.now();
//       BillData.billDate = DateFormat('dd-MM-yyyy').format(now);
//       BillData.session = DateFormat('hh:mm a').format(now);

//       // ✅ Static Counter No
//       BillData.counterNo = "Counter No:";

//       // ✅ Generate bill number
//       final billSnap =
//           await FirebaseFirestore.instance
//               .collection("bills")
//               .doc(adminUid)
//               .collection("all_bills")
//               .get();

//       final nextNo = billSnap.docs.length + 1;
//       BillData.billNo = "BILL#$nextNo";

//       print("✅ Bill generated: ${BillData.billNo}");
//     } catch (e, st) {
//       print("❌ Error in _loadBillData: $e");
//       print("📍 StackTrace: $st");
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_initialized) {
//       _initialized = true;
//       _loadBillData(ref);
//     }
//   }

//   Future<void> waitForAdminUidAndLoad(WidgetRef ref) async {
//     int retries = 0;
//     while (retries < 6) {
//       final adminUid = ref.read(selectedAdminUidProvider);
//       print("⏳ Waiting for admin UID... Attempt $retries: $adminUid");

//       if (adminUid != null) {
//         print("✅ Admin UID available: $adminUid");
//         await _loadBillData(ref);
//         return;
//       }

//       await Future.delayed(const Duration(milliseconds: 300));
//       retries++;
//     }

//     print("❌ Admin UID still null after retries.");
//   }

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
//     // Parse the session time into DateTime
//     final time = DateFormat('hh:mm a').parse(BillData.session);
//     final hour = time.hour;

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
//           "${BillData.customerName}",
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           "${BillData.customerMobile}",
//           style: const TextStyle(fontSize: 15),
//         ),
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
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 6),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "${item["serial"]}. ${item["name"]}",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isDarkMode ? Colors.white : Colors.black,
//                         ),
//                       ),
//                       Text(
//                         "Qty: ${item["quantity"]} | Price/unit: ₹${item["price"]} | GST: ${item["gst"]} | Discount: ${item["discount"]}",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: isDarkMode ? Colors.white70 : Colors.black54,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     "₹${(item["price"] as double) * (item["quantity"] as int)}",
//                     textAlign: TextAlign.right,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green[700],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
//   );

//   Widget _buildBillSummary(bool isDarkMode) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       _billSummaryRow("Total Items:", "${BillData.getTotalQuantity()}"),
//       _billSummaryRow(
//         "Total Amount:",
//         "₹${BillData.getTotalAmount().toStringAsFixed(2)}",
//         isBold: true,
//       ),
//       _billSummaryRow(
//         "GST (5%):",
//         "₹${BillData.getTotalGST().toStringAsFixed(2)}",
//       ),
//       _billSummaryRow(
//         "Net Amount Due:",
//         "₹${BillData.getNetAmountDue().toStringAsFixed(2)}",
//         isBold: true,
//       ),
//     ],
//   );

//   Widget _buildPaymentDetails(bool isDarkMode) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       _billSummaryRow(
//         "Amount Paid:",
//         "₹${BillData.amountPaid.toStringAsFixed(2)}",
//         isBold: true,
//       ),
//       _billSummaryRow(
//         "Balance Amount:",
//         "₹${BillData.getBalanceAmount().toStringAsFixed(2)}",
//         isBold: true,
//       ),
//     ],
//   );

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
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//               color: isBold ? Colors.green[800] : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
