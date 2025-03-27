import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexabill/providers/home_provider.dart';
import 'package:nexabill/services/role_routes.dart';
import 'package:nexabill/ui/screens/customerHome_screen.dart';
import 'package:path_provider/path_provider.dart';

final profileFutureProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not logged in");

  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

  if (userDoc.exists) {
    final data = userDoc.data() as Map<String, dynamic>;

    ref.read(selectedGenderProvider.notifier).state = data["gender"] ?? "Male";
    ref.read(selectedStateProvider.notifier).state = data["state"] ?? "";

    return data;
  }

  throw Exception("User profile not found");
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      return ProfileNotifier(ref);
    });

final selectedGenderProvider = StateProvider<String>((ref) => "Male");
final selectedStateProvider = StateProvider<String?>((ref) => null);

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this.ref) : super(ProfileState.initial());

  final Ref ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> loadProfile(WidgetRef ref) async {
    User? user = _auth.currentUser;
    if (user == null) {
      state = ProfileState.error("User not logged in");
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(user.uid).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        state = ProfileState.error("User profile not found");
        return;
      }

      ref.read(selectedGenderProvider.notifier).state =
          userData["gender"] ?? "Male";
      ref.read(selectedStateProvider.notifier).state = userData["state"] ?? "";

      String? base64Image = userData["profileImageUrl"];
      File? decodedImage;
      if (base64Image != null && base64Image.isNotEmpty) {
        decodedImage = await decodeBase64ToImage(base64Image);
      }

      state = ProfileState.loaded(
        fullName: userData["fullName"] ?? "",
        phoneNumber: userData["phoneNumber"] ?? "",
        email: user.email ?? "",
        gender: userData["gender"] ?? "Male",
        dob:
            userData["dob"] != null ? DateTime.tryParse(userData["dob"]) : null,
        address: userData["address"] ?? "",
        city: userData["city"] ?? "",
        selectedState: userData["state"] ?? "",
        pin: userData["pin"] ?? "",
        profileImage: decodedImage,
        profileImageUrl: base64Image ?? "",
        isProfileComplete: userData["isProfileComplete"] ?? false,
        role: userData["role"] ?? "customer",
        mart: userData["mart"] ?? "",
        counterNumber: userData["counterNumber"] ?? "",
      );

      debugPrint("✅ Profile data and gender restored successfully.");
    } catch (e) {
      state = ProfileState.error("Error loading profile: \${e.toString()}");
    }
  }

  Future<void> pickAndUploadImage(WidgetRef ref) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    List<int> compressedImageBytes = await _compressImage(imageFile);
    String base64String = base64Encode(compressedImageBytes);

    await uploadProfileImage(base64String, ref);
  }

  Future<List<int>> _compressImage(File imageFile) async {
    Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      quality: 40,
      format: CompressFormat.jpeg,
    );
    return compressedBytes ?? await imageFile.readAsBytes();
  }

  Future<void> uploadProfileImage(String base64String, WidgetRef ref) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(user.uid);

      // Save to Realtime Database
      await userRef.update({"profileImageBase64": base64String});

      // Save to Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"profileImageUrl": base64String},
      );

      // ✅ Optimistically update the state (so UI shows it instantly)
      state = state.copyWith(profileImageUrl: base64String);
      final decoded = await decodeBase64ToImage(base64String);
      state = state.copyWith(profileImage: decoded);

      // ✅ Invalidate and give slight delay for Firestore to fully update
      ref.invalidate(profileImageProvider);
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint("✅ Profile image updated and state refreshed!");
    } catch (e) {
      debugPrint("❌ Error updating profile image: $e");
    }
  }

  Future<File?> decodeBase64ToImage(String base64String) async {
    try {
      if (base64String.trim().isEmpty) {
        debugPrint("❌ Base64 string is empty.");
        return null;
      }

      // Ensure valid padding for base64 string
      while (base64String.length % 4 != 0) {
        base64String += '=';
      }

      final bytes = base64Decode(base64String);

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/profile_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      debugPrint("✅ Profile image decoded and saved at: ${file.path}");
      return file;
    } catch (e) {
      debugPrint("❌ Error decoding Base64 image: ${e.toString()}");
      return null;
    }
  }

  void updateProfileField(String fieldName, dynamic fieldValue, WidgetRef ref) {
    // Update gender and state in global providers
    if (fieldName == "gender") {
      ref.read(selectedGenderProvider.notifier).state = fieldValue;
    } else if (fieldName == "selectedState") {
      ref.read(selectedStateProvider.notifier).state = fieldValue;
    }

    // Update internal state
    state = state.copyWith(
      fullName: fieldName == "fullName" ? fieldValue : state.fullName,
      phoneNumber: fieldName == "phoneNumber" ? fieldValue : state.phoneNumber,
      gender: fieldName == "gender" ? fieldValue : state.gender,
      dob: fieldName == "dob" ? fieldValue : state.dob,
      address: fieldName == "address" ? fieldValue : state.address,
      city: fieldName == "city" ? fieldValue : state.city,
      selectedState:
          fieldName == "selectedState" ? fieldValue : state.selectedState,
      pin: fieldName == "pin" ? fieldValue : state.pin,
      // ✅ Retain everything else unchanged
      profileImage: state.profileImage,
      profileImageUrl: state.profileImageUrl,
      isProfileComplete: state.isProfileComplete,
      isLoading: false,
      errorMessage: state.errorMessage,
      role: fieldName == "role" ? fieldValue : state.role,
      mart: fieldName == "mart" ? fieldValue : state.mart,
      counterNumber:
          fieldName == "counterNumber" ? fieldValue : state.counterNumber,
    );
  }

  // Future<void> saveProfile(BuildContext context, WidgetRef ref) async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     state = ProfileState.error("User not logged in");
  //     return;
  //   }

  //   try {
  //     state = state.copyWith(isLoading: true);

  //     // ✅ Build updated profile map
  //     final Map<String, dynamic> updatedProfileData = {
  //       "fullName": state.fullName.trim(),
  //       "phoneNumber": state.phoneNumber.trim(),
  //       "gender": state.gender,
  //       "dob": state.dob?.toIso8601String() ?? "",
  //       "address": state.address.trim(),
  //       "city": state.city.trim(),
  //       "state": state.selectedState.trim(),
  //       "pin": state.pin.trim(),
  //       "profileImageUrl": state.profileImageUrl,
  //       "role": state.role,
  //       "mart": state.mart,
  //       "counterNumber": state.counterNumber,
  //     };

  //     // ✅ Mark profile complete if all fields are filled
  //     final isComplete = updatedProfileData.values.every(
  //       (value) => value != null && value.toString().trim().isNotEmpty,
  //     );
  //     updatedProfileData["isProfileComplete"] = isComplete;

  //     // ✅ Save to Firestore
  //     await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(user.uid)
  //         .set(updatedProfileData, SetOptions(merge: true));

  //     // ✅ Save to Realtime Database
  //     await FirebaseDatabase.instance
  //         .ref()
  //         .child("users")
  //         .child(user.uid)
  //         .update(updatedProfileData);

  //     // ✅ Invalidate image provider to refresh HomeScreen
  //     ref.invalidate(profileImageProvider);

  //     // ✅ Give Firestore time to sync
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     // ✅ Update local state
  //     state = state.copyWith(isLoading: false, isProfileComplete: isComplete);

  //     debugPrint("✅ Profile saved successfully: $updatedProfileData");

  //     // ✅ Navigate to HomeScreen
  //     if (context.mounted) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder:
  //               (context) => RoleRoutes.getHomeScreen(
  //                 state.role,
  //                 state.isProfileComplete,
  //               ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     state = ProfileState.error("Error saving profile: ${e.toString()}");
  //   }
  // }
  // 🔄 Modified saveProfile method with role-based profile completeness check
  Future<void> saveProfile(BuildContext context, WidgetRef ref) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = ProfileState.error("User not logged in");
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      // ✅ Build updated profile map
      final Map<String, dynamic> updatedProfileData = {
        "fullName": state.fullName.trim(),
        "phoneNumber": state.phoneNumber.trim(),
        "gender": state.gender,
        "dob": state.dob?.toIso8601String() ?? "",
        "address": state.address.trim(),
        "city": state.city.trim(),
        "state": state.selectedState.trim(),
        "pin": state.pin.trim(),
        "profileImageUrl": state.profileImageUrl,
        "role": state.role,
        "mart": state.mart,
        "counterNumber": state.counterNumber,
      };

      // ✅ Conditional validation for profile completeness based on role
      final isCashier = state.role.toLowerCase() == "cashier";
      final requiredFields = [
        updatedProfileData["fullName"],
        updatedProfileData["phoneNumber"],
        updatedProfileData["gender"],
        updatedProfileData["dob"],
        updatedProfileData["address"],
        updatedProfileData["city"],
        updatedProfileData["state"],
        updatedProfileData["pin"],
        updatedProfileData["profileImageUrl"],
        updatedProfileData["role"],
        if (isCashier) updatedProfileData["mart"],
        if (isCashier) updatedProfileData["counterNumber"],
      ];

      final isComplete = requiredFields.every(
        (value) => value != null && value.toString().trim().isNotEmpty,
      );
      updatedProfileData["isProfileComplete"] = isComplete;

      // ✅ Save to Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(updatedProfileData, SetOptions(merge: true));

      // ✅ Save to Realtime Database
      await FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(user.uid)
          .update(updatedProfileData);

      // ✅ Invalidate image provider to refresh HomeScreen
      ref.invalidate(profileImageProvider);

      // ✅ Give Firestore time to sync
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ Update local state
      state = state.copyWith(isLoading: false, isProfileComplete: isComplete);

      debugPrint("✅ Profile saved successfully: \$updatedProfileData");

      // ✅ Navigate to HomeScreen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => RoleRoutes.getHomeScreen(
                  state.role,
                  state.isProfileComplete,
                ),
          ),
        );
      }
    } catch (e) {
      state = ProfileState.error("Error saving profile: \${e.toString()}");
    }
  }
}

class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String gender;
  final DateTime? dob;
  final String address;
  final String city;
  final String selectedState;
  final String pin;
  final File? profileImage;
  final String profileImageUrl;

  final bool isProfileComplete;
  final String role;
  final String mart;
  final String counterNumber;

  ProfileState({
    required this.isLoading,
    this.errorMessage,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.gender,
    this.dob,
    required this.address,
    required this.city,
    required this.selectedState,
    required this.pin,
    this.profileImage,
    required this.profileImageUrl,
    required this.isProfileComplete,
    required this.role,
    required this.mart,
    required this.counterNumber,
  });

  factory ProfileState.initial() {
    return ProfileState(
      isLoading: false,
      errorMessage: null,
      fullName: "",
      phoneNumber: "",
      email: "",
      gender: "Male",
      dob: null,
      address: "",
      city: "",
      selectedState: "",
      pin: "",
      profileImage: null,
      profileImageUrl: "",
      isProfileComplete: false,
      role: "customer",
      mart: "",
      counterNumber: "",
    );
  }

  factory ProfileState.loaded({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String gender,
    DateTime? dob,
    required String address,
    required String city,
    required String selectedState,
    required String pin,
    File? profileImage,
    String profileImageUrl = "",
    bool isProfileComplete = false,
    required String role,
    required String mart,
    required String counterNumber,
  }) {
    return ProfileState(
      isLoading: false,
      errorMessage: null,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      gender: gender,
      dob: dob,
      address: address,
      city: city,
      selectedState: selectedState,
      pin: pin,
      profileImage: profileImage,
      profileImageUrl: profileImageUrl,
      isProfileComplete: isProfileComplete,
      role: role,
      mart: mart,
      counterNumber: counterNumber,
    );
  }

  factory ProfileState.error(String message) {
    return ProfileState(
      isLoading: false,
      errorMessage: message,
      fullName: "",
      phoneNumber: "",
      email: "",
      gender: "Male",
      dob: null,
      address: "",
      city: "",
      selectedState: "",
      pin: "",
      profileImage: null,
      profileImageUrl: "",
      isProfileComplete: false,
      role: "customer",
      mart: "",
      counterNumber: "",
    );
  }

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? gender,
    DateTime? dob,
    String? address,
    String? city,
    String? selectedState,
    String? pin,
    File? profileImage,
    String? profileImageUrl,
    bool? isProfileComplete,
    String? role,
    String? mart,
    String? counterNumber,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      city: city ?? this.city,
      selectedState: selectedState ?? this.selectedState,
      pin: pin ?? this.pin,
      profileImage: profileImage ?? this.profileImage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      role: role ?? this.role,
      mart: mart ?? this.mart,
      counterNumber: counterNumber ?? this.counterNumber,
    );
  }
}
