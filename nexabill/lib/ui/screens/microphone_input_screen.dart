import 'package:flutter/material.dart';
import 'package:nexabill/ui/screens/customer_home_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/customer_home_provider.dart';
import 'package:nexabill/core/theme.dart';

class MicrophoneInputScreen extends ConsumerStatefulWidget {
  const MicrophoneInputScreen({super.key});

  @override
  ConsumerState<MicrophoneInputScreen> createState() =>
      _MicrophoneInputScreenState();
}

class _MicrophoneInputScreenState extends ConsumerState<MicrophoneInputScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = "";
  int _quantity = 1;

  final _gemini = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: 'AIzaSyD4Zs7RkPSNgbJnOSqzhtV9uI2q_LPkaSE',
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startListening();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('🎙️ Mic Status: $status');
        if (status == 'done') {
          debugPrint("🎧 Heard: $_spokenText");
        }
      },
      onError: (error) => debugPrint('❌ Mic Error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() => _spokenText = result.recognizedWords);
          debugPrint("🎧 Heard: ${result.recognizedWords}");
        },
        localeId: 'en_IN',
      );
    }
  }

  Future<void> _handleAccept() async {
    if (_spokenText.isEmpty) return;

    debugPrint("🔍 Sending to Gemini: '$_spokenText'");
    final prompt =
        "Extract only the product ID (PID) number from the following voice input: '$_spokenText'. If product name is available, include it. Return in format: name - pid or just pid if name is unclear.";

    try {
      final response = await _gemini.generateContent([Content.text(prompt)]);
      final reply = response.text?.trim() ?? "";

      debugPrint("🤖 Gemini Reply: $reply");

      String productName = "";
      String productId = "";

      if (reply.contains('-')) {
        final parts = reply.split('-');
        productName = parts[0].trim();
        productId = parts[1].trim();
      } else {
        productId = reply.trim();
      }

      final selectedAdminUid = ref.read(selectedAdminUidProvider);
      if (selectedAdminUid == null) return;

      final adminDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(selectedAdminUid)
              .get();
      final productList =
          adminDoc.data()?['productList'] as Map<String, dynamic>?;

      if (productList == null) {
        debugPrint("❌ Admin product list is empty or missing.");
        return;
      }

      final matchedEntry = productList.entries.firstWhere(
        (entry) => (entry.value["productId"]?.toString() ?? "") == productId,
        orElse: () => MapEntry("", {}),
      );

      if (matchedEntry.value.isEmpty) {
        debugPrint("❌ Product with PID '$productId' not found.");
        return;
      }

      final product = matchedEntry.value;
      debugPrint("📦 Product Fetched from Firestore: $product");

      final qrCode = product["qrCode"] ?? "";
      final smartPriceMatch = RegExp(
        r'SMart Price: ₹(\d+(\.\d+)?)',
      ).firstMatch(qrCode);
      final smartPrice =
          double.tryParse(smartPriceMatch?.group(1) ?? "") ??
          double.tryParse(product["price"] ?? "0") ??
          0.0;

      final productItem = {
        "serial": ref.read(scannedProductsProvider).length + 1,
        "name": product["name"] ?? productName,
        "productId": productId,
        "price": smartPrice,
        "quantity": _quantity,
        "gst": product["gst"] ?? "0%",
        "discount": product["discount"] ?? "0%",
        "finalPrice": smartPrice,
        "variant": product["variant"] ?? "",
      };

      final updatedList = [...ref.read(scannedProductsProvider), productItem];
      ref.read(scannedProductsProvider.notifier).state = updatedList;

      debugPrint(
        "🛒 Confirmed: '${product["name"]} ($productId)' with quantity $_quantity",
      );
    } catch (e) {
      debugPrint("❌ Gemini or Firestore error: $e");
    }

    Navigator.pop(context);
  }

  void _handleAdd() => setState(() => _quantity++);
  void _handleSubtract() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _handleCancel() => Navigator.pop(context);

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Icon(
            _isListening ? Icons.mic : Icons.mic_off,
            color: Colors.redAccent,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            _spokenText.isEmpty ? "Listening..." : _spokenText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: AppTheme.whiteColor,
                        ),
                        onPressed: _handleSubtract,
                      ),
                      Text(
                        "$_quantity",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.whiteColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppTheme.whiteColor),
                        onPressed: _handleAdd,
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
                        onPressed: _handleCancel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
