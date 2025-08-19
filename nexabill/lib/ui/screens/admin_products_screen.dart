import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
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

                  return Dismissible(
                    key: ValueKey(product.name),
                    background: Container(
                      color:
                          isDark
                              ? AppTheme.secondaryColor.withOpacity(0.8)
                              : AppTheme.primaryColor.withOpacity(0.85),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete,
                        color: AppTheme.whiteColor,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      controller.deleteProduct(product.name);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Product deleted"),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () => controller.addProductBack(product),
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Stack(
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
                                            "${product.name} (PID: ${product.productId})",
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
                                            "Qty: ${product.quantity} | Variant: ${product.variant}",
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
                                () => controller.downloadQrCard(
                                  qrCardKey,
                                  context,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:qr_flutter/qr_flutter.dart';
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
//                                 crossAxisAlignment: CrossAxisAlignment.start,
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
//                                       mainAxisSize: MainAxisSize.min,
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         const SizedBox(height: 6),
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
//                           onPressed:
//                               () =>
//                                   controller.downloadQrCard(qrCardKey, context),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//     );
//   }
// }
