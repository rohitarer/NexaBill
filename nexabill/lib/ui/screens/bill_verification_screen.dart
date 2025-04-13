import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/ui/widgets/bill_container.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/ui/widgets/verification_buttons.dart';

class BillVerificationScreen extends ConsumerStatefulWidget {
  const BillVerificationScreen({super.key});

  @override
  ConsumerState<BillVerificationScreen> createState() =>
      _BillVerificationScreenState();
}

class _BillVerificationScreenState
    extends ConsumerState<BillVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _checkCode(String value) {
    if (value.length == 6) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).unfocus(); // ✅ Close keyboard
        debugPrint("6-digit OTP entered: $value -> Showing bill.");
        ref.read(billVerificationProvider.notifier).showBill();
        _codeController.clear();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billVerificationProvider);
    final notifier = ref.read(billVerificationProvider.notifier);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final ScrollController scrollController = ScrollController();

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "“Every bill verified is a step toward trust.”",
                  style: TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Enter 6-digit Verification Code",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 200,
                  child: CustomTextField(
                    controller: _codeController,
                    maxLength: 6, // ✅ Updated to 6 digits
                    keyboardType: TextInputType.number,
                    hintText: "XXXXXX",
                    onChanged: _checkCode,
                    isPassword: false,
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.isVisible)
          BillContainer(
            scrollController: scrollController,
            billItems: BillData.products,
            isKeyboardOpen: isKeyboardOpen,
          ),
        if (state.isVisible)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: VerificationButtons(ref: ref, martName: "DMart"),
          ),
      ],
    );
  }
}
