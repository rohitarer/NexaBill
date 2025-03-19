import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexabill/ui/screens/home_screen.dart';

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

  /// **Load Profile Data from Firestore**
  Future<void> loadProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = ProfileState.error("User not logged in");
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        state = ProfileState.error("User profile not found");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      state = ProfileState.loaded(
        fullName: userData["fullName"] ?? "",
        phoneNumber: userData["phoneNumber"] ?? "",
        email: user.email ?? "",
        gender: userData["gender"] ?? "Male",
        dob:
            userData["dob"] != null ? DateTime.tryParse(userData["dob"]) : null,
        address: userData["address"] ?? "",
        city: userData["city"] ?? "",
        selectedState: userData["state"],
        pin: userData["pin"] ?? "",
        isProfileComplete:
            userData["isProfileComplete"] ?? false, // ✅ Use existing field
      );
    } catch (e) {
      state = ProfileState.error("Error loading profile: ${e.toString()}");
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
      isProfileComplete: state.isProfileComplete, // ✅ Retain existing value
      profileImage: state.profileImage, // ✅ Retain existing profile image
    );
  }

  // Future<void> saveProfile() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     state = ProfileState.error("User not logged in");
  //     return;
  //   }

  //   try {
  //     state = state.copyWith(isLoading: true);

  //     // ✅ Fetch Latest Data Before Saving
  //     final updatedProfileData = {
  //       "fullName": state.fullName.trim(),
  //       "phoneNumber": state.phoneNumber.trim(),
  //       "gender": state.gender,
  //       "dob": state.dob?.toIso8601String() ?? "",
  //       "address": state.address.trim(),
  //       "city": state.city.trim(),
  //       "state": state.selectedState ?? "",
  //       "pin": state.pin.trim(),
  //       "isProfileCompleted": true, // ✅ Ensure profile completion flag is set
  //     };

  //     // ✅ Save Data to Firestore with Merge
  //     await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(user.uid)
  //         .set(
  //           updatedProfileData,
  //           SetOptions(
  //             merge: true,
  //           ), // ✅ Merge prevents overwriting existing data
  //         );

  //     state = state.copyWith(isLoading: false);

  //     debugPrint("✅ Profile saved successfully!");
  //   } catch (e) {
  //     state = ProfileState.error("Error saving profile: ${e.toString()}");
  //   }
  // }

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
      };

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

  /// **Pick Image**
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      state = state.copyWith(profileImage: File(pickedFile.path));
    }
  }
}

// class ProfileNotifier extends StateNotifier<ProfileState> {
//   ProfileNotifier() : super(ProfileState.initial());

//   /// **Load Profile Data from Firestore**
//   Future<void> loadProfile() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       state = ProfileState.error("User not logged in");
//       return;
//     }

//     try {
//       state = state.copyWith(isLoading: true);

//       DocumentSnapshot userDoc =
//           await FirebaseFirestore.instance
//               .collection("users")
//               .doc(user.uid)
//               .get();

//       if (!userDoc.exists) {
//         state = ProfileState.error("User profile not found");
//         return;
//       }

//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//       state = ProfileState.loaded(
//         fullName: userData["fullName"] ?? "",
//         phoneNumber: userData["phoneNumber"] ?? "",
//         email: user.email ?? "",
//         gender: userData["gender"] ?? "Male",
//         dob:
//             userData["dob"] != null ? DateTime.tryParse(userData["dob"]) : null,
//         address: userData["address"] ?? "",
//         city: userData["city"] ?? "",
//         selectedState: userData["state"],
//         pin: userData["pin"] ?? "",
//       );
//     } catch (e) {
//       state = ProfileState.error("Error loading profile: ${e.toString()}");
//     }
//   }

//   /// **Update a Specific Field Without Resetting Others**
//   void updateProfileField(String fieldName, dynamic fieldValue) {
//     state = state.copyWith(
//       isLoading: false, // Ensure UI does not get stuck
//       errorMessage: state.errorMessage, // Keep existing error messages
//       fullName: fieldName == "fullName" ? fieldValue : state.fullName,
//       phoneNumber: fieldName == "phoneNumber" ? fieldValue : state.phoneNumber,
//       gender: fieldName == "gender" ? fieldValue : state.gender,
//       dob: fieldName == "dob" ? fieldValue : state.dob,
//       address: fieldName == "address" ? fieldValue : state.address,
//       city: fieldName == "city" ? fieldValue : state.city,
//       selectedState:
//           fieldName == "selectedState" ? fieldValue : state.selectedState,
//       pin: fieldName == "pin" ? fieldValue : state.pin,
//       profileImage: state.profileImage, // Retain the existing profile image
//     );
//   }

//   /// **Save Profile Updates**
//   Future<void> saveProfile() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       state = ProfileState.error("User not logged in");
//       return;
//     }

//     try {
//       state = state.copyWith(isLoading: true);

//       await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
//         "fullName": state.fullName,
//         "phoneNumber": state.phoneNumber,
//         "gender": state.gender,
//         "dob": state.dob?.toIso8601String() ?? "",
//         "address": state.address,
//         "city": state.city,
//         "state": state.selectedState,
//         "pin": state.pin,
//         "isProfileCompleted": true,
//       }, SetOptions(merge: true));

//       state = state.copyWith(isLoading: false);
//     } catch (e) {
//       state = ProfileState.error("Error saving profile: ${e.toString()}");
//     }
//   }

//   /// **Pick Image**
//   Future<void> pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//     );
//     if (pickedFile != null) {
//       state = state.copyWith(profileImage: File(pickedFile.path));
//     }
//   }
// }

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
  final File? profileImage;
  final bool
  isProfileComplete; // ✅ Only keep this field for profile completion tracking

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
    required this.isProfileComplete, // ✅ Ensure only this tracks profile completion
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
      "isProfileComplete":
          isProfileComplete, // ✅ Only use this field for profile tracking
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
      selectedState: json["selectedState"] ?? "", // ✅ Ensure no null issues
      pin: json["pin"] ?? "",
      profileImage: null, // ✅ Profile image is stored locally, not in Firestore
      isProfileComplete:
          json["isProfileComplete"] ?? false, // ✅ Only keep this field
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
      selectedState: "", // ✅ Default to empty string
      pin: "",
      profileImage: null,
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
    bool isProfileComplete =
        false, // ✅ Use a default value instead of force unwrapping
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
      isProfileComplete: isProfileComplete, // ✅ Ensure existing value persists
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
    bool? isProfileComplete, // ✅ Ensure copyWith supports this field
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
      isProfileComplete:
          isProfileComplete ?? this.isProfileComplete, // ✅ Ensure persistence
    );
  }
}

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';

// /// **Profile Fetching Provider with Retry Logic**
// // final profileFutureProvider = FutureProvider<Map<String, dynamic>>((ref) async {
// //   User? user = FirebaseAuth.instance.currentUser;
// //   if (user == null) {
// //     throw Exception("User not logged in");
// //   }

// //   const int maxRetries = 5;
// //   int attempt = 0;

// //   while (attempt < maxRetries) {
// //     DocumentSnapshot userDoc = await FirebaseFirestore.instance
// //         .collection("users")
// //         .doc(user.uid)
// //         .get();

// //     if (userDoc.exists) {
// //       return userDoc.data() as Map<String, dynamic>;
// //     }

// //     attempt++;
// //     await Future.delayed(const Duration(seconds: 2)); // Retry delay
// //   }

// //   throw Exception("User profile not found");
// // });
// final profileFutureProvider = FutureProvider<Map<String, dynamic>>((ref) async {
//   User? user = FirebaseAuth.instance.currentUser;
//   if (user == null) {
//     throw Exception("User not logged in");
//   }

//   const int maxRetries = 5;
//   int attempt = 0;

//   while (attempt < maxRetries) {
//     DocumentSnapshot userDoc =
//         await FirebaseFirestore.instance
//             .collection("users")
//             .doc(user.uid)
//             .get();

//     if (userDoc.exists) {
//       return userDoc.data() as Map<String, dynamic>;
//     }

//     attempt++;
//     await Future.delayed(const Duration(seconds: 1));
//   }

//   throw Exception("User profile not found after retries");
// });

// /// **StateNotifierProvider for Profile Editing**
// final profileNotifierProvider =
//     StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
//       return ProfileNotifier();
//     });

// /// **StateProviders for Gender & State Selection**
// final selectedGenderProvider = StateProvider<String>((ref) => "Male");
// final selectedStateProvider = StateProvider<String?>(
//   (ref) => null,
// ); // Default is null (Hint text)

// /// **Profile Notifier**
// class ProfileNotifier extends StateNotifier<ProfileState> {
//   ProfileNotifier() : super(ProfileState.initial());

//   /// **Load Profile Data from Firestore**
//   Future<void> loadProfile() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       state = ProfileState.error("User not logged in");
//       return;
//     }

//     try {
//       state = state.copyWith(isLoading: true);

//       DocumentSnapshot userDoc =
//           await FirebaseFirestore.instance
//               .collection("users")
//               .doc(user.uid)
//               .get();

//       if (!userDoc.exists) {
//         state = ProfileState.error("User profile not found");
//         return;
//       }

//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//       state = ProfileState.loaded(
//         fullName: userData["fullName"] ?? "",
//         phoneNumber: userData["phoneNumber"] ?? "",
//         email: user.email ?? "",
//         gender: userData["gender"] ?? "Male",
//         dob:
//             userData["dob"] != null ? DateTime.tryParse(userData["dob"]) : null,
//         address: userData["address"] ?? "",
//         city: userData["city"] ?? "",
//         selectedState: userData["state"],
//         pin: userData["pin"] ?? "",
//       );
//     } catch (e) {
//       state = ProfileState.error("Error loading profile: ${e.toString()}");
//     }
//   }

//   /// **Save Profile Updates**
//   Future<void> saveProfile({
//     required String fullName,
//     required String phoneNumber,
//     required String gender,
//     required DateTime? dob,
//     required String address,
//     required String city,
//     required String selectedState,
//     required String pin,
//   }) async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       state = ProfileState.error("User not logged in");
//       return;
//     }

//     try {
//       state = state.copyWith(isLoading: true);

//       await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
//         "fullName": fullName,
//         "phoneNumber": phoneNumber,
//         "gender": gender,
//         "dob": dob?.toIso8601String() ?? "",
//         "address": address,
//         "city": city,
//         "state": selectedState,
//         "pin": pin,
//         "isProfileCompleted": true,
//       }, SetOptions(merge: true));

//       state = ProfileState.loaded(
//         fullName: fullName,
//         phoneNumber: phoneNumber,
//         email: user.email ?? "",
//         gender: gender,
//         dob: dob,
//         address: address,
//         city: city,
//         selectedState: selectedState,
//         pin: pin,
//       );
//     } catch (e) {
//       state = ProfileState.error("Error saving profile: ${e.toString()}");
//     }
//   }

//   /// **Pick Image**
//   Future<void> pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//     );
//     if (pickedFile != null) {
//       state = state.copyWith(profileImage: File(pickedFile.path));
//     }
//   }
// }

// /// **Profile State Class**
// class ProfileState {
//   final bool isLoading;
//   final String? errorMessage;
//   final String fullName;
//   final String phoneNumber;
//   final String email;
//   final String gender;
//   final DateTime? dob;
//   final String address;
//   final String city;
//   final String? selectedState;
//   final String pin;
//   final File? profileImage;

//   ProfileState({
//     required this.isLoading,
//     this.errorMessage,
//     required this.fullName,
//     required this.phoneNumber,
//     required this.email,
//     required this.gender,
//     this.dob,
//     required this.address,
//     required this.city,
//     required this.selectedState,
//     required this.pin,
//     this.profileImage,
//   });

//   /// **Initial State**
//   factory ProfileState.initial() {
//     return ProfileState(
//       isLoading: false,
//       fullName: "",
//       phoneNumber: "",
//       email: "",
//       gender: "Male",
//       address: "",
//       city: "",
//       selectedState: null, // No default state, show hint text
//       pin: "",
//     );
//   }

//   /// **Loaded State**
//   factory ProfileState.loaded({
//     required String fullName,
//     required String phoneNumber,
//     required String email,
//     required String gender,
//     DateTime? dob,
//     required String address,
//     required String city,
//     required String? selectedState,
//     required String pin,
//   }) {
//     return ProfileState(
//       isLoading: false,
//       fullName: fullName,
//       phoneNumber: phoneNumber,
//       email: email,
//       gender: gender,
//       dob: dob,
//       address: address,
//       city: city,
//       selectedState: selectedState,
//       pin: pin,
//     );
//   }

//   /// **Error State**
//   factory ProfileState.error(String message) {
//     return ProfileState(
//       isLoading: false,
//       errorMessage: message,
//       fullName: "",
//       phoneNumber: "",
//       email: "",
//       gender: "Male",
//       address: "",
//       city: "",
//       selectedState: null, // No default state
//       pin: "",
//     );
//   }

//   /// **Copy State for Updates**
//   ProfileState copyWith({
//     bool? isLoading,
//     String? errorMessage,
//     String? fullName,
//     String? phoneNumber,
//     String? email,
//     String? gender,
//     DateTime? dob,
//     String? address,
//     String? city,
//     String? selectedState,
//     String? pin,
//     File? profileImage,
//   }) {
//     return ProfileState(
//       isLoading: isLoading ?? this.isLoading,
//       errorMessage: errorMessage ?? this.errorMessage,
//       fullName: fullName ?? this.fullName,
//       phoneNumber: phoneNumber ?? this.phoneNumber,
//       email: email ?? this.email,
//       gender: gender ?? this.gender,
//       dob: dob ?? this.dob,
//       address: address ?? this.address,
//       city: city ?? this.city,
//       selectedState: selectedState ?? this.selectedState,
//       pin: pin ?? this.pin,
//       profileImage: profileImage ?? this.profileImage,
//     );
//   }
// }
