import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:nexabill/core/theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
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
      if (scannedCode != scanData.code) {
        setState(() {
          scannedCode = scanData.code;
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
        controller?.resumeCamera(); // ✅ Restart scanner
      }
    });
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
          // 🔵 Primary container with full row (+ | quantity | -)
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

          // ✅ Accept and ❌ Cancel
          Row(
            children: [
              const SizedBox(width: 20),
              CircleAvatar(
                backgroundColor: Colors.green.shade600,
                child: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: () {
                    // ✅ Accept logic
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
