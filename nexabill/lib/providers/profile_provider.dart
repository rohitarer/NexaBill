import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexabill/ui/screens/home_screen.dart';
import 'package:path_provider/path_provider.dart';

/// **Profile Fetching Provider with Retry Logic**
final profileFutureProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }

  const int maxRetries = 5;
  int attempt = 0;

  while (attempt < maxRetries) {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }

    attempt++;
    await Future.delayed(const Duration(seconds: 1));
  }

  throw Exception("User profile not found after retries");
});

/// **StateNotifierProvider for Profile Editing**
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      return ProfileNotifier();
    });

/// **State Providers for Gender & State Selection**
final selectedGenderProvider = StateProvider<String>((ref) => "Male");
final selectedStateProvider = StateProvider<String?>(
  (ref) => null,
); // Default is null (Hint text)

/// **Profile Notifier**

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState.initial());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// **📌 Load Profile Data from Firebase Realtime Database & Firestore**
  Future<void> loadProfile() async {
    User? user = _auth.currentUser;
    if (user == null) {
      state = ProfileState.error("User not logged in");
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      // ✅ Fetch user data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(user.uid).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        state = ProfileState.error("User profile not found");
        return;
      }

      // ✅ Fetch Base64 Image String from Firestore
      String? base64Image = userData["profileImageUrl"];

      // ✅ Decode the Base64 string into a File
      File? decodedImage;
      if (base64Image != null && base64Image.isNotEmpty) {
        decodedImage = await decodeBase64ToImage(base64Image);
      }

      // ✅ Update ProfileState with loaded data
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
        profileImage: decodedImage, // ✅ Set decoded image
        profileImageUrl: base64Image ?? "", // ✅ Store Base64 Image String
        isProfileComplete: userData["isProfileComplete"] ?? false,
      );

      debugPrint("✅ Profile image loaded successfully");
    } catch (e) {
      state = ProfileState.error("Error loading profile: ${e.toString()}");
    }
  }

  /// **📌 Pick Image and Convert to Base64**
  Future<void> pickAndUploadImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    state = state.copyWith(profileImage: imageFile);

    await uploadProfileImageToRealtimeDatabase(imageFile);
  }

  /// **📌 Convert Image to Base64 and Upload to Firebase Realtime Database & Firestore**
  Future<void> uploadProfileImageToRealtimeDatabase(File imageFile) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ Convert Image to Base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);

      // ✅ Save Base64 Image to Realtime Database
      DatabaseReference userRef = _database
          .ref()
          .child("users")
          .child(user.uid);
      await userRef.update({
        "profileImageBase64": base64String, // 🔥 Store Image as Base64 String
      });

      // ✅ Save the SAME Base64 String in Firestore
      await _firestore.collection("users").doc(user.uid).update({
        "profileImageUrl": base64String, // 🔥 Store Base64 String in Firestore
      });

      // ✅ Update state
      state = state.copyWith(profileImageUrl: base64String);

      debugPrint(
        "✅ Profile image saved successfully in Realtime Database & Firestore",
      );
    } catch (e) {
      debugPrint(
        "❌ Error uploading profile image to Realtime Database: ${e.toString()}",
      );
    }
  }

  /// **📌 Convert Base64 String to File**
  Future<File?> decodeBase64ToImage(String base64String) async {
    try {
      if (base64String.isEmpty) return null;

      // ✅ Fix Incorrect Padding by ensuring Base64 length is a multiple of 4
      while (base64String.length % 4 != 0) {
        base64String += '=';
      }

      // ✅ Decode Image Bytes
      List<int> imageBytes = base64Decode(base64String);

      // ✅ Save to Temporary Directory
      final tempDir = await getTemporaryDirectory();
      final imageFile = File('${tempDir.path}/profile_image.png');
      await imageFile.writeAsBytes(imageBytes);

      debugPrint("✅ Profile image decoded successfully");
      return imageFile;
    } catch (e) {
      debugPrint("❌ Error decoding Base64 image: ${e.toString()}");
      return null;
    }
  }

  /// **Update a Specific Field Without Resetting Others**
  void updateProfileField(String fieldName, dynamic fieldValue) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: state.errorMessage,
      fullName: fieldName == "fullName" ? fieldValue : state.fullName,
      phoneNumber: fieldName == "phoneNumber" ? fieldValue : state.phoneNumber,
      gender: fieldName == "gender" ? fieldValue : state.gender,
      dob: fieldName == "dob" ? fieldValue : state.dob,
      address: fieldName == "address" ? fieldValue : state.address,
      city: fieldName == "city" ? fieldValue : state.city,
      selectedState:
          fieldName == "selectedState" ? fieldValue : state.selectedState,
      pin: fieldName == "pin" ? fieldValue : state.pin,
      profileImage: state.profileImage, // ✅ Retain existing profile image
      isProfileComplete: state.isProfileComplete, // ✅ Retain existing value
    );
  }

  Future<void> saveProfile(BuildContext context, WidgetRef ref) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = ProfileState.error("User not logged in");
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      // ✅ Fetch Latest Data Before Saving
      final Map<String, dynamic> updatedProfileData = {
        "fullName": state.fullName.trim(),
        "phoneNumber": state.phoneNumber.trim(),
        "gender": state.gender,
        "dob": state.dob?.toIso8601String() ?? "",
        "address": state.address.trim(),
        "city": state.city.trim(),
        "state": state.selectedState?.trim() ?? "",
        "pin": state.pin.trim(),
        // "profileImageUrl": state.profileImageUrl, // ✅ Save Image URL
      };
      // ✅ Ensure profileImageUrl is not empty before saving
      if (state.profileImageUrl.isNotEmpty) {
        updatedProfileData["profileImageUrl"] = state.profileImageUrl;
      }

      // ✅ Ensure all fields are properly filled to mark as complete
      bool isComplete = updatedProfileData.values.every(
        (value) => value != null && value.toString().trim().isNotEmpty,
      );

      // ✅ Store isProfileComplete as a boolean
      updatedProfileData["isProfileComplete"] = isComplete;

      // ✅ Save Data to Firestore with Merge
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(
            updatedProfileData,
            SetOptions(merge: true), // ✅ Prevents overwriting existing data
          );

      // ✅ Save Data to Realtime Database
      await _database
          .ref()
          .child("users")
          .child(user.uid)
          .update(updatedProfileData);

      // ✅ Update State with Saved Data
      state = state.copyWith(
        isLoading: false,
        isProfileComplete: isComplete, // ✅ Ensure boolean is used here
      );

      debugPrint("✅ Profile saved successfully: $updatedProfileData");

      // ✅ Rebuild UI & Navigate if Profile is Complete
      if (isComplete) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        });
      }
    } catch (e) {
      state = ProfileState.error("Error saving profile: ${e.toString()}");
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // ✅ Update UI instantly with selected image
      state = state.copyWith(profileImage: imageFile);

      // ✅ Upload to Firebase Realtime Database as Base64
      await uploadProfileImageToRealtimeDatabase(imageFile);
    }
  }
}

/// **Profile State Class**

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
  final File? profileImage; // ✅ Local image file (for selection)
  final String profileImageUrl; // ✅ Firebase Storage image URL
  final bool isProfileComplete; // ✅ Profile completion status

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
  });

  /// **✅ Convert ProfileState to JSON for Firestore**
  Map<String, dynamic> toJson() {
    return {
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "email": email,
      "gender": gender,
      "dob": dob?.toIso8601String(),
      "address": address,
      "city": city,
      "selectedState": selectedState,
      "pin": pin,
      "profileImageUrl": profileImageUrl, // ✅ Include Image URL
      "isProfileComplete": isProfileComplete,
    };
  }

  /// **✅ Create ProfileState from JSON (Firestore)**
  factory ProfileState.fromJson(Map<String, dynamic> json) {
    return ProfileState(
      isLoading: false,
      errorMessage: null,
      fullName: json["fullName"] ?? "",
      phoneNumber: json["phoneNumber"] ?? "",
      email: json["email"] ?? "",
      gender: json["gender"] ?? "Male",
      dob: json["dob"] != null ? DateTime.tryParse(json["dob"]) : null,
      address: json["address"] ?? "",
      city: json["city"] ?? "",
      selectedState: json["selectedState"] ?? "",
      pin: json["pin"] ?? "",
      profileImage: null, // ✅ Profile image is stored locally, not in Firestore
      profileImageUrl: json["profileImageUrl"] ?? "", // ✅ Fetch Image URL
      isProfileComplete: json["isProfileComplete"] ?? false,
    );
  }

  /// **✅ Initial State**
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
      profileImageUrl: "", // ✅ No image initially
      isProfileComplete: false, // ✅ Default to false
    );
  }

  /// **✅ Loaded State**
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
    String profileImageUrl = "", // ✅ Default to empty URL
    bool isProfileComplete = false, // ✅ Default value
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
      profileImageUrl: profileImageUrl, // ✅ Ensure URL persists
      isProfileComplete: isProfileComplete,
    );
  }

  /// **✅ Error State**
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
      isProfileComplete: false, // ✅ Ensure a default value is set
    );
  }

  /// **✅ CopyWith Method - Updates Individual Fields Without Resetting Others**
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
    String? profileImageUrl, // ✅ Support image URL updates
    bool? isProfileComplete,
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
      profileImageUrl:
          profileImageUrl ?? this.profileImageUrl, // ✅ Persist Image URL
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
