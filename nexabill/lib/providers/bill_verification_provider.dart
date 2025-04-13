import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BillSealStatus { none, sealed, rejected }

class BillVerificationState {
  final bool isVisible;
  final BillSealStatus sealStatus;

  BillVerificationState({required this.isVisible, required this.sealStatus});

  BillVerificationState copyWith({
    bool? isVisible,
    BillSealStatus? sealStatus,
  }) {
    return BillVerificationState(
      isVisible: isVisible ?? this.isVisible,
      sealStatus: sealStatus ?? this.sealStatus,
    );
  }
}

class BillVerificationNotifier extends StateNotifier<BillVerificationState> {
  BillVerificationNotifier()
    : super(
        BillVerificationState(
          isVisible: false,
          sealStatus: BillSealStatus.none,
        ),
      );

  void showBill() {
    state = state.copyWith(isVisible: true, sealStatus: BillSealStatus.none);
    debugPrint('Bill shown: Reset to no stamp.');
  }

  void sealBill() {
    if (state.sealStatus == BillSealStatus.sealed) {
      debugPrint('Already sealed. Skipping reseal.');
      return;
    }
    debugPrint('Sealing bill...');
    state = state.copyWith(sealStatus: BillSealStatus.sealed);
  }

  void rejectBill() {
    debugPrint('Rejecting bill...');
    state = state.copyWith(sealStatus: BillSealStatus.rejected);
    Future.delayed(const Duration(seconds: 2), () {
      debugPrint('Auto-hiding rejected bill.');
      state = state.copyWith(isVisible: false, sealStatus: BillSealStatus.none);
    });
  }

  void reset() {
    debugPrint('Resetting bill verification state.');
    state = BillVerificationState(
      isVisible: false,
      sealStatus: BillSealStatus.none,
    );
  }
}

final billVerificationProvider =
    StateNotifierProvider<BillVerificationNotifier, BillVerificationState>(
      (ref) => BillVerificationNotifier(),
    );
