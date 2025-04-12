import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

final adminProductsProvider =
    ChangeNotifierProvider.autoDispose<AdminProductsProvider>((ref) {
      final provider = AdminProductsProvider();
      provider.clearFields();
      provider.fetchProductsFromFirestore();
      return provider;
    });

class ProductModel {
  final String name;
  final String price;
  final String quantity;
  final String gst;
  final String discount;
  final String qrCode;

  ProductModel({
    required this.name,
    required this.price,
    required this.quantity,
    required this.gst,
    required this.discount,
    required this.qrCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'gst': gst,
      'discount': discount,
      'qrCode': qrCode,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      quantity: map['quantity'] ?? '',
      gst: map['gst'] ?? '',
      discount: map['discount'] ?? '',
      qrCode: map['qrCode'] ?? '',
    );
  }
}

class AdminProductsProvider extends ChangeNotifier {
  final List<ProductModel> _products = [];
  List<ProductModel> get products => List.unmodifiable(_products);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  String? _generatedQRData;
  String? get generatedQRData => _generatedQRData;

  bool allFieldsFilled = false;

  String _martName = "";
  String get martName => _martName;

  Future<void> fetchMartName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && doc.data()!.containsKey('martName')) {
        _martName = doc['martName'] ?? "";
        debugPrint("✅ Mart Name Fetched: $_martName");
        updateQRData(
          name: nameController.text.trim(),
          price: priceController.text.trim(),
          quantity: quantityController.text.trim(),
          gst: gstController.text.trim(),
          discount: discountController.text.trim(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch mart name: $e");
    }
  }

  Future<void> fetchProductsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists && doc.data()!.containsKey('productList')) {
        final productMap = doc['productList'] as Map<String, dynamic>;
        _products.clear();
        productMap.forEach((_, item) {
          if (item is Map<String, dynamic>) {
            _products.add(ProductModel.fromMap(item));
          }
        });
        notifyListeners();
        debugPrint("✅ Products Fetched: ${_products.length}");
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch products from Firestore: $e");
    }
  }

  void onInputChange(WidgetRef ref) {
    updateQRData(
      name: nameController.text.trim(),
      price: priceController.text.trim(),
      quantity: quantityController.text.trim(),
      gst: gstController.text.trim(),
      discount: discountController.text.trim(),
    );
  }

  void updateQRData({
    required String name,
    required String price,
    required String quantity,
    required String gst,
    required String discount,
  }) {
    allFieldsFilled =
        name.isNotEmpty &&
        price.isNotEmpty &&
        quantity.isNotEmpty &&
        gst.isNotEmpty &&
        discount.isNotEmpty;

    if (allFieldsFilled) {
      _generatedQRData = '''
Product: $name
Price: ₹$price
Qty: $quantity
GST: $gst%
Discount: $discount%
$_martName Price: ₹${calculateDiscountedPrice()}
''';
    } else {
      _generatedQRData = null;
    }
    notifyListeners();
  }

  String calculateDiscountedPrice() {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final discount = double.tryParse(discountController.text.trim()) ?? 0;
    final discounted = price - (price * discount / 100);
    return discounted.toStringAsFixed(2);
  }

  Future<void> saveProduct(WidgetRef ref, BuildContext context) async {
    final name = nameController.text.trim();
    final price = priceController.text.trim();
    final quantity = quantityController.text.trim();
    final gst = gstController.text.trim();
    final discount = discountController.text.trim();
    final qrCode = _generatedQRData;

    if (qrCode == null) return;

    final product = ProductModel(
      name: name,
      price: price,
      quantity: quantity,
      gst: gst,
      discount: discount,
      qrCode: qrCode,
    );

    await addProductToFirestore(product);

    clearFields();
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> addProductToFirestore(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await docRef.set({
        'productList': {product.name: product.toMap()},
      }, SetOptions(merge: true));

      _products.add(product);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Failed to add product to Firestore: $e");
    }
  }

  Future<void> downloadQrCard(GlobalKey globalKey, BuildContext context) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        debugPrint("❌ Storage permission not granted");
        return;
      }

      final boundary =
          globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint("❌ RepaintBoundary not found");
        return;
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        debugPrint("❌ PNG bytes were null");
        return;
      }

      final result = await SaverGallery.saveImage(
        pngBytes,
        quality: 100,
        fileName: "product_qr_${DateTime.now().millisecondsSinceEpoch}",
        androidRelativePath: "Pictures/NexaBill/Products",
        skipIfExists: false,
      );

      debugPrint("✅ Saved using saver_gallery: $result");

      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.removeCurrentSnackBar(); // 🔄 Dismiss old one
        messenger.showSnackBar(
          const SnackBar(
            content: Text("✅ QR saved to Gallery"),
            duration: Duration(seconds: 2), // Optional: shorter duration
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Download QR failed: $e");
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.photos.request().isGranted) return true;
      if (await Permission.manageExternalStorage.request().isGranted)
        return true;
    }
    return false;
  }

  void deleteProduct(String name) {
    _products.removeWhere((p) => p.name == name);
    notifyListeners();
  }

  void clearFields() {
    nameController.clear();
    priceController.clear();
    quantityController.clear();
    gstController.clear();
    discountController.clear();
    _generatedQRData = null;
    allFieldsFilled = false;
    notifyListeners();
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// final adminProductsProvider =
//     ChangeNotifierProvider.autoDispose<AdminProductsProvider>((ref) {
//       final provider = AdminProductsProvider();
//       provider.clearFields();
//       provider.fetchProductsFromFirestore();
//       return provider;
//     });

// class ProductModel {
//   final String name;
//   final String price;
//   final String quantity;
//   final String gst;
//   final String discount;
//   final String qrCode;

//   ProductModel({
//     required this.name,
//     required this.price,
//     required this.quantity,
//     required this.gst,
//     required this.discount,
//     required this.qrCode,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'price': price,
//       'quantity': quantity,
//       'gst': gst,
//       'discount': discount,
//       'qrCode': qrCode,
//     };
//   }

//   factory ProductModel.fromMap(Map<String, dynamic> map) {
//     return ProductModel(
//       name: map['name'] ?? '',
//       price: map['price'] ?? '',
//       quantity: map['quantity'] ?? '',
//       gst: map['gst'] ?? '',
//       discount: map['discount'] ?? '',
//       qrCode: map['qrCode'] ?? '',
//     );
//   }
// }

// class AdminProductsProvider extends ChangeNotifier {
//   final List<ProductModel> _products = [];
//   List<ProductModel> get products => List.unmodifiable(_products);

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController quantityController = TextEditingController();
//   final TextEditingController gstController = TextEditingController();
//   final TextEditingController discountController = TextEditingController();

//   String? _generatedQRData;
//   String? get generatedQRData => _generatedQRData;

//   bool allFieldsFilled = false;

//   String _martName = "";
//   String get martName => _martName;

//   Future<void> fetchMartName() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final doc =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(user.uid)
//               .get();
//       if (doc.exists && doc.data()!.containsKey('martName')) {
//         _martName = doc['martName'] ?? "";
//         debugPrint("✅ Mart Name Fetched: $_martName");
//         updateQRData(
//           name: nameController.text.trim(),
//           price: priceController.text.trim(),
//           quantity: quantityController.text.trim(),
//           gst: gstController.text.trim(),
//           discount: discountController.text.trim(),
//         );
//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint("❌ Failed to fetch mart name: $e");
//     }
//   }

//   Future<void> fetchProductsFromFirestore() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final doc =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(user.uid)
//               .get();

//       if (doc.exists && doc.data()!.containsKey('productList')) {
//         final productMap = doc['productList'] as Map<String, dynamic>;
//         _products.clear();
//         productMap.forEach((_, item) {
//           if (item is Map<String, dynamic>) {
//             _products.add(ProductModel.fromMap(item));
//           }
//         });
//         notifyListeners();
//         debugPrint("✅ Products Fetched: ${_products.length}");
//       }
//     } catch (e) {
//       debugPrint("❌ Failed to fetch products from Firestore: $e");
//     }
//   }

//   void onInputChange(WidgetRef ref) {
//     updateQRData(
//       name: nameController.text.trim(),
//       price: priceController.text.trim(),
//       quantity: quantityController.text.trim(),
//       gst: gstController.text.trim(),
//       discount: discountController.text.trim(),
//     );
//   }

//   void updateQRData({
//     required String name,
//     required String price,
//     required String quantity,
//     required String gst,
//     required String discount,
//   }) {
//     allFieldsFilled =
//         name.isNotEmpty &&
//         price.isNotEmpty &&
//         quantity.isNotEmpty &&
//         gst.isNotEmpty &&
//         discount.isNotEmpty;

//     if (allFieldsFilled) {
//       _generatedQRData = '''
// Product: $name
// Price: ₹$price
// Qty: $quantity
// GST: $gst%
// Discount: $discount%
// $_martName Price: ₹${calculateDiscountedPrice()}
// ''';
//     } else {
//       _generatedQRData = null;
//     }
//     notifyListeners();
//   }

//   String calculateDiscountedPrice() {
//     final price = double.tryParse(priceController.text.trim()) ?? 0;
//     final discount = double.tryParse(discountController.text.trim()) ?? 0;
//     final discounted = price - (price * discount / 100);
//     return discounted.toStringAsFixed(2);
//   }

//   Future<void> saveProduct(WidgetRef ref, BuildContext context) async {
//     final name = nameController.text.trim();
//     final price = priceController.text.trim();
//     final quantity = quantityController.text.trim();
//     final gst = gstController.text.trim();
//     final discount = discountController.text.trim();
//     final qrCode = _generatedQRData;

//     if (qrCode == null) return;

//     final product = ProductModel(
//       name: name,
//       price: price,
//       quantity: quantity,
//       gst: gst,
//       discount: discount,
//       qrCode: qrCode,
//     );

//     await addProductToFirestore(product);

//     clearFields();
//     if (context.mounted) Navigator.pop(context);
//   }

//   Future<void> addProductToFirestore(ProductModel product) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final docRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid);
//       await docRef.set({
//         'productList': {product.name: product.toMap()},
//       }, SetOptions(merge: true));

//       _products.add(product);
//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Failed to add product to Firestore: $e");
//     }
//   }

//   void deleteProduct(String name) {
//     _products.removeWhere((p) => p.name == name);
//     notifyListeners();
//   }

//   void clearFields() {
//     nameController.clear();
//     priceController.clear();
//     quantityController.clear();
//     gstController.clear();
//     discountController.clear();
//     _generatedQRData = null;
//     allFieldsFilled = false;
//     notifyListeners();
//   }
// }

