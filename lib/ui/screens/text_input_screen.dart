import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';

class TextInputScreen extends ConsumerStatefulWidget {
  final String initialText;
  final int quantity;

  const TextInputScreen({
    super.key,
    required this.initialText,
    required this.quantity,
  });

  @override
  ConsumerState<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends ConsumerState<TextInputScreen> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
  }

  void _handleAdd() => setState(() => _quantity++);
  void _handleSubtract() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  Widget buildQuantityBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.whiteColor.withOpacity(0.95),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.red),
            onPressed: _handleSubtract,
          ),
          Text(
            "$_quantity",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: _handleAdd,
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.green,
            child: IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                // ✅ Add logic to confirm product with text and quantity
                Navigator.pop(context);
              },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [Positioned(bottom: 40, child: buildQuantityBox())],
      ),
    );
  }
}
