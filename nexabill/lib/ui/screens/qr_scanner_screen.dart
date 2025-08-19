import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:nexabill/core/theme.dart';
import 'customer_home_screen.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedCode;
  int quantity = 0;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scannedCode != scanData.code && scanData.code != null) {
        setState(() {
          scannedCode = scanData.code!;
          quantity = 1;
        });
        controller.pauseCamera();
      }
    });
  }

  void _handleDecrement() {
    setState(() {
      quantity--;
      if (quantity < 1) {
        scannedCode = null;
        controller?.resumeCamera();
      }
    });
  }

  // Future<void> _handleAccept() async {
  //   if (scannedCode == null || quantity < 1) return;

  //   // 🧠 Parse multi-line QR data
  //   final lines = scannedCode!.split('\n').map((e) => e.trim()).toList();
  //   final nameLine = lines.firstWhere(
  //     (l) => l.startsWith("Product:"),
  //     orElse: () => "",
  //   );
  //   final productName = nameLine.replaceFirst("Product:", "").trim();

  //   if (productName.isEmpty) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("❌ Invalid QR code format")));
  //     controller?.resumeCamera();
  //     return;
  //   }

  //   final adminUid = ref.read(selectedAdminUidProvider);
  //   if (adminUid == null) return;

  //   try {
  //     final adminDoc =
  //         await FirebaseFirestore.instance
  //             .collection("users")
  //             .doc(adminUid)
  //             .get();

  //     final productList =
  //         adminDoc.data()?["productList"] as Map<String, dynamic>?;

  //     if (productList == null || !productList.containsKey(productName)) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("❌ Product '$productName' not found.")),
  //       );
  //       controller?.resumeCamera();
  //       return;
  //     }

  //     final product = productList[productName];
  //     final productItem = {
  //       "serial": ref.read(scannedProductsProvider).length + 1,
  //       "name": product["name"] ?? "",
  //       "price": double.tryParse(product["price"] ?? "0") ?? 0.0,
  //       "quantity": quantity,
  //       "gst": product["gst"] ?? "0%",
  //       "discount": product["discount"] ?? "0%",
  //     };

  //     final updatedList = [...ref.read(scannedProductsProvider), productItem];
  //     ref.read(scannedProductsProvider.notifier).state = updatedList;

  //     Navigator.pop(context); // ✅ Close scanner
  //   } catch (e) {
  //     print("❌ Error scanning product: $e");
  //   }
  // }

  Future<void> _handleAccept() async {
    if (scannedCode == null || quantity < 1) return;

    // 🧠 Parse QR multi-line
    final lines = scannedCode!.split('\n').map((e) => e.trim()).toList();

    final nameLine = lines.firstWhere(
      (l) => l.startsWith("Product:"),
      orElse: () => "",
    );
    final smartPriceLine = lines.firstWhere(
      (l) => l.contains("SMart Price: ₹"),
      orElse: () => "",
    );

    final productName = nameLine.replaceFirst("Product:", "").trim();

    // ✅ Extract SMart Price from QR string
    final martPriceMatch = RegExp(
      r'SMart Price: ₹(\d+(\.\d+)?)',
    ).firstMatch(smartPriceLine);
    final martPrice = double.tryParse(martPriceMatch?.group(1) ?? "0") ?? 0.0;

    if (productName.isEmpty || martPrice == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Invalid QR code format or SMart Price missing"),
        ),
      );
      controller?.resumeCamera();
      return;
    }

    final adminUid = ref.read(selectedAdminUidProvider);
    if (adminUid == null) return;

    try {
      final adminDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(adminUid)
              .get();

      final productList =
          adminDoc.data()?["productList"] as Map<String, dynamic>?;

      if (productList == null || !productList.containsKey(productName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Product '$productName' not found.")),
        );
        controller?.resumeCamera();
        return;
      }

      final product = productList[productName];

      final productItem = {
        "serial": ref.read(scannedProductsProvider).length + 1,
        "name": product["name"] ?? "",
        "price":
            double.tryParse(product["price"] ?? "0") ?? 0.0, // ✅ unit price
        "quantity": quantity,
        "gst": product["gst"] ?? "0%",
        "discount": product["discount"] ?? "0%",
        "finalPrice": martPrice, // ✅ discounted price per unit
      };

      final updatedList = [...ref.read(scannedProductsProvider), productItem];
      ref.read(scannedProductsProvider.notifier).state = updatedList;

      // Navigator.pop(context); // ✅ Close scanner
      await Future.delayed(const Duration(milliseconds: 300));
if (mounted) Navigator.pop(context);

    } catch (e) {
      print("❌ Error scanning product: $e");
    }
  }

  Widget buildQuantityBox() {
    if (quantity < 1 || scannedCode == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.whiteColor,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: AppTheme.whiteColor),
                  onPressed: _handleDecrement,
                ),
                Text(
                  "$quantity",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whiteColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.whiteColor),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 20),
              CircleAvatar(
                backgroundColor: Colors.green.shade600,
                child: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _handleAccept,
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.blueAccent,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: MediaQuery.of(context).size.width * 0.7,
                ),
              ),
            ),
          ),
          buildQuantityBox(),
        ],
      ),
    );
  }
}
