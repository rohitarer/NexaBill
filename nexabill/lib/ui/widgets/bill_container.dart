import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_cashier_provider.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/providers/customer_home_provider.dart';
import 'package:nexabill/providers/otp_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/screens/customer_home_screen.dart';
import 'package:nexabill/ui/widgets/bill_otp_handler.dart';
import 'package:nexabill/ui/widgets/cahier_info_handler.dart';
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
  bool _waitingForOtp = false;
  bool _hasPopped = false;
  bool _hasResetAfterSeal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBillData());
  }

  void _resetPaymentState() {
    BillData.amountPaid = 0.0;
    _billOtp = null;
    _paymentVerified = false;
    _waitingForOtp = true;
    if (mounted) setState(() {});
  }

  // Future<void> _loadBillData() async {
  //   try {
  //     if (!mounted) return;
  //     print("🚀 Starting bill data load...");

  //     final billVerificationNotifier = ref.read(
  //       billVerificationProvider.notifier,
  //     );
  //     final profileAsync = ref.read(profileFutureProvider);
  //     final selectedAdminUid = ref.read(selectedAdminUidProvider);
  //     final state = ref.read(billVerificationProvider);
  //     final currentUser = FirebaseAuth.instance.currentUser;

  //     final userId = currentUser?.uid ?? state.userId ?? "";
  //     BillData.customerId = userId;
  //     BillData.adminUid = selectedAdminUid ?? "";

  //     // 🔁 If bill already exists (stream listen for updates)
  //     if (BillData.customerId.isNotEmpty && BillData.billNo.isNotEmpty) {
  //       debugPrint(
  //         "📡 Subscribing to bill stream for ${BillData.customerId} → ${BillData.billNo}",
  //       );

  //       final billStream =
  //           FirebaseFirestore.instance
  //               .collection('users')
  //               .doc(BillData.customerId)
  //               .collection('my_bills')
  //               .doc(BillData.billNo)
  //               .snapshots();

  //       billStream.listen((billSnapshot) {
  //         if (!billSnapshot.exists || !mounted) return;

  //         final data = billSnapshot.data()!;
  //         print("📦 Firestore Bill Data Keys: ${data.keys}");

  //         final rawProducts = data['products'];
  //         if (rawProducts != null && rawProducts is Map) {
  //           final productsMap = Map<String, dynamic>.from(rawProducts);
  //           BillData.products =
  //               productsMap.entries
  //                   .map((e) => Map<String, dynamic>.from(e.value))
  //                   .toList();

  //           print("🛍️ Loaded ${BillData.products.length} products:");
  //           for (var p in BillData.products) {
  //             print("  • ${p["name"]} x${p["quantity"]} @ ₹${p["finalPrice"]}");
  //           }
  //         } else {
  //           print("⚠️ No valid 'products' map found.");
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
  //         BillData.cashier = data['cashier'] ?? '';
  //         BillData.counterNo = data['counterNo'] ?? '';
  //         BillData.martContact = data['martContact'] ?? '';
  //         BillData.martGSTIN = data['martGSTIN'] ?? '';
  //         BillData.martCIN = data['martCIN'] ?? '';
  //         BillData.sealStatus = data['sealStatus'] ?? 'none';

  //         final seal = BillSealStatusExtension.fromString(BillData.sealStatus);
  //         billVerificationNotifier.setSealStatus(seal);

  //         if (mounted) {
  //           print("🧩 setState() triggered after bill stream update.");
  //           setState(() {});
  //         }
  //       });
  //     } else {
  //       // 🔄 Generate new bill if none exists
  //       if (BillData.billNo.isEmpty) {
  //         final customerProfile = await ref.read(profileFutureProvider.future);
  //         final adminUid = selectedAdminUid;

  //         if (adminUid == null || customerProfile.isEmpty) {
  //           print("⚠️ Missing admin UID or customer profile.");
  //           return;
  //         }

  //         final adminDoc =
  //             await FirebaseFirestore.instance
  //                 .collection("users")
  //                 .doc(adminUid)
  //                 .get();
  //         final adminProfile = adminDoc.data();
  //         if (adminProfile == null) {
  //           print("❌ Admin profile not found for UID: $adminUid");
  //           return;
  //         }

  //         print("🧠 Fetched Admin UID: $adminUid for bill creation");

  //         // ✅ Reset old bill data (but retain customerId)
  //         final previousCustomerId = BillData.customerId;

  //         BillData.products = [];
  //         BillData.amountPaid = 0.0;
  //         BillData.otp = "";
  //         BillData.billDate = "";
  //         BillData.session = "";
  //         BillData.sealStatus = "";
  //         BillData.counterNo = "";
  //         BillData.billNo = "";

  //         BillData.customerId = previousCustomerId; // ✅ Retain after reset
  //         BillData.adminUid = adminUid;
  //         BillData.customerName = customerProfile["fullName"] ?? "";
  //         BillData.customerMobile = customerProfile["phoneNumber"] ?? "";
  //         BillData.cashier = "";

  //         final martAddress = adminProfile["martAddress"] ?? "";
  //         final martState = adminProfile["martState"] ?? "";

  //         BillData.martName = adminProfile["martName"] ?? "";
  //         BillData.martAddress = "$martAddress, $martState, India";
  //         BillData.martContact = adminProfile["martContact"] ?? "";
  //         BillData.martGSTIN = adminProfile["martGstin"] ?? "";
  //         BillData.martCIN = adminProfile["martCin"] ?? "";

  //         final now = DateTime.now();
  //         BillData.billDate = DateFormat('dd-MM-yyyy').format(now);
  //         BillData.session = DateFormat('hh:mm a').format(now);

  //         // ✅ Firestore-safe transaction to avoid duplicate billNo
  //         final adminRef = FirebaseFirestore.instance
  //             .collection("users")
  //             .doc(adminUid);

  //         await FirebaseFirestore.instance.runTransaction((transaction) async {
  //           final adminSnap = await transaction.get(adminRef);
  //           final currentCount =
  //               (adminSnap.data()?['lastBillNumber'] ?? 0) as int;
  //           final newCount = currentCount + 1;

  //           transaction.update(adminRef, {'lastBillNumber': newCount});
  //           BillData.billNo = "BILL#$newCount";
  //         });

  //         print("✅ Generated new Bill No: ${BillData.billNo}");
  //       }
  //     }

  //     if (mounted) {
  //       print("✅ Final setState() call after full execution.");
  //       setState(() {});
  //     }
  //   } catch (e, st) {
  //     print("❌ Error in _loadBillData: $e");
  //     print("📍 StackTrace: $st");
  //   }
  // }

  Future<void> _loadBillData() async {
    try {
      if (!mounted) return;
      print("🚀 Starting bill data load...");

      final billVerificationNotifier = ref.read(
        billVerificationProvider.notifier,
      );
      final profileAsync = ref.read(profileFutureProvider);
      final selectedAdminUid = ref.read(selectedAdminUidProvider);
      final state = ref.read(billVerificationProvider);
      final currentUser = FirebaseAuth.instance.currentUser;

      final userId = currentUser?.uid ?? state.userId ?? "";
      BillData.customerId = userId;
      BillData.adminUid = selectedAdminUid ?? "";

      if (BillData.customerId.isNotEmpty && BillData.billNo.isNotEmpty) {
        debugPrint(
          "📡 Subscribing to bill stream for ${BillData.customerId} → \${BillData.billNo}",
        );

        final billStream =
            FirebaseFirestore.instance
                .collection('users')
                .doc(BillData.customerId)
                .collection('my_bills')
                .doc(BillData.billNo)
                .snapshots();

        billStream.listen((billSnapshot) {
          if (!billSnapshot.exists || !mounted) return;

          final data = billSnapshot.data()!;
          print("📦 Firestore Bill Data Keys: ${data.keys}");

          final rawProducts = data['products'];
          if (rawProducts != null && rawProducts is Map) {
            final productsMap = Map<String, dynamic>.from(rawProducts);
            BillData.products =
                productsMap.entries
                    .map((e) => Map<String, dynamic>.from(e.value))
                    .toList();

            print("🛍️ Loaded ${BillData.products.length} products:");
            for (var p in BillData.products) {
              print("  • ${p["name"]} x${p["quantity"]} @ ₹${p["finalPrice"]}");
            }
          } else {
            print("⚠️ No valid 'products' map found.");
            BillData.products = [];
          }

          BillData.customerName = data['customerName'] ?? '';
          BillData.customerMobile = data['customerMobile'] ?? '';
          BillData.martName = data['martName'] ?? '';
          BillData.martAddress = data['martAddress'] ?? '';
          BillData.amountPaid = (data['amountPaid'] ?? 0).toDouble();
          BillData.otp = data['otp'] ?? '';
          BillData.billDate = data['billDate'] ?? '';
          BillData.session = data['session'] ?? '';
          BillData.cashier = data['cashier'] ?? '';
          BillData.counterNo = data['counterNo'] ?? '';
          BillData.martContact = data['martContact'] ?? '';
          BillData.martGSTIN = data['martGSTIN'] ?? '';
          BillData.martCIN = data['martCIN'] ?? '';
          BillData.sealStatus = data['sealStatus'] ?? 'none';

          final seal = BillSealStatusExtension.fromString(BillData.sealStatus);
          billVerificationNotifier.setSealStatus(seal);

          if (mounted) {
            print("🧩 setState() triggered after bill stream update.");
            setState(() {});
          }
        });
      } else if (BillData.billNo.isEmpty) {
        final customerProfile = await ref.read(profileFutureProvider.future);
        final adminUid = selectedAdminUid;

        if (adminUid == null || customerProfile.isEmpty) {
          print("⚠️ Missing admin UID or customer profile.");
          return;
        }

        final adminDoc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(adminUid)
                .get();
        final adminProfile = adminDoc.data();
        if (adminProfile == null) {
          print("❌ Admin profile not found for UID: \$adminUid");
          return;
        }

        print("🧠 Fetched Admin UID: $adminUid for bill creation");

        final previousCustomerId = BillData.customerId;

        BillData.products = [];
        BillData.amountPaid = 0.0;
        BillData.otp = "";
        BillData.billDate = "";
        BillData.session = "";
        BillData.sealStatus = "";
        BillData.counterNo = "";
        BillData.billNo = "";

        BillData.customerId = previousCustomerId;
        BillData.adminUid = adminUid;
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

        final adminRef = FirebaseFirestore.instance
            .collection("users")
            .doc(adminUid);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final adminSnap = await transaction.get(adminRef);
          final currentCount =
              (adminSnap.data()?['lastBillNumber'] ?? 0) as int;
          final newCount = currentCount + 1;

          transaction.update(adminRef, {'lastBillNumber': newCount});
          BillData.billNo = "BILL#$newCount";
        });

        print("✅ Generated new Bill No: ${BillData.billNo}");
      }

      if (mounted) {
        print("✅ Final setState() call after full execution.");
        setState(() {});
      }
    } catch (e, st) {
      print("❌ Error in _loadBillData: $e");
      print("📍 StackTrace: $st");
    }
  }

  Future<void> saveBillToFirestore({
    required String? otp,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not logged in");
      if (otp == null || otp.trim().isEmpty) {
        debugPrint("⚠️ OTP is null or empty. Cannot save.");
        return;
      }

      // ✅ Ensure customer ID is present
      if (BillData.customerId.trim().isEmpty) {
        BillData.customerId = currentUser.uid;
      }

      final String customerUid = BillData.customerId;
      final String cashierUid = currentUser.uid;
      final String billNo = BillData.billNo;
      final String adminUid = BillData.adminUid;
      final timestamp = DateTime.now().toIso8601String();

      if (customerUid.trim().isEmpty || billNo.trim().isEmpty) {
        debugPrint("❌ Missing customerUid or billNo, aborting save.");
        return;
      }

      // 🔁 Convert product list into Firestore map
      final Map<String, dynamic> productMap = {
        for (var item in products)
          item['name']: Map<String, dynamic>.from(item),
      };

      // ✅ Ensure billDate and session
      if (BillData.billDate.isEmpty || BillData.session.isEmpty) {
        final now = DateTime.now();
        BillData.billDate = DateFormat('dd-MM-yyyy').format(now);
        BillData.session = DateFormat('hh:mm a').format(now);
      }

      // 🔄 Fetch missing mart info
      if (BillData.martGSTIN.isEmpty ||
          BillData.martCIN.isEmpty ||
          BillData.martContact.isEmpty) {
        final adminDoc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(adminUid)
                .get();
        final adminData = adminDoc.data();
        if (adminData != null) {
          BillData.martGSTIN = adminData["martGstin"] ?? "";
          BillData.martCIN = adminData["martCin"] ?? "";
          BillData.martContact = adminData["martContact"] ?? "";
        }
      }

      // 🧾 Final bill data map
      final billData = {
        "products": productMap,
        "amountPaid": BillData.amountPaid,
        "timestamp": timestamp,
        "otp": otp,
        "billNo": billNo,
        "customerName": BillData.customerName,
        "customerMobile": BillData.customerMobile,
        "martName": BillData.martName,
        "martAddress": BillData.martAddress,
        "billDate": BillData.billDate,
        "session": BillData.session,
        "counterNo": BillData.counterNo,
        "martContact": BillData.martContact,
        "martGSTIN": BillData.martGSTIN,
        "martCIN": BillData.martCIN,
        "uid": customerUid,
        "cashier": BillData.cashier,
        "cashierCounter": BillData.counterNo,
        "sealStatus": BillData.sealStatus,
      };

      // ✅ Save bill to Firestore for all roles
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection("users")
          .doc(customerUid)
          .collection("my_bills")
          .doc(billNo)
          .set(billData);
      debugPrint("📥 Bill saved for customer");

      if (cashierUid != customerUid) {
        await firestore
            .collection("users")
            .doc(cashierUid)
            .collection("my_bills")
            .doc(billNo)
            .set(billData);
        debugPrint("📥 Bill saved for cashier");
      }

      if (adminUid.trim().isNotEmpty) {
        await firestore
            .collection("users")
            .doc(adminUid)
            .collection("my_bills")
            .doc(billNo)
            .set(billData);
        debugPrint("📥 Bill saved for admin");
      }

      // ✅ Save OTP to 'otps' collection
      final otpData = {
        "otp": otp,
        "userId": customerUid, // ✅ Ensure this is always present
        "amountPaid": BillData.amountPaid,
        "timestamp": timestamp,
        "expiresAt":
            DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      };

      await firestore.collection("otps").doc(billNo).set(otpData);

      debugPrint("📥 OTP saved: $otp for $billNo, UID: $customerUid");

      // 🔄 Refresh bill state
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadBillData();
    } catch (e, st) {
      debugPrint("❌ Error in saveBillToFirestore: $e");
      debugPrint("📍 StackTrace: $st");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sealStatus = ref.watch(billVerificationProvider).sealStatus;

    if (!BillData.hasResetAfterSeal && sealStatus == BillSealStatus.sealed) {
      BillData.hasResetAfterSeal = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Bill Verified ✅")));
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          ref.read(billVerificationProvider.notifier).reset();
          ref.read(scannedProductsProvider.notifier).state = [];
          ref.read(selectedMartProvider.notifier).state = null;
          ref.read(selectedAdminUidProvider.notifier).state = null;
          BillData.products.clear();
          BillData.billNo = "";
          BillData.sealStatus = "none";
          setState(() {});
        });
      });
    }

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
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
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
                        if (sealStatus == BillSealStatus.sealed ||
                            sealStatus == BillSealStatus.rejected)
                          VerificationStamp(
                            type:
                                sealStatus == BillSealStatus.sealed
                                    ? StampType.verified
                                    : StampType.rejected,
                            martName: BillData.martName,
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
          "📆 ${BillData.billDate}  |  🕒 ${BillData.session}  |  💼 Counter No:${BillData.counterNo}",
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
    // Parse session time
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
      hour = DateTime.now().hour;
    }

    String sessionLabel =
        (hour >= 5 && hour < 12)
            ? "🌅 Morning"
            : (hour >= 12 && hour < 17)
            ? "☀️ Afternoon"
            : (hour >= 17 && hour < 21)
            ? "🌇 Evening"
            : "🌙 Night";

    return FutureBuilder<void>(
      future: CashierInfoHandler.updateCashierAndCounterIfMissing(ref),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🧾 ${BillData.billNo} | 💼 Counter No:${BillData.counterNo}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Text(
            //   "🪑 ${BillData.counterNo}",
            //   style: const TextStyle(fontSize: 15),
            // ),
            Text(
              "${BillData.billDate}  |  🕒 ${BillData.session}  |  Session: $sessionLabel",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 5),
            Text(
              "Customer: ${BillData.customerName}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Mobile: ${BillData.customerMobile}",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 5),
            Text(
              "Cashier: ${BillData.cashier}",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
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

    final netAmountDue = totalFinalAmount - BillData.amountPaid;
    final netDisplayAmount = netAmountDue <= 0 ? 0.0 : netAmountDue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _billSummaryRow("Total Items:", "$totalQuantity"),
        _billSummaryRow(
          "Total Amount:",
          "₹${totalFinalAmount.toStringAsFixed(2)}",
          isBold: true,
        ),
        _billSummaryRow(
          "Net Amount Due:",
          "₹${netDisplayAmount.toStringAsFixed(2)}",
          isBold: true,
        ),
      ],
    );
  }

  // Widget _buildPaymentDetails(bool isDarkMode) {
  //   debugPrint("💰 Building Payment Details");

  //   double total = widget.billItems.fold(0, (sum, item) {
  //     final p = item["finalPrice"] ?? item["price"] ?? 0.0;
  //     final q = item["quantity"] ?? 1;
  //     return sum + (p as double) * (q as int);
  //   });

  //   double balance = total - BillData.amountPaid;
  //   if (balance < 0) balance = 0; // ✅ Prevent negative balance

  //   debugPrint("🔢 Total: ₹$total");
  //   debugPrint("💳 Paid: ₹${BillData.amountPaid}");
  //   debugPrint("🧾 Balance: ₹$balance");

  //   final bool isBillSealed =
  //       BillData.sealStatus == 'sealed' || BillData.sealStatus == 'rejected';
  //   final bool hasOtp = BillData.otp.isNotEmpty;

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _billSummaryRow(
  //         "Amount Paid:",
  //         "₹${BillData.amountPaid.toStringAsFixed(2)}",
  //         isBold: true,
  //       ),
  //       _billSummaryRow(
  //         "Balance Amount:",
  //         "₹${balance.toStringAsFixed(2)}",
  //         isBold: true,
  //       ),

  //       // ✅ Only show OTP input if not sealed and OTP not already added
  //       if (!isBillSealed && !hasOtp)
  //         OtpHandler(
  //           billNo: BillData.billNo,
  //           onOtpReceived: (otp, amount) async {
  //             if (!mounted) return;

  //             setState(() {
  //               _billOtp = otp;
  //               BillData.amountPaid = amount;
  //               _paymentVerified = true;
  //               _waitingForOtp = false;
  //             });

  //             final currentUser = FirebaseAuth.instance.currentUser;
  //             if (currentUser != null) {
  //               BillData.customerId = currentUser.uid;
  //             }

  //             await saveBillToFirestore(
  //               otp: _billOtp,
  //               products: widget.billItems,
  //             );

  //             await Future.delayed(const Duration(milliseconds: 500));

  //             if (!mounted) return;

  //             final localRef = ref;
  //             await _loadBillData();
  //             await CashierInfoHandler.updateCashierAndCounterIfMissing(
  //               localRef,
  //             );

  //             if (mounted) setState(() {});
  //           },
  //         ),

  //       if (hasOtp && !isBillSealed)
  //         Padding(
  //           padding: const EdgeInsets.only(top: 8.0),
  //           child: _billSummaryRow(
  //             "Verification Code:",
  //             BillData.otp.isNotEmpty ? BillData.otp : "(blank)",
  //             isBold: true,
  //           ),
  //         ),
  //     ],
  //   );
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
          onOtpReceived: (otp, amount) async {
            if (!mounted) return;

            setState(() {
              _billOtp = otp;
              BillData.amountPaid = amount;
              _paymentVerified = true;
              _waitingForOtp = false;
            });

            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              BillData.customerId = currentUser.uid;
            }

            await saveBillToFirestore(
              otp: _billOtp,
              products: widget.billItems,
            );

            await Future.delayed(const Duration(milliseconds: 500));

            if (!mounted) return;

            final localRef = ref; // ✅ cache ref safely
            await _loadBillData(); // will internally use localRef if needed
            await CashierInfoHandler.updateCashierAndCounterIfMissing(localRef);

            if (mounted) setState(() {}); // ensure UI updates after async
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
