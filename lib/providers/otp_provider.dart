// ✅ otp_refresh_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// This provider triggers rebuilds when the OTP is updated.
final otpRefreshProvider = StateProvider<bool>((ref) => false);
