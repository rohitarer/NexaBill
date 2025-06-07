import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nexabill/providers/admin_products_provider.dart';

class AddProductSheet extends ConsumerStatefulWidget {
  const AddProductSheet({super.key});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProductsProvider.notifier).clearFields();
      ref.read(adminProductsProvider.notifier).fetchMartName();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final controller = ref.watch(adminProductsProvider.notifier);
    final qrData = ref.watch(adminProductsProvider).generatedQRData;
    final martName = ref.watch(adminProductsProvider).martName;
    final nextPid = controller.products.length + 1;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add New Product",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.nameController,
              label: "Product Name",
              hintText: "Enter product name",
              prefixIcon: Icons.shopping_bag,
              labelColor: isDarkMode ? Colors.white : null,
              onChanged: (_) => controller.onInputChange(ref),
            ),
            CustomTextField(
              controller: controller.priceController,
              label: "Price",
              hintText: "Enter price",
              prefixIcon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              labelColor: isDarkMode ? Colors.white : null,
              onChanged: (_) => controller.onInputChange(ref),
            ),
            CustomTextField(
              controller: controller.variantController,
              label: "Variant / Size",
              hintText: "Enter variant or size",
              prefixIcon: Icons.label,
              labelColor: isDarkMode ? Colors.white : null,
              onChanged: (_) => controller.onInputChange(ref),
            ),
            CustomTextField(
              controller: controller.quantityController,
              label: "Quantity",
              hintText: "Enter quantity",
              prefixIcon: Icons.confirmation_number,
              keyboardType: TextInputType.number,
              labelColor: isDarkMode ? Colors.white : null,
              onChanged: (_) => controller.onInputChange(ref),
            ),
            CustomTextField(
              controller: controller.gstController,
              label: "GST %",
              hintText: "Enter GST %",
              prefixIcon: Icons.percent,
              keyboardType: TextInputType.number,
              labelColor: isDarkMode ? Colors.white : null,
              onChanged: (_) => controller.onInputChange(ref),
            ),
            CustomTextField(
              controller: controller.discountController,
              label: "Discount %",
              hintText: "Enter discount %",
              prefixIcon: Icons.discount,
              keyboardType: TextInputType.number,
              labelColor: isDarkMode ? Colors.white : null,
              onChanged: (_) => controller.onInputChange(ref),
            ),

            if (qrData != null && controller.allFieldsFilled) ...[
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 120.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${controller.nameController.text.trim()} (PID: $nextPid)",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Qty: ${controller.quantityController.text.trim()} | Variant: ${controller.variantController.text.trim()}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "MRP: ₹${controller.priceController.text.trim()}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "$martName Price: ₹${controller.calculateDiscountedPrice()}",
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
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  qrData != null && controller.allFieldsFilled
                      ? () => controller.saveProduct(ref, context)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: const Text("Add Product"),
            ),
          ],
        ),
      ),
    );
  }
}
