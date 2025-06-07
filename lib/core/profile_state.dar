import 'dart:io';

class ProfileState {
  final bool isLoading;
  final String? message; // ✅ Added this field
  final File? profileImage;

  ProfileState({required this.isLoading, this.message, this.profileImage});

  /// ✅ **Initial State**
  factory ProfileState.initial() {
    return ProfileState(isLoading: false);
  }

  /// ✅ **Success State**
  factory ProfileState.success(String message) {
    return ProfileState(isLoading: false, message: message);
  }

  /// ✅ **Error State**
  factory ProfileState.error(String message) {
    return ProfileState(isLoading: false, message: message);
  }

  /// ✅ **Copy State for Image Updates**
  ProfileState copyWith({
    bool? isLoading,
    String? message,
    File? profileImage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
