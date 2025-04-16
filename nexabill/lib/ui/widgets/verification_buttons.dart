import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexabill/core/theme.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_verification_provider.dart';
import 'package:nexabill/ui/widgets/cahier_info_handler.dart';

class VerificationButtons extends ConsumerStatefulWidget {
  final String martName;
  final VoidCallback? onPop; // 👈 Callback from parent

  const VerificationButtons({super.key, required this.martName, this.onPop});

  @override
  ConsumerState<VerificationButtons> createState() =>
      _VerificationButtonsState();
}

class _VerificationButtonsState extends ConsumerState<VerificationButtons>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _shineController;
  late AnimationController _starController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shineAnimation;

  bool _isAccepted = false;
  bool _isRejected = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _shineAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shineController.dispose();
    _starController.dispose();
    super.dispose();
  }

  // void _handleAccept() async {
  //   final state = ref.read(billVerificationProvider);
  //   final notifier = ref.read(billVerificationProvider.notifier);

  //   setState(() {
  //     _isAccepted = true;
  //     _isRejected = false;
  //   });

  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null && BillData.customerId.isEmpty) {
  //     BillData.customerId = user.uid;
  //   }

  //   if (state.sealStatus != BillSealStatus.sealed) {
  //     debugPrint('✅ Verified button FIRST press → Apply verified stamp.');
  //     await notifier.sealBill();
  //     await CashierInfoHandler.saveSealStatus(BillSealStatus.sealed);

  //     _shineController.forward(from: 0.0);
  //     _starController.forward(from: 0.0);

  //     Future.delayed(const Duration(milliseconds: 800), () {
  //       if (!_hasPopped) {
  //         _hasPopped = true;
  //         widget.onPop?.call(); // ✅ handler call
  //         debugPrint("🚪 Verified (first press) → Handler called.");
  //       }
  //     });
  //   } else {
  //     debugPrint('✅ Verified button SECOND press → Already sealed.');
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       if (!_hasPopped) {
  //         _hasPopped = true;
  //         widget.onPop?.call(); // ✅ handler call
  //         debugPrint("🚪 Verified (second press) → Handler called.");
  //       }
  //     });
  //   }
  // }

  void _handleAccept() async {
    if (!mounted) return;

    final state = ref.read(billVerificationProvider);
    final notifier = ref.read(billVerificationProvider.notifier);

    setState(() {
      _isAccepted = true;
      _isRejected = false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && BillData.customerId.isEmpty) {
      BillData.customerId = user.uid;
    }

    if (state.sealStatus != BillSealStatus.sealed) {
      debugPrint('✅ Verified button FIRST press → Apply verified stamp.');
      await notifier.sealBill();

      if (!mounted) return;
      await CashierInfoHandler.saveSealStatus(BillSealStatus.sealed);

      if (mounted) {
        _shineController.forward(from: 0.0);
        _starController.forward(from: 0.0);
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_hasPopped) {
          _hasPopped = true;
          widget.onPop?.call(); // ✅ handler call
          debugPrint("🚪 Verified (first press) → Handler called.");
        }
      });
    } else {
      debugPrint('✅ Verified button SECOND press → Already sealed.');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasPopped) {
          _hasPopped = true;
          widget.onPop?.call(); // ✅ handler call
          debugPrint("🚪 Verified (second press) → Handler called.");
        }
      });
    }
  }

  void _handleReject() async {
    final notifier = ref.read(billVerificationProvider.notifier);

    setState(() {
      _isRejected = true;
      _isAccepted = false;
    });

    notifier.rejectBill();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && BillData.customerId.isEmpty) {
      BillData.customerId = user.uid;
    }

    await CashierInfoHandler.saveSealStatus(BillSealStatus.rejected);

    Future.delayed(const Duration(seconds: 2), () {
      if (!_hasPopped) {
        _hasPopped = true;
        widget.onPop?.call(); // ✅ handler call
        debugPrint("⛔ Rejected → Handler called to exit.");
      }
    });
  }

  List<Widget> _buildStars() {
    return List.generate(6, (index) {
      final angle = (pi / 3) * index;
      return AnimatedBuilder(
        animation: _starController,
        builder: (_, __) {
          final radius = _starController.value * 50;
          return Positioned(
            top: 30 - cos(angle) * radius,
            left: 30 + sin(angle) * radius,
            child: Opacity(
              opacity: 1 - _starController.value,
              child: const Icon(Icons.star, color: Colors.amber, size: 16),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  curve: _isRejected ? Curves.bounceOut : Curves.easeOutBack,
                  left: _isRejected ? screenWidth - 80 : screenWidth / 2 - 90,
                  bottom: _isRejected ? -10 : 0,
                  child: GestureDetector(
                    onTap: _handleAccept,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isAccepted) ..._buildStars(),
                        if (_isAccepted)
                          AnimatedBuilder(
                            animation: _shineAnimation,
                            builder: (_, __) {
                              return Container(
                                width: 60 + _shineAnimation.value,
                                height: 60 + _shineAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.2 * (1 - _shineAnimation.value / 12),
                                  ),
                                ),
                              );
                            },
                          ),
                        CircleAvatar(
                          radius:
                              _isRejected
                                  ? 20
                                  : _isAccepted
                                  ? 36
                                  : 30,
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.check, color: AppTheme.whiteColor),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.bounceOut,
                  left: _isAccepted ? screenWidth - 80 : screenWidth / 2 + 30,
                  bottom: _isAccepted ? -10 : 0,
                  child: GestureDetector(
                    onTap: _handleReject,
                    child: CircleAvatar(
                      radius:
                          _isAccepted
                              ? 20
                              : _isRejected
                              ? 36
                              : 30,
                      backgroundColor: AppTheme.warningColor,
                      child: Icon(Icons.close, color: AppTheme.whiteColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
