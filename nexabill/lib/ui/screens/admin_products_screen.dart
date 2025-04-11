import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nexabill/providers/admin_products_provider.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminProductsProvider.notifier).fetchMartName(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = ref.watch(adminProductsProvider.notifier);
    final products = ref.watch(adminProductsProvider).products;
    final martName = ref.watch(adminProductsProvider).martName;

    return Scaffold(
      body:
          products.isEmpty
              ? const Center(
                child: Text(
                  "➕ Add a product to get started",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final price = double.tryParse(product.price) ?? 0;
                  final discount = double.tryParse(product.discount) ?? 0;
                  final discountedPrice = price - (price * discount / 100);

                  final GlobalKey qrCardKey = GlobalKey();

                  return Stack(
                    children: [
                      RepaintBoundary(
                        key: qrCardKey,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  QrImageView(
                                    data: product.qrCode,
                                    version: QrVersions.auto,
                                    size: 100.0,
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Qty: ${product.quantity}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          "MRP: ₹${product.price}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          "$martName Price: ₹${discountedPrice.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          icon: Icon(
                            Icons.download,
                            size: 20,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          onPressed:
                              () =>
                                  controller.downloadQrCard(qrCardKey, context),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}

// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:saver_gallery/saver_gallery.dart';
// import 'package:nexabill/providers/admin_products_provider.dart';

// class AdminProductsScreen extends ConsumerStatefulWidget {
//   const AdminProductsScreen({super.key});

//   @override
//   ConsumerState<AdminProductsScreen> createState() =>
//       _AdminProductsScreenState();
// }

// class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(
//       () => ref.read(adminProductsProvider.notifier).fetchMartName(),
//     );
//   }

//   Future<bool> _requestStoragePermission() async {
//     if (Platform.isAndroid) {
//       if (await Permission.storage.request().isGranted) return true;
//       if (await Permission.photos.request().isGranted) return true;
//       if (await Permission.manageExternalStorage.request().isGranted)
//         return true;
//     }
//     return false;
//   }

//   Future<void> _downloadQrCard(GlobalKey globalKey) async {
//     try {
//       final hasPermission = await _requestStoragePermission();
//       if (!hasPermission) {
//         debugPrint("❌ Storage permission not granted");
//         return;
//       }

//       final boundary =
//           globalKey.currentContext?.findRenderObject()
//               as RenderRepaintBoundary?;
//       if (boundary == null) {
//         debugPrint("❌ RepaintBoundary not found");
//         return;
//       }

//       if (boundary.debugNeedsPaint) {
//         await Future.delayed(const Duration(milliseconds: 300));
//       }

//       final image = await boundary.toImage(pixelRatio: 3.0);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       final pngBytes = byteData?.buffer.asUint8List();

//       if (pngBytes == null) {
//         debugPrint("❌ PNG bytes were null");
//         return;
//       }

//       final result = await SaverGallery.saveImage(
//         pngBytes,
//         quality: 100,
//         fileName: "product_qr_${DateTime.now().millisecondsSinceEpoch}",
//         androidRelativePath: "Pictures/NexaBill/Products",
//         skipIfExists: false,
//       );

//       debugPrint("✅ Saved using saver_gallery: $result");

//       if (context.mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("✅ QR saved to Gallery")));
//       }
//     } catch (e) {
//       debugPrint("❌ Download QR failed: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final controller = ref.watch(adminProductsProvider.notifier);
//     final products = ref.watch(adminProductsProvider).products;
//     final martName = ref.watch(adminProductsProvider).martName;

//     return Scaffold(
//       body:
//           products.isEmpty
//               ? const Center(
//                 child: Text(
//                   "➕ Add a product to get started",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//                 ),
//               )
//               : ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: products.length,
//                 itemBuilder: (context, index) {
//                   final product = products[index];
//                   final price = double.tryParse(product.price) ?? 0;
//                   final discount = double.tryParse(product.discount) ?? 0;
//                   final discountedPrice = price - (price * discount / 100);

//                   final GlobalKey qrCardKey = GlobalKey();

//                   return Stack(
//                     children: [
//                       RepaintBoundary(
//                         key: qrCardKey,
//                         child: Material(
//                           color: Colors.transparent,
//                           child: Container(
//                             margin: const EdgeInsets.only(bottom: 16),
//                             decoration: BoxDecoration(
//                               color: isDark ? Colors.black : Colors.white,
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.1),
//                                   blurRadius: 6,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Row(
//                                 crossAxisAlignment:
//                                     CrossAxisAlignment
//                                         .start, // ensures proper alignment
//                                 children: [
//                                   QrImageView(
//                                     data: product.qrCode,
//                                     version: QrVersions.auto,
//                                     size: 100.0,
//                                     backgroundColor: Colors.white,
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: Column(
//                                       mainAxisSize:
//                                           MainAxisSize
//                                               .min, // dynamic height based on content
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           product.name,
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.bold,
//                                             color:
//                                                 isDark
//                                                     ? Colors.white
//                                                     : Colors.black,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           "Qty: ${product.quantity}",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color:
//                                                 isDark
//                                                     ? Colors.white
//                                                     : Colors.black,
//                                           ),
//                                         ),
//                                         Text(
//                                           "MRP: ₹${product.price}",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color:
//                                                 isDark
//                                                     ? Colors.white
//                                                     : Colors.black,
//                                           ),
//                                         ),
//                                         Text(
//                                           "$martName Price: ₹${discountedPrice.toStringAsFixed(2)}",
//                                           style: const TextStyle(
//                                             fontSize: 14,
//                                             color: Colors.green,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         right: 4,
//                         top: 4,
//                         child: IconButton(
//                           icon: Icon(
//                             Icons.download,
//                             size: 20,
//                             color: isDark ? Colors.white : Colors.black,
//                           ),
//                           onPressed: () => _downloadQrCard(qrCardKey),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//     );
//   }
// }
