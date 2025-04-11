import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nexabill/providers/customer_home_provider.dart';
import 'package:nexabill/services/role_routes.dart';
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
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        state = ProfileState.error("User profile not found");
        return;
      }

      // Gender & State sync
      ref.read(selectedGenderProvider.notifier).state =
          userData["gender"] ?? "Male";
      ref.read(selectedStateProvider.notifier).state = userData["state"] ?? "";

      // Decode base64 images
      final profileImageFile = await decodeBase64ToImage(
        userData["profileImageUrl"] ?? "",
        "profile_image",
      );

      final martLogoFile = await decodeBase64ToImage(
        userData["martLogoUrl"] ?? "",
        "mart_logo",
      );

      final passbookImage = await decodeBase64ToImage(
        userData["passbookBase64"] ?? "",
        "passbook",
      );

      final panImage = await decodeBase64ToImage(
        userData["panBase64"] ?? "",
        "pan",
      );

      final aadharImage = await decodeBase64ToImage(
        userData["aadharBase64"] ?? "",
        "aadhar",
      );

      // Decode cover images
      List<String> martCoverBase64List = [];
      List<File> martCoverFileList = [];

      if (userData["martCoverImages"] is List) {
        martCoverBase64List = List<String>.from(userData["martCoverImages"]);
        for (final base64 in martCoverBase64List) {
          final file = await decodeBase64ToImage(base64, "cover");
          if (file != null) martCoverFileList.add(file);
        }
      }

      final role = userData["role"] ?? "customer";

      state = state.copyWith(
        isLoading: false,
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
        profileImage: profileImageFile,
        profileImageUrl: userData["profileImageUrl"] ?? "",
        role: role,
        mart: userData["mart"] ?? "",
        counterNumber: userData["counterNumber"] ?? "",
        martName: userData["martName"] ?? "",
        martContact: userData["martContact"] ?? "",
        martAddress: userData["martAddress"] ?? "",
        martCity: userData["martCity"] ?? "",
        martState: userData["martState"] ?? "",
        martPinCode: userData["martPinCode"] ?? "",
        martGstin: userData["martGstin"] ?? "",
        martCin: userData["martCin"] ?? "",
        martLogoUrl: userData["martLogoUrl"] ?? "",
        martLogoFile: martLogoFile,
        martCoverImages: martCoverBase64List,
        martCoverFiles: martCoverFileList,

        // Bank details
        bankHolder: userData["accountHolder"] ?? "",
        bankAccountNumber: userData["accountNumber"] ?? "",
        bankIFSC: userData["ifscCode"] ?? "",
        bankUPI: userData["upiId"] ?? "",
        bankName: userData["bankInfo"],

        // Document images
        passbookImage: passbookImage,
        panImage: panImage,
        aadharImage: aadharImage,

        // Prevent premature completion for admin
        isProfileComplete:
            role == "admin" ? false : (userData["isProfileComplete"] ?? false),
      );

      debugPrint("✅ Profile, bank & docs loaded successfully.");
    } catch (e) {
      state = ProfileState.error("Error loading profile: ${e.toString()}");
    }
  }

  Future<void> pickAndUploadImage({
    required WidgetRef ref,
    required String targetField, // e.g., 'profileImageUrl', 'passbookBase64'
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      debugPrint("📸 Triggered image picker for $targetField");

      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) {
        debugPrint("❌ No image selected for $targetField");
        return;
      }

      final imageFile = File(pickedFile.path);
      final compressedBytes = await _compressImage(imageFile);
      final base64String = base64Encode(compressedBytes);

      // 🛠️ Pass both base64 string and a file name prefix
      final decodedFile = await decodeBase64ToImage(base64String, targetField);
      if (decodedFile == null) {
        debugPrint("❌ Failed to decode image for $targetField");
        return;
      }

      updateProfileField(targetField, base64String, ref);

      if (targetField == 'profileImageUrl') {
        state = state.copyWith(
          profileImageUrl: base64String,
          profileImage: decodedFile,
        );
      }

      debugPrint("✅ $targetField image uploaded and state updated.");
    } catch (e) {
      debugPrint("❌ Error during image upload for $targetField: $e");
    }
  }

  Future<List<int>> _compressImage(
    File imageFile, {
    int targetKB = 500,
    int minQuality = 10,
  }) async {
    const int maxAttempts = 5;
    int quality = 20;
    List<int>? compressedBytes;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null || compressedBytes.isEmpty) break;

      final sizeKB = compressedBytes.length ~/ 1024;
      debugPrint(
        "🧪 Attempt ${attempt + 1}: Size = ${sizeKB}KB at quality $quality",
      );

      if (sizeKB <= targetKB) break;
      quality -= 15; // reduce quality for next attempt

      if (quality < minQuality) break;
    }

    if (compressedBytes == null || compressedBytes.isEmpty) {
      debugPrint("⚠️ Compression failed. Using original file.");
      return await imageFile.readAsBytes();
    }

    debugPrint("✅ Final compressed size: ${compressedBytes.length ~/ 1024} KB");
    return compressedBytes;
  }

  Future<void> pickMartLogo(BuildContext context, WidgetRef ref) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final File logoFile = File(picked.path);
      final compressedBytes = await _compressImage(logoFile);
      final base64Logo = base64Encode(compressedBytes);

      state = state.copyWith(martLogoFile: logoFile, martLogoUrl: base64Logo);

      updateProfileField("martLogoUrl", base64Logo, ref);
      updateProfileField("martLogoFile", logoFile, ref);

      debugPrint("✅ Mart logo updated in provider");
    } catch (e) {
      debugPrint("❌ Error picking mart logo: $e");
    }
  }

  Future<void> pickMartCoverImages(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder:
              (context, setModalState) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Mart Cover Images",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () async {
                            final picked = await picker.pickMultiImage();
                            if (picked.isEmpty) return;

                            final List<File> files = [];
                            final List<String> base64List = [];

                            for (var img in picked) {
                              final file = File(img.path);
                              final compressed = await _compressImage(file);
                              final base64 = base64Encode(compressed);
                              files.add(file);
                              base64List.add(base64);
                            }

                            final updatedFiles = [
                              ...state.martCoverFiles,
                              ...files,
                            ];
                            final updatedBase64 = [
                              ...state.martCoverImages,
                              ...base64List,
                            ];

                            setModalState(() {
                              state = state.copyWith(
                                martCoverFiles: updatedFiles,
                                martCoverImages: updatedBase64,
                              );
                            });

                            updateProfileField(
                              "martCoverFiles",
                              updatedFiles,
                              ref,
                            );
                            updateProfileField(
                              "martCoverImages",
                              updatedBase64,
                              ref,
                            );

                            debugPrint(
                              "✅ Mart cover images updated in provider",
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.martCoverFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  state.martCoverFiles[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    final updatedFiles = [
                                      ...state.martCoverFiles,
                                    ]..removeAt(index);
                                    final updatedBase64 = [
                                      ...state.martCoverImages,
                                    ]..removeAt(index);

                                    setModalState(() {
                                      state = state.copyWith(
                                        martCoverFiles: updatedFiles,
                                        martCoverImages: updatedBase64,
                                      );
                                    });

                                    updateProfileField(
                                      "martCoverFiles",
                                      updatedFiles,
                                      ref,
                                    );
                                    updateProfileField(
                                      "martCoverImages",
                                      updatedBase64,
                                      ref,
                                    );
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Future<void> pickBankDocument(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      switch (type) {
        case 'passbook':
          state = state.copyWith(passbookImage: file);
          break;
        case 'pan':
          state = state.copyWith(panImage: file);
          break;
        case 'aadhar':
          state = state.copyWith(aadharImage: file);
          break;
      }
    }
  }

  Future<void> fetchBankDetailsFromIFSC(String ifscCode) async {
    try {
      final url = Uri.parse("https://ifsc.razorpay.com/$ifscCode");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bank = data['BANK'];
        final branch = data['BRANCH'];
        if (bank != null && branch != null) {
          state = state.copyWith(bankName: "$bank, $branch");
        } else {
          state = state.copyWith(bankName: "Bank details not found");
        }
      } else {
        state = state.copyWith(bankName: "Invalid IFSC code");
      }
    } catch (e) {
      state = state.copyWith(bankName: "Error fetching bank details");
    }
  }

  Future<void> uploadProfileImage({
    required String base64String,
    required String fieldName, // e.g., 'profileImageUrl', 'passbookImage', etc.
    required WidgetRef ref,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ No authenticated user found");
        return;
      }

      // ✅ Decode image from base64
      final decodedFile = await decodeBase64ToImage(base64String, fieldName);
      if (decodedFile == null) {
        debugPrint("❌ Failed to decode image for $fieldName");
        return;
      }

      // ✅ Firestore update
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {fieldName: base64String},
      );

      // ✅ Realtime DB update (optional - for sync)
      await FirebaseDatabase.instance.ref("users/${user.uid}").update({
        fieldName: base64String,
      });

      // ✅ Update local state
      updateProfileField(fieldName, base64String, ref);

      if (fieldName == "profileImageUrl") {
        state = state.copyWith(
          profileImageUrl: base64String,
          profileImage: decodedFile,
        );
        ref.invalidate(profileImageProvider);
      }

      debugPrint("✅ $fieldName updated and stored locally & remotely");
    } catch (e) {
      debugPrint("❌ Error updating $fieldName image: $e");
    }
  }

  Future<File?> decodeBase64ToImage(String base64String, String fileTag) async {
    try {
      if (base64String.trim().isEmpty) {
        debugPrint("⚠️ Base64 string is empty for $fileTag");
        return null;
      }

      // Fix base64 padding
      while (base64String.length % 4 != 0) {
        base64String += '=';
      }

      final bytes = base64Decode(base64String);
      final tempDir = await getTemporaryDirectory();

      final filePath =
          '${tempDir.path}/${fileTag}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      debugPrint("✅ Decoded image for $fileTag saved at: $filePath");
      return file;
    } catch (e) {
      debugPrint("❌ Error decoding image ($fileTag): $e");
      return null;
    }
  }

  void updateProfileField(String fieldName, dynamic fieldValue, WidgetRef ref) {
    if (fieldName == "gender") {
      ref.read(selectedGenderProvider.notifier).state = fieldValue;
    } else if (fieldName == "selectedState") {
      ref.read(selectedStateProvider.notifier).state = fieldValue;
    }

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
      role: fieldName == "role" ? fieldValue : state.role,
      mart: fieldName == "mart" ? fieldValue : state.mart,
      counterNumber:
          fieldName == "counterNumber" ? fieldValue : state.counterNumber,
      martName: fieldName == "martName" ? fieldValue : state.martName,
      martContact: fieldName == "martContact" ? fieldValue : state.martContact,
      martAddress: fieldName == "martAddress" ? fieldValue : state.martAddress,
      martCity: fieldName == "martCity" ? fieldValue : state.martCity,
      martState: fieldName == "martState" ? fieldValue : state.martState,
      martPinCode: fieldName == "martPinCode" ? fieldValue : state.martPinCode,
      martGstin: fieldName == "martGstin" ? fieldValue : state.martGstin,
      martCin: fieldName == "martCin" ? fieldValue : state.martCin,
      martLogoUrl: fieldName == "martLogoUrl" ? fieldValue : state.martLogoUrl,
      martLogoFile:
          fieldName == "martLogoFile" ? fieldValue : state.martLogoFile,
      martCoverImages:
          fieldName == "martCoverImages"
              ? List<String>.from(fieldValue)
              : state.martCoverImages,
      martCoverFiles:
          fieldName == "martCoverFiles"
              ? List<File>.from(fieldValue)
              : state.martCoverFiles,
      bankHolder: fieldName == "bankHolder" ? fieldValue : state.bankHolder,
      bankAccountNumber:
          fieldName == "bankAccountNumber"
              ? fieldValue
              : state.bankAccountNumber,
      bankIFSC: fieldName == "bankIFSC" ? fieldValue : state.bankIFSC,
      bankUPI: fieldName == "bankUPI" ? fieldValue : state.bankUPI,
      bankName: fieldName == "bankName" ? fieldValue : state.bankName,
      passbookImage:
          fieldName == "passbookImage" ? fieldValue : state.passbookImage,
      panImage: fieldName == "panImage" ? fieldValue : state.panImage,
      aadharImage: fieldName == "aadharImage" ? fieldValue : state.aadharImage,
      profileImage: state.profileImage,
      profileImageUrl: state.profileImageUrl,
      isProfileComplete: _calculateProfileCompletion(
        state.copyWith(
          fullName: fieldName == "fullName" ? fieldValue : state.fullName,
          phoneNumber:
              fieldName == "phoneNumber" ? fieldValue : state.phoneNumber,
          gender: fieldName == "gender" ? fieldValue : state.gender,
          dob: fieldName == "dob" ? fieldValue : state.dob,
          address: fieldName == "address" ? fieldValue : state.address,
          city: fieldName == "city" ? fieldValue : state.city,
          selectedState:
              fieldName == "selectedState" ? fieldValue : state.selectedState,
          pin: fieldName == "pin" ? fieldValue : state.pin,
          profileImageUrl:
              fieldName == "profileImageUrl"
                  ? fieldValue
                  : state.profileImageUrl,
          role: fieldName == "role" ? fieldValue : state.role,
          mart: fieldName == "mart" ? fieldValue : state.mart,
          counterNumber:
              fieldName == "counterNumber" ? fieldValue : state.counterNumber,
        ),
      ),
      isLoading: false,
      errorMessage: state.errorMessage,
    );
  }

  // bool _calculateProfileCompletion(ProfileState s) {
  //   final role = s.role.toLowerCase();
  //   final basicFields = [
  //     s.fullName,
  //     s.phoneNumber,
  //     s.gender,
  //     s.dob?.toIso8601String() ?? "",
  //     s.address,
  //     s.city,
  //     s.selectedState,
  //     s.pin,
  //     s.profileImageUrl,
  //     s.role,
  //   ];

  //   final isBasicComplete = basicFields.every(
  //     (val) => val.toString().trim().isNotEmpty,
  //   );

  //   if (!isBasicComplete) return false;

  //   if (role == "cashier") {
  //     return s.mart.trim().isNotEmpty && s.counterNumber.trim().isNotEmpty;
  //   } else if (role == "customer") {
  //     return s.mart.trim().isNotEmpty;
  //   } else if (role == "admin") {
  //     return true;
  //   }

  //   return false;
  // }

  bool _calculateProfileCompletion(ProfileState s) {
    final role = s.role.toLowerCase();
    final basicFields = [
      s.fullName,
      s.phoneNumber,
      s.gender,
      s.dob?.toIso8601String() ?? "",
      s.address,
      s.city,
      s.selectedState,
      s.pin,
      s.profileImageUrl,
      s.role,
    ];

    final isBasicComplete = basicFields.every(
      (val) => val.toString().trim().isNotEmpty,
    );

    if (!isBasicComplete) return false;

    if (role == "cashier") {
      return s.mart.trim().isNotEmpty && s.counterNumber.trim().isNotEmpty;
    } else if (role == "customer") {
      return true; // ✅ Changed: Customer only needs basic info
    } else if (role == "admin") {
      return true;
    }

    return false;
  }

  Future<void> saveProfile(BuildContext context, WidgetRef ref) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = ProfileState.error("User not logged in");
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      final role = state.role.toLowerCase();
      final isCashier = role == "cashier";
      final isAdmin = role == "admin";

      final Map<String, dynamic> updatedProfileData = {
        // ✅ Basic profile
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

      if (isAdmin) {
        // ✅ Add mart details
        updatedProfileData.addAll({
          "martName": state.martName.trim(),
          "martContact": state.martContact.trim(),
          "martAddress": state.martAddress.trim(),
          "martCity": state.martCity.trim(),
          "martState": state.martState.trim(),
          "martPinCode": state.martPinCode.trim(),
          "martGstin": state.martGstin.trim(),
          "martCin": state.martCin.trim(),
          "martLogoUrl": state.martLogoUrl.trim(),
          "martCoverImages": List<String>.from(state.martCoverImages),
        });

        // ✅ Add bank details
        updatedProfileData.addAll({
          "accountHolder": state.bankHolder.trim(),
          "accountNumber": state.bankAccountNumber.trim(),
          "ifscCode": state.bankIFSC.trim(),
          "upiId": state.bankUPI.trim(),
          "bankInfo": state.bankName ?? "",
          "passbookBase64":
              state.passbookImage != null
                  ? base64Encode(await state.passbookImage!.readAsBytes())
                  : "",
          "panBase64":
              state.panImage != null
                  ? base64Encode(await state.panImage!.readAsBytes())
                  : "",
          "aadharBase64":
              state.aadharImage != null
                  ? base64Encode(await state.aadharImage!.readAsBytes())
                  : "",
        });
      }

      // ✅ Determine if profile is complete
      final isComplete = () {
        if (isAdmin) return true;
        if (isCashier) {
          return [
            state.fullName,
            state.phoneNumber,
            state.gender,
            state.dob?.toIso8601String(),
            state.address,
            state.city,
            state.selectedState,
            state.pin,
            state.profileImageUrl,
            state.role,
            state.mart,
            state.counterNumber,
          ].every((val) => val != null && val.toString().trim().isNotEmpty);
        }
        if (role == "customer") {
          return [
            state.fullName,
            state.phoneNumber,
            state.gender,
            state.dob?.toIso8601String(),
            state.address,
            state.city,
            state.selectedState,
            state.pin,
            state.profileImageUrl,
            state.role,
            // ✅ Removed `mart` from here for customer
          ].every((val) => val != null && val.toString().trim().isNotEmpty);
        }

        return false;
      }();

      updatedProfileData["isProfileComplete"] = isComplete;

      // 🔄 Save to Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(updatedProfileData, SetOptions(merge: true));

      // 🔄 Save to Realtime DB (optional)
      await FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(user.uid)
          .update(updatedProfileData);

      ref.invalidate(profileImageProvider);
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(isLoading: false, isProfileComplete: isComplete);

      debugPrint("✅ Profile saved successfully:");
      updatedProfileData.forEach((k, v) => debugPrint("  $k: $v"));

      // ⏩ Navigate only if user is not admin
      if (context.mounted && !isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => AppRoutes.getHomeScreen(state.role, isComplete),
          ),
        );
      }
    } catch (e) {
      state = ProfileState.error("Error saving profile: ${e.toString()}");
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

  final String martName;
  final String martContact;
  final String martAddress;
  final String martCity;
  final String martState;
  final String martPinCode;
  final String martGstin;
  final String martCin;

  final String martLogoUrl;
  final File? martLogoFile;
  final List<String> martCoverImages;
  final List<File> martCoverFiles;

  final String bankHolder;
  final String bankAccountNumber;
  final String bankIFSC;
  final String bankUPI;
  final String? bankName;
  final File? passbookImage;
  final File? panImage;
  final File? aadharImage;

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
    required this.martName,
    required this.martContact,
    required this.martAddress,
    required this.martCity,
    required this.martState,
    required this.martPinCode,
    required this.martGstin,
    required this.martCin,
    required this.martLogoUrl,
    required this.martLogoFile,
    required this.martCoverImages,
    required this.martCoverFiles,
    required this.bankHolder,
    required this.bankAccountNumber,
    required this.bankIFSC,
    required this.bankUPI,
    this.bankName,
    this.passbookImage,
    this.panImage,
    this.aadharImage,
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
      martName: "",
      martContact: "",
      martAddress: "",
      martCity: "",
      martState: "",
      martPinCode: "",
      martGstin: "",
      martCin: "",
      martLogoUrl: "",
      martLogoFile: null,
      martCoverImages: [],
      martCoverFiles: [],
      bankHolder: "",
      bankAccountNumber: "",
      bankIFSC: "",
      bankUPI: "",
      bankName: null,
      passbookImage: null,
      panImage: null,
      aadharImage: null,
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
      martName: "",
      martContact: "",
      martAddress: "",
      martCity: "",
      martState: "",
      martPinCode: "",
      martGstin: "",
      martCin: "",
      martLogoUrl: "",
      martLogoFile: null,
      martCoverImages: [],
      martCoverFiles: [],
      bankHolder: "",
      bankAccountNumber: "",
      bankIFSC: "",
      bankUPI: "",
      bankName: null,
      passbookImage: null,
      panImage: null,
      aadharImage: null,
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
    String? martName,
    String? martContact,
    String? martAddress,
    String? martCity,
    String? martState,
    String? martPinCode,
    String? martGstin,
    String? martCin,
    String? martLogoUrl,
    File? martLogoFile,
    List<String>? martCoverImages,
    List<File>? martCoverFiles,
    String? bankHolder,
    String? bankAccountNumber,
    String? bankIFSC,
    String? bankUPI,
    String? bankName,
    File? passbookImage,
    File? panImage,
    File? aadharImage,
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
      martName: martName ?? this.martName,
      martContact: martContact ?? this.martContact,
      martAddress: martAddress ?? this.martAddress,
      martCity: martCity ?? this.martCity,
      martState: martState ?? this.martState,
      martPinCode: martPinCode ?? this.martPinCode,
      martGstin: martGstin ?? this.martGstin,
      martCin: martCin ?? this.martCin,
      martLogoUrl: martLogoUrl ?? this.martLogoUrl,
      martLogoFile: martLogoFile ?? this.martLogoFile,
      martCoverImages: martCoverImages ?? this.martCoverImages,
      martCoverFiles: martCoverFiles ?? this.martCoverFiles,
      bankHolder: bankHolder ?? this.bankHolder,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIFSC: bankIFSC ?? this.bankIFSC,
      bankUPI: bankUPI ?? this.bankUPI,
      bankName: bankName ?? this.bankName,
      passbookImage: passbookImage ?? this.passbookImage,
      panImage: panImage ?? this.panImage,
      aadharImage: aadharImage ?? this.aadharImage,
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:nexabill/providers/home_provider.dart';
// import 'package:nexabill/services/role_routes.dart';
// import 'package:nexabill/ui/screens/mart_details_screen.dart';
// import 'package:path_provider/path_provider.dart';

// final profileFutureProvider = FutureProvider<Map<String, dynamic>>((ref) async {
//   User? user = FirebaseAuth.instance.currentUser;
//   if (user == null) throw Exception("User not logged in");

//   DocumentSnapshot userDoc =
//       await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

//   if (userDoc.exists) {
//     final data = userDoc.data() as Map<String, dynamic>;

//     ref.read(selectedGenderProvider.notifier).state = data["gender"] ?? "Male";
//     ref.read(selectedStateProvider.notifier).state = data["state"] ?? "";

//     return data;
//   }

//   throw Exception("User profile not found");
// });

// final profileNotifierProvider =
//     StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
//       return ProfileNotifier(ref);
//     });

// final selectedGenderProvider = StateProvider<String>((ref) => "Male");
// final selectedStateProvider = StateProvider<String?>((ref) => null);

// class ProfileNotifier extends StateNotifier<ProfileState> {
//   ProfileNotifier(this.ref) : super(ProfileState.initial());

//   final Ref ref;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseDatabase _database = FirebaseDatabase.instance;

//   Future<void> loadProfile(WidgetRef ref) async {
//     User? user = _auth.currentUser;
//     if (user == null) {
//       state = ProfileState.error("User not logged in");
//       return;
//     }

//     try {
//       state = state.copyWith(isLoading: true);

//       DocumentSnapshot userDoc =
//           await _firestore.collection("users").doc(user.uid).get();
//       final userData = userDoc.data() as Map<String, dynamic>?;

//       if (userData == null) {
//         state = ProfileState.error("User profile not found");
//         return;
//       }

//       // Gender & State Riverpod sync
//       ref.read(selectedGenderProvider.notifier).state =
//           userData["gender"] ?? "Male";
//       ref.read(selectedStateProvider.notifier).state = userData["state"] ?? "";

//       // Decode images
//       final profileBase64 = userData["profileImageUrl"];
//       final profileImageFile = await decodeBase64ToImage(profileBase64 ?? "");

//       final martLogoBase64 = userData["martLogoUrl"];
//       final martLogoFile = await decodeBase64ToImage(martLogoBase64 ?? "");

//       List<String> martCoverBase64List = [];
//       List<File> martCoverFileList = [];

//       if (userData["martCoverImages"] is List) {
//         martCoverBase64List = List<String>.from(userData["martCoverImages"]);
//         for (final base64 in martCoverBase64List) {
//           final file = await decodeBase64ToImage(base64);
//           if (file != null) martCoverFileList.add(file);
//         }
//       }

//       final role = userData["role"] ?? "customer";

//       state = state.copyWith(
//         isLoading: false,
//         fullName: userData["fullName"] ?? "",
//         phoneNumber: userData["phoneNumber"] ?? "",
//         email: user.email ?? "",
//         gender: userData["gender"] ?? "Male",
//         dob:
//             userData["dob"] != null ? DateTime.tryParse(userData["dob"]) : null,
//         address: userData["address"] ?? "",
//         city: userData["city"] ?? "",
//         selectedState: userData["state"] ?? "",
//         pin: userData["pin"] ?? "",
//         profileImage: profileImageFile,
//         profileImageUrl: profileBase64 ?? "",
//         role: role,
//         mart: userData["mart"] ?? "",
//         counterNumber: userData["counterNumber"] ?? "",
//         martName: userData["martName"] ?? "",
//         martContact: userData["martContact"] ?? "",
//         martAddress: userData["martAddress"] ?? "",
//         martCity: userData["martCity"] ?? "",
//         martState: userData["martState"] ?? "",
//         martPinCode: userData["martPinCode"] ?? "",
//         martGstin: userData["martGstin"] ?? "",
//         martCin: userData["martCin"] ?? "",
//         martLogoUrl: martLogoBase64 ?? "",
//         martLogoFile: martLogoFile,
//         martCoverImages: martCoverBase64List,
//         martCoverFiles: martCoverFileList,

//         // 🔒 Prevent premature profile completion for Admin
//         isProfileComplete:
//             (role == "admin")
//                 ? false
//                 : (userData["isProfileComplete"] ?? false),
//       );

//       debugPrint("✅ Profile data, mart logo & covers loaded successfully.");
//     } catch (e) {
//       state = ProfileState.error("Error loading profile: ${e.toString()}");
//     }
//   }

//   Future<void> pickAndUploadImage(WidgetRef ref) async {
//     try {
//       debugPrint("📸 Triggered image picker for profile");
//       final pickedFile = await ImagePicker().pickImage(
//         source: ImageSource.gallery,
//       );

//       if (pickedFile == null) {
//         debugPrint("❌ No image selected");
//         return;
//       }

//       final imageFile = File(pickedFile.path);
//       final compressedBytes = await _compressImage(imageFile);
//       final base64String = base64Encode(compressedBytes);

//       await uploadProfileImage(base64String, ref);
//     } catch (e) {
//       debugPrint("❌ Error picking and uploading image: $e");
//     }
//   }

//   Future<List<int>> _compressImage(File imageFile, {int quality = 50}) async {
//     try {
//       if (!imageFile.existsSync()) {
//         debugPrint("❌ File does not exist: ${imageFile.path}");
//         return [];
//       }

//       final compressedBytes = await FlutterImageCompress.compressWithFile(
//         imageFile.path,
//         quality: quality.clamp(10, 100),
//         format: CompressFormat.jpeg,
//       );

//       if (compressedBytes == null) {
//         debugPrint("⚠️ Compression returned null, using original file");
//         return await imageFile.readAsBytes();
//       }

//       debugPrint("✅ Image compressed successfully");
//       return compressedBytes;
//     } catch (e) {
//       debugPrint("❌ Image compression failed: $e");
//       return await imageFile.readAsBytes();
//     }
//   }

//   Future<void> pickMartLogo(BuildContext context, WidgetRef ref) async {
//     try {
//       final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//       if (picked == null) return;

//       final File logoFile = File(picked.path);
//       final compressedBytes = await _compressImage(logoFile);
//       final base64Logo = base64Encode(compressedBytes);

//       state = state.copyWith(martLogoFile: logoFile, martLogoUrl: base64Logo);

//       updateProfileField("martLogoUrl", base64Logo, ref);
//       updateProfileField("martLogoFile", logoFile, ref);

//       debugPrint("✅ Mart logo updated in provider");
//     } catch (e) {
//       debugPrint("❌ Error picking mart logo: $e");
//     }
//   }

//   Future<void> pickMartCoverImages(BuildContext context, WidgetRef ref) async {
//     final ImagePicker picker = ImagePicker();

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (_) {
//         return StatefulBuilder(
//           builder:
//               (context, setModalState) => Container(
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).scaffoldBackgroundColor,
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(16),
//                   ),
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "Mart Cover Images",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.add_circle_outline),
//                           onPressed: () async {
//                             final picked = await picker.pickMultiImage();
//                             if (picked.isEmpty) return;

//                             final List<File> files = [];
//                             final List<String> base64List = [];

//                             for (var img in picked) {
//                               final file = File(img.path);
//                               final compressed = await _compressImage(file);
//                               final base64 = base64Encode(compressed);
//                               files.add(file);
//                               base64List.add(base64);
//                             }

//                             final updatedFiles = [
//                               ...state.martCoverFiles,
//                               ...files,
//                             ];
//                             final updatedBase64 = [
//                               ...state.martCoverImages,
//                               ...base64List,
//                             ];

//                             setModalState(() {
//                               state = state.copyWith(
//                                 martCoverFiles: updatedFiles,
//                                 martCoverImages: updatedBase64,
//                               );
//                             });

//                             updateProfileField(
//                               "martCoverFiles",
//                               updatedFiles,
//                               ref,
//                             );
//                             updateProfileField(
//                               "martCoverImages",
//                               updatedBase64,
//                               ref,
//                             );

//                             debugPrint(
//                               "✅ Mart cover images updated in provider",
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     SizedBox(
//                       height: 100,
//                       child: ListView.separated(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: state.martCoverFiles.length,
//                         separatorBuilder: (_, __) => const SizedBox(width: 10),
//                         itemBuilder: (context, index) {
//                           return Stack(
//                             children: [
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   state.martCoverFiles[index],
//                                   width: 100,
//                                   height: 100,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                               Positioned(
//                                 top: 0,
//                                 right: 0,
//                                 child: GestureDetector(
//                                   onTap: () {
//                                     final updatedFiles = [
//                                       ...state.martCoverFiles,
//                                     ]..removeAt(index);
//                                     final updatedBase64 = [
//                                       ...state.martCoverImages,
//                                     ]..removeAt(index);

//                                     setModalState(() {
//                                       state = state.copyWith(
//                                         martCoverFiles: updatedFiles,
//                                         martCoverImages: updatedBase64,
//                                       );
//                                     });

//                                     updateProfileField(
//                                       "martCoverFiles",
//                                       updatedFiles,
//                                       ref,
//                                     );
//                                     updateProfileField(
//                                       "martCoverImages",
//                                       updatedBase64,
//                                       ref,
//                                     );
//                                   },
//                                   child: const CircleAvatar(
//                                     radius: 12,
//                                     backgroundColor: Colors.white,
//                                     child: Icon(
//                                       Icons.close,
//                                       size: 16,
//                                       color: Colors.red,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//         );
//       },
//     );
//   }

//   Future<void> pickBankDocument(String type) async {
//   final picker = ImagePicker();
//   final picked = await picker.pickImage(source: ImageSource.gallery);
//   if (picked != null) {
//     final file = File(picked.path);
//     switch (type) {
//       case 'passbook':
//         state = state.copyWith(passbookImage: file);
//         break;
//       case 'pan':
//         state = state.copyWith(panImage: file);
//         break;
//       case 'aadhar':
//         state = state.copyWith(aadharImage: file);
//         break;
//     }
//   }
// }

// Future<void> fetchBankDetailsFromIFSC(String ifscCode) async {
//   try {
//     final url = Uri.parse("https://ifsc.razorpay.com/$ifscCode");
//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final bank = data['BANK'];
//       final branch = data['BRANCH'];
//       if (bank != null && branch != null) {
//         state = state.copyWith(bankInfo: "$bank, $branch");
//       } else {
//         state = state.copyWith(bankInfo: "Bank details not found");
//       }
//     } else {
//       state = state.copyWith(bankInfo: "Invalid IFSC code");
//     }
//   } catch (e) {
//     state = state.copyWith(bankInfo: "Error fetching bank details");
//   }
// }

//   Future<void> uploadProfileImage(String base64String, WidgetRef ref) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         debugPrint("❌ No user found");
//         return;
//       }

//       // ✅ Update in Firebase Realtime DB (optional)
//       final realtimeRef = FirebaseDatabase.instance
//           .ref()
//           .child("users")
//           .child(user.uid);
//       await realtimeRef.update({"profileImageBase64": base64String});

//       // ✅ Update in Firestore
//       final firestoreRef = FirebaseFirestore.instance
//           .collection("users")
//           .doc(user.uid);
//       await firestoreRef.update({"profileImageUrl": base64String});

//       // ✅ Update local state
//       final decodedImage = await decodeBase64ToImage(base64String);
//       state = state.copyWith(
//         profileImageUrl: base64String,
//         profileImage: decodedImage,
//       );

//       ref.invalidate(profileImageProvider);
//       await Future.delayed(const Duration(milliseconds: 300));
//       debugPrint("✅ Profile image updated and state refreshed!");
//     } catch (e) {
//       debugPrint("❌ Error updating profile image: $e");
//     }
//   }

//   Future<File?> decodeBase64ToImage(String base64String) async {
//     try {
//       if (base64String.trim().isEmpty) {
//         debugPrint("❌ Base64 string is empty.");
//         return null;
//       }

//       // Fix incorrect padding
//       while (base64String.length % 4 != 0) {
//         base64String += '=';
//       }

//       final bytes = base64Decode(base64String);
//       final tempDir = await getTemporaryDirectory();
//       final filePath =
//           '${tempDir.path}/profile_image_${DateTime.now().millisecondsSinceEpoch}.png';

//       final file = File(filePath);
//       await file.writeAsBytes(bytes);
//       debugPrint("✅ Profile image decoded and saved at: $filePath");

//       return file;
//     } catch (e) {
//       debugPrint("❌ Error decoding Base64 image: $e");
//       return null;
//     }
//   }

//   void updateProfileField(String fieldName, dynamic fieldValue, WidgetRef ref) {
//     // Sync specific providers
//     if (fieldName == "gender") {
//       ref.read(selectedGenderProvider.notifier).state = fieldValue;
//     } else if (fieldName == "selectedState") {
//       ref.read(selectedStateProvider.notifier).state = fieldValue;
//     }

//     state = state.copyWith(
//       fullName: fieldName == "fullName" ? fieldValue : state.fullName,
//       phoneNumber: fieldName == "phoneNumber" ? fieldValue : state.phoneNumber,
//       gender: fieldName == "gender" ? fieldValue : state.gender,
//       dob: fieldName == "dob" ? fieldValue : state.dob,
//       address: fieldName == "address" ? fieldValue : state.address,
//       city: fieldName == "city" ? fieldValue : state.city,
//       selectedState:
//           fieldName == "selectedState" ? fieldValue : state.selectedState,
//       pin: fieldName == "pin" ? fieldValue : state.pin,
//       role: fieldName == "role" ? fieldValue : state.role,
//       mart: fieldName == "mart" ? fieldValue : state.mart,
//       counterNumber:
//           fieldName == "counterNumber" ? fieldValue : state.counterNumber,
//       martName: fieldName == "martName" ? fieldValue : state.martName,
//       martContact: fieldName == "martContact" ? fieldValue : state.martContact,
//       martAddress: fieldName == "martAddress" ? fieldValue : state.martAddress,
//       martCity: fieldName == "martCity" ? fieldValue : state.martCity,
//       martState: fieldName == "martState" ? fieldValue : state.martState,
//       martPinCode: fieldName == "martPinCode" ? fieldValue : state.martPinCode,
//       martGstin: fieldName == "martGstin" ? fieldValue : state.martGstin,
//       martCin: fieldName == "martCin" ? fieldValue : state.martCin,
//       martLogoUrl: fieldName == "martLogoUrl" ? fieldValue : state.martLogoUrl,
//       martLogoFile:
//           fieldName == "martLogoFile" ? fieldValue : state.martLogoFile,
//       martCoverImages:
//           fieldName == "martCoverImages"
//               ? List<String>.from(fieldValue)
//               : state.martCoverImages,
//       martCoverFiles:
//           fieldName == "martCoverFiles"
//               ? List<File>.from(fieldValue)
//               : state.martCoverFiles,
//       // Static state values
//       profileImage: state.profileImage,
//       profileImageUrl: state.profileImageUrl,
//       isProfileComplete: state.isProfileComplete,
//       isLoading: false,
//       errorMessage: state.errorMessage,
//     );
//   }

//   Future<void> saveProfile(BuildContext context, WidgetRef ref) async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       state = ProfileState.error("User not logged in");
//       return;
//     }

//     try {
//       state = state.copyWith(isLoading: true);

//       final role = state.role.toLowerCase();
//       final isCashier = role == "cashier";
//       final isAdmin = role == "admin";

//       // 🔗 Basic profile fields for all users
//       final Map<String, dynamic> updatedProfileData = {
//         "fullName": state.fullName.trim(),
//         "phoneNumber": state.phoneNumber.trim(),
//         "gender": state.gender,
//         "dob": state.dob?.toIso8601String() ?? "",
//         "address": state.address.trim(),
//         "city": state.city.trim(),
//         "state": state.selectedState.trim(),
//         "pin": state.pin.trim(),
//         "profileImageUrl": state.profileImageUrl,
//         "role": state.role,
//         "mart": state.mart,
//         "counterNumber": state.counterNumber,
//       };

//       // 👨‍💼 Admin-specific mart info
//       if (isAdmin) {
//         updatedProfileData.addAll({
//           "martName": state.martName.trim(),
//           "martContact": state.martContact.trim(),
//           "martAddress": state.martAddress.trim(),
//           "martCity": state.martCity.trim(),
//           "martState": state.martState.trim(),
//           "martPinCode": state.martPinCode.trim(),
//           "martGstin": state.martGstin.trim(),
//           "martCin": state.martCin.trim(),
//           "martLogoUrl": state.martLogoUrl.trim(),
//           "martCoverImages": List<String>.from(state.martCoverImages),
//         });
//       }

//       // ✅ Determine profile completion
//       final requiredFields = [
//         state.fullName,
//         state.phoneNumber,
//         state.gender,
//         state.dob?.toIso8601String() ?? "",
//         state.address,
//         state.city,
//         state.selectedState,
//         state.pin,
//         state.profileImageUrl,
//         state.role,
//         if (isCashier) state.mart,
//         if (isCashier) state.counterNumber,
//       ];

//       final bool isComplete =
//           !isAdmin &&
//           requiredFields.every(
//             (val) => val != null && val.toString().trim().isNotEmpty,
//           );

//       updatedProfileData["isProfileComplete"] = isComplete;

//       // 🔄 Firestore update
//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(user.uid)
//           .set(updatedProfileData, SetOptions(merge: true));

//       // 🔄 Realtime DB update (optional)
//       await FirebaseDatabase.instance
//           .ref()
//           .child("users")
//           .child(user.uid)
//           .update(updatedProfileData);

//       // ✅ Update state
//       ref.invalidate(profileImageProvider);
//       await Future.delayed(const Duration(milliseconds: 300));

//       state = state.copyWith(isLoading: false, isProfileComplete: isComplete);

//       debugPrint("✅ Profile saved successfully:");
//       updatedProfileData.forEach((k, v) => debugPrint("  $k: $v"));

//       // ⏩ Leave navigation to the UI (no redirect here for admin)
//       if (context.mounted && !isAdmin) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (context) => AppRoutes.getHomeScreen(state.role, isComplete),
//           ),
//         );
//       }
//     } catch (e) {
//       state = ProfileState.error("Error saving profile: ${e.toString()}");
//     }
//   }
// }

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
//   final String selectedState;
//   final String pin;
//   final File? profileImage;
//   final String profileImageUrl;
//   final bool isProfileComplete;
//   final String role;
//   final String mart;
//   final String counterNumber;

//   // 🔹 Admin-only mart details
//   final String martName;
//   final String martContact;
//   final String martAddress;
//   final String martCity;
//   final String martState;
//   final String martPinCode;
//   final String martGstin;
//   final String martCin;

//   // 🔹 Mart image fields
//   final String martLogoUrl;
//   final File? martLogoFile;
//   final List<String> martCoverImages;
//   final List<File> martCoverFiles;

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
//     required this.profileImageUrl,
//     required this.isProfileComplete,
//     required this.role,
//     required this.mart,
//     required this.counterNumber,
//     required this.martName,
//     required this.martContact,
//     required this.martAddress,
//     required this.martCity,
//     required this.martState,
//     required this.martPinCode,
//     required this.martGstin,
//     required this.martCin,
//     required this.martLogoUrl,
//     required this.martLogoFile,
//     required this.martCoverImages,
//     required this.martCoverFiles,
//   });

//   factory ProfileState.initial() {
//     return ProfileState(
//       isLoading: false,
//       errorMessage: null,
//       fullName: "",
//       phoneNumber: "",
//       email: "",
//       gender: "Male",
//       dob: null,
//       address: "",
//       city: "",
//       selectedState: "",
//       pin: "",
//       profileImage: null,
//       profileImageUrl: "",
//       isProfileComplete: false,
//       role: "customer",
//       mart: "",
//       counterNumber: "",
//       martName: "",
//       martContact: "",
//       martAddress: "",
//       martCity: "",
//       martState: "",
//       martPinCode: "",
//       martGstin: "",
//       martCin: "",
//       martLogoUrl: "",
//       martLogoFile: null,
//       martCoverImages: [],
//       martCoverFiles: [],
//     );
//   }

//   factory ProfileState.error(String message) {
//     return ProfileState(
//       isLoading: false,
//       errorMessage: message,
//       fullName: "",
//       phoneNumber: "",
//       email: "",
//       gender: "Male",
//       dob: null,
//       address: "",
//       city: "",
//       selectedState: "",
//       pin: "",
//       profileImage: null,
//       profileImageUrl: "",
//       isProfileComplete: false,
//       role: "customer",
//       mart: "",
//       counterNumber: "",
//       martName: "",
//       martContact: "",
//       martAddress: "",
//       martCity: "",
//       martState: "",
//       martPinCode: "",
//       martGstin: "",
//       martCin: "",
//       martLogoUrl: "",
//       martLogoFile: null,
//       martCoverImages: [],
//       martCoverFiles: [],
//     );
//   }

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
//     String? profileImageUrl,
//     bool? isProfileComplete,
//     String? role,
//     String? mart,
//     String? counterNumber,
//     String? martName,
//     String? martContact,
//     String? martAddress,
//     String? martCity,
//     String? martState,
//     String? martPinCode,
//     String? martGstin,
//     String? martCin,
//     String? martLogoUrl,
//     File? martLogoFile,
//     List<String>? martCoverImages,
//     List<File>? martCoverFiles,
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
//       profileImageUrl: profileImageUrl ?? this.profileImageUrl,
//       isProfileComplete: isProfileComplete ?? this.isProfileComplete,
//       role: role ?? this.role,
//       mart: mart ?? this.mart,
//       counterNumber: counterNumber ?? this.counterNumber,
//       martName: martName ?? this.martName,
//       martContact: martContact ?? this.martContact,
//       martAddress: martAddress ?? this.martAddress,
//       martCity: martCity ?? this.martCity,
//       martState: martState ?? this.martState,
//       martPinCode: martPinCode ?? this.martPinCode,
//       martGstin: martGstin ?? this.martGstin,
//       martCin: martCin ?? this.martCin,
//       martLogoUrl: martLogoUrl ?? this.martLogoUrl,
//       martLogoFile: martLogoFile ?? this.martLogoFile,
//       martCoverImages: martCoverImages ?? this.martCoverImages,
//       martCoverFiles: martCoverFiles ?? this.martCoverFiles,
//     );
//   }
// }
