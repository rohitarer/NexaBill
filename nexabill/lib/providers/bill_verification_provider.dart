import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BillSealStatus { none, sealed, rejected }

// ✅ Extension to convert enum ↔ string
extension BillSealStatusExtension on BillSealStatus {
  String get value {
    switch (this) {
      case BillSealStatus.sealed:
        return 'sealed';
      case BillSealStatus.rejected:
        return 'rejected';
      default:
        return 'none';
    }
  }

  static BillSealStatus fromString(String value) {
    switch (value) {
      case 'sealed':
        return BillSealStatus.sealed;
      case 'rejected':
        return BillSealStatus.rejected;
      default:
        return BillSealStatus.none;
    }
  }
}

class BillVerificationState {
  final bool isVisible;
  final BillSealStatus sealStatus;
  final String otpCode;
  final String userId;

  BillVerificationState({
    required this.isVisible,
    required this.sealStatus,
    this.otpCode = '',
    this.userId = '',
  });

  BillVerificationState copyWith({
    bool? isVisible,
    BillSealStatus? sealStatus,
    String? otpCode,
    String? userId,
  }) {
    return BillVerificationState(
      isVisible: isVisible ?? this.isVisible,
      sealStatus: sealStatus ?? this.sealStatus,
      otpCode: otpCode ?? this.otpCode,
      userId: userId ?? this.userId,
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

  void showBill({required String otp, required String userId}) {
    state = state.copyWith(
      isVisible: true,
      sealStatus: BillSealStatus.none,
      otpCode: otp,
      userId: userId,
    );
    debugPrint('Bill shown with OTP: $otp for userId: $userId');
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
      state = BillVerificationState(
        isVisible: false,
        sealStatus: BillSealStatus.none,
      );
    });
  }

  // ✅ Use this when reading from Firestore
  void setSealStatus(BillSealStatus sealStatus) {
    debugPrint('Setting seal status from Firestore: $sealStatus');
    state = state.copyWith(sealStatus: sealStatus);
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
