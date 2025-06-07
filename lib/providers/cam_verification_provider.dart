import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the camera verification toggle state (Admin setting)
final camVerificationProvider = StateProvider<bool>((ref) => false);
