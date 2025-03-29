import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/data/state_data.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/services/role_routes.dart';
import 'package:nexabill/ui/widgets/custom_dropdown.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MartDetailsScreen extends ConsumerStatefulWidget {
  const MartDetailsScreen({super.key});

  @override
  ConsumerState<MartDetailsScreen> createState() => _MartDetailsScreenState();
}

class _MartDetailsScreenState extends ConsumerState<MartDetailsScreen> {
  final GlobalKey<FormState> _martFormKey = GlobalKey<FormState>();
  late TextEditingController martNameController;
  late TextEditingController martContactController;
  late TextEditingController martAddressController;
  late TextEditingController martCityController;
  late TextEditingController martStateController;
  late TextEditingController martPinCodeController;
  late TextEditingController martGstinController;
  late TextEditingController martCinController;
  Future<void> setLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', route);
  }

  // String? selectedState;
  // File? martLogo;
  // List<File> martCoverImages = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    martNameController = TextEditingController();
    martContactController = TextEditingController();
    martAddressController = TextEditingController();
    martCityController = TextEditingController();
    martStateController = TextEditingController();
    martPinCodeController = TextEditingController();
    martGstinController = TextEditingController();
    martCinController = TextEditingController();

    // Load profile and set data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(ref);

      final profileState = ref.read(profileNotifierProvider);

      martNameController.text = profileState.martName;
      martContactController.text = profileState.martContact;
      martAddressController.text = profileState.martAddress;
      martCityController.text = profileState.martCity;
      martStateController.text = profileState.martState;
      martPinCodeController.text = profileState.martPinCode;
      martGstinController.text = profileState.martGstin;
      martCinController.text = profileState.martCin;

      ref.read(selectedStateProvider.notifier).state =
          profileState.selectedState;
    });
  }

  @override
  void dispose() {
    martNameController.dispose();
    martContactController.dispose();
    martAddressController.dispose();
    martCityController.dispose();
    martStateController.dispose();
    martPinCodeController.dispose();
    martGstinController.dispose();
    martCinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final profileNotifier = ref.read(profileNotifierProvider.notifier);
    final profileState = ref.watch(profileNotifierProvider); // ✅ Add this line
    final martLogo = profileState.martLogoFile;
    final martCoverImages = profileState.martCoverFiles;

    return Scaffold(
      appBar: AppBar(title: const Text('Mart Details')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // 🔹 Cover Image Carousel or Placeholder
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      martCoverImages.isNotEmpty
                          ? CarouselSlider(
                            options: CarouselOptions(
                              viewportFraction: 1.0,
                              autoPlay: true,
                              height: 200,
                            ),
                            items:
                                martCoverImages.map((img) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      img,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 200,
                                    ),
                                  );
                                }).toList(),
                          )
                          : Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              image: const DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(
                                  "https://www.w3schools.com/w3images/mountains.jpg",
                                ),
                              ),
                            ),
                          ),

                      // 🔹 Cover Image Camera Icon
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: GestureDetector(
                          onTap:
                              () => ref
                                  .read(profileNotifierProvider.notifier)
                                  .pickMartCoverImages(context, ref),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.camera_alt, color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Mart Logo Avatar
                Positioned(
                  bottom: -30,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              martLogo != null
                                  ? FileImage(martLogo!)
                                  : const NetworkImage(
                                        "https://www.w3schools.com/w3images/avatar2.png",
                                      )
                                      as ImageProvider,
                        ),
                      ),

                      // 🔹 Logo Camera Icon
                      Positioned(
                        bottom: 8,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            debugPrint("📸 Mart Logo camera icon tapped");
                            ref
                                .read(profileNotifierProvider.notifier)
                                .pickMartLogo(context, ref);
                          },
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Form(
                    key: _martFormKey, // ✅ Ensure this is defined above
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: martNameController,
                          label: "Mart Name",
                          hintText: "Enter mart name",
                          prefixIcon: Icons.store,
                          labelColor: isDarkMode ? Colors.white : Colors.black,
                          prefixIconColor:
                              isDarkMode ? Colors.black54 : Colors.black54,
                          textColor: isDarkMode ? Colors.black : Colors.black,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Mart name is required";
                            }
                            return null;
                          },
                        ),
                        CustomTextField(
                          controller: martContactController,
                          label: "Contact Number",
                          hintText: "Enter contact number",
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone,
                          labelColor: isDarkMode ? Colors.white : Colors.black,
                          prefixIconColor:
                              isDarkMode ? Colors.black54 : Colors.black54,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Contact number is required";
                            }
                            if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                              return "Enter a valid 10-digit phone number";
                            }
                            return null;
                          },
                        ),
                        CustomTextField(
                          controller: martAddressController,
                          label: "Mart Address",
                          hintText: "Enter mart address",
                          prefixIcon: Icons.location_on,
                          labelColor: isDarkMode ? Colors.white : Colors.black,
                          prefixIconColor:
                              isDarkMode ? Colors.black54 : Colors.black54,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Mart address is required";
                            }
                            return null;
                          },
                        ),
                        CustomTextField(
                          controller: martCityController,
                          label: "City",
                          hintText: "Enter city",
                          prefixIcon: Icons.location_city,
                          labelColor: isDarkMode ? Colors.white : Colors.black,
                          prefixIconColor:
                              isDarkMode ? Colors.black54 : Colors.black54,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "City is required";
                            }
                            return null;
                          },
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "State",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            FormField<String>(
                              validator: (value) {
                                if (profileState.martState.isEmpty) {
                                  return "Please select a state";
                                }
                                return null;
                              },
                              builder: (FormFieldState<String> state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomDropdown(
                                      value:
                                          StateData.stateList.contains(
                                                profileState.martState,
                                              )
                                              ? profileState.martState
                                              : null,

                                      hintText: "Select State",
                                      items: StateData.stateList,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              profileNotifierProvider.notifier,
                                            )
                                            .updateProfileField(
                                              "martState",
                                              value,
                                              ref,
                                            );
                                        state.didChange(value);
                                      },
                                      textColor: Colors.black,
                                      hintColor: Colors.black54,
                                      fillColor: Colors.white,
                                      prefixIcon: Icons.map,
                                      iconColor: Colors.black54,
                                    ),
                                    if (state.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                          left: 8,
                                        ),
                                        child: Text(
                                          state.errorText!,
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: martPinCodeController,
                          label: "Pin Code",
                          hintText: "Enter pin code",
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.pin_drop,
                          labelColor: isDarkMode ? Colors.white : Colors.black,
                          prefixIconColor:
                              isDarkMode ? Colors.black54 : Colors.black54,
                          textColor: isDarkMode ? Colors.black : Colors.black,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Pin Code is required";
                            }
                            if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                              return "Enter a valid 6-digit pin code";
                            }
                            return null;
                          },
                        ),

                        CustomTextField(
                          controller: martGstinController,
                          label: "GSTIN",
                          hintText: "Enter GSTIN",
                          prefixIcon: Icons.confirmation_number,
                          labelColor: isDarkMode ? Colors.white : Colors.black,
                          prefixIconColor:
                              isDarkMode ? Colors.black54 : Colors.black54,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "GSTIN is required";
                            }
                            // You can add regex for GSTIN validation here if needed
                            return null;
                          },
                        ),
                        CustomTextField(
                          controller: martCinController,
                          label: "CIN (Optional)",
                          hintText: "Enter CIN (Optional)",
                          prefixIcon: Icons.description,
                          labelColor: isDarkMode ? Colors.white : Colors.black,
                          prefixIconColor:
                              isDarkMode ? Colors.black54 : Colors.black54,
                          validator: (value) {
                            return null; // Optional field
                          },
                        ),
                      ],
                    ),
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     // 🔙 Previous Button (Navigate to Profile)
                  //     ElevatedButton(
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Colors.grey[300],
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(10),
                  //         ),
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 20,
                  //           vertical: 14,
                  //         ),
                  //       ),
                  //       onPressed: () {
                  //         debugPrint("🔙 Navigating to /profile");
                  //         Navigator.pushNamed(context, "/profile");
                  //       },
                  //       child: const Text(
                  //         "Previous",
                  //         style: TextStyle(color: Colors.black, fontSize: 16),
                  //       ),
                  //     ),

                  //     // ✅ Show "Save & Next" only for admin
                  //     profileState.role.toLowerCase() == "admin"
                  //         ? Align(
                  //           alignment: Alignment.centerRight,
                  //           child: ElevatedButton(
                  //             style: ElevatedButton.styleFrom(
                  //               backgroundColor: AppTheme.primaryColor,
                  //               shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(10),
                  //               ),
                  //               padding: const EdgeInsets.symmetric(
                  //                 horizontal: 24,
                  //                 vertical: 14,
                  //               ),
                  //             ),
                  //             onPressed:
                  //                 profileState.isLoading
                  //                     ? null
                  //                     : () async {
                  //                       debugPrint("💾 Save & Next pressed");
                  //                       debugPrint(
                  //                         "📋 Checking mart form values:",
                  //                       );
                  //                       debugPrint(
                  //                         "martName: ${martNameController.text}",
                  //                       );
                  //                       debugPrint(
                  //                         "martContact: ${martContactController.text}",
                  //                       );
                  //                       debugPrint(
                  //                         "martAddress: ${martAddressController.text}",
                  //                       );
                  //                       debugPrint(
                  //                         "martCity: ${martCityController.text}",
                  //                       );
                  //                       debugPrint(
                  //                         "martState: ${martStateController.text}",
                  //                       );
                  //                       debugPrint(
                  //                         "martPinCode: ${martPinCodeController.text}",
                  //                       );
                  //                       debugPrint(
                  //                         "martGstin: ${martGstinController.text}",
                  //                       );
                  //                       debugPrint(
                  //                         "martCin: ${martCinController.text}",
                  //                       );

                  //                       if (_martFormKey.currentState
                  //                               ?.validate() ??
                  //                           false) {
                  //                         debugPrint("✅ Mart form validated");

                  //                         // Update mart fields to state
                  //                         profileNotifier.updateProfileField(
                  //                           "martName",
                  //                           martNameController.text.trim(),
                  //                           ref,
                  //                         );
                  //                         profileNotifier.updateProfileField(
                  //                           "martContact",
                  //                           martContactController.text.trim(),
                  //                           ref,
                  //                         );
                  //                         profileNotifier.updateProfileField(
                  //                           "martAddress",
                  //                           martAddressController.text.trim(),
                  //                           ref,
                  //                         );
                  //                         profileNotifier.updateProfileField(
                  //                           "martCity",
                  //                           martCityController.text.trim(),
                  //                           ref,
                  //                         );
                  //                         // profileNotifier.updateProfileField(
                  //                         //   "martState",
                  //                         //   martStateController.text.trim(),
                  //                         //   ref,
                  //                         // );
                  //                         if (profileState
                  //                             .martState
                  //                             .isNotEmpty) {
                  //                           profileNotifier.updateProfileField(
                  //                             "martState",
                  //                             profileState.martState,
                  //                             ref,
                  //                           );
                  //                         }

                  //                         profileNotifier.updateProfileField(
                  //                           "martPinCode",
                  //                           martPinCodeController.text.trim(),
                  //                           ref,
                  //                         );

                  //                         profileNotifier.updateProfileField(
                  //                           "martGstin",
                  //                           martGstinController.text.trim(),
                  //                           ref,
                  //                         );
                  //                         profileNotifier.updateProfileField(
                  //                           "martCin",
                  //                           martCinController.text.trim(),
                  //                           ref,
                  //                         );

                  //                         debugPrint(
                  //                           "⏳ Calling saveProfile...",
                  //                         );
                  //                         await profileNotifier.saveProfile(
                  //                           context,
                  //                           ref,
                  //                         );
                  //                         debugPrint(
                  //                           "✅ Finished saveProfile call",
                  //                         );

                  //                         // Navigate only if still on this screen
                  //                         if (context.mounted) {
                  //                           debugPrint(
                  //                             "➡️ Navigating to /bank-details",
                  //                           );
                  //                           Navigator.pushNamed(
                  //                             context,
                  //                             "/bank-details",
                  //                           );
                  //                         }
                  //                       } else {
                  //                         debugPrint(
                  //                           "❌ Mart form validation failed",
                  //                         );
                  //                       }
                  //                     },
                  //             child:
                  //                 profileState.isLoading
                  //                     ? const SizedBox(
                  //                       height: 24,
                  //                       width: 24,
                  //                       child: CircularProgressIndicator(
                  //                         color: Colors.white,
                  //                         strokeWidth: 2.5,
                  //                       ),
                  //                     )
                  //                     : const Text(
                  //                       "Save & Next",
                  //                       style: TextStyle(
                  //                         fontSize: 18,
                  //                         color: Colors.white,
                  //                       ),
                  //                     ),
                  //           ),
                  //         )
                  //         : const SizedBox.shrink(), // ❌ No Save for non-admin
                  //   ],
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔙 Previous Button (Navigate to Profile)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () {
                          debugPrint("🔙 Navigating to /profile");
                          Navigator.pushNamed(context, "/profile");
                        },
                        child: const Text(
                          "Previous",
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),

                      // ✅ Show "Save & Next" only for admin
                      profileState.role.toLowerCase() == "admin"
                          ? Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                              onPressed:
                                  profileState.isLoading
                                      ? null
                                      : () async {
                                        debugPrint(
                                          "\uD83D\uDCBE Save & Next pressed",
                                        );
                                        debugPrint(
                                          "\uD83D\uDCCB Validating mart form...",
                                        );

                                        if (_martFormKey.currentState
                                                ?.validate() ??
                                            false) {
                                          debugPrint(
                                            "\u2705 Mart form validated",
                                          );

                                          profileNotifier.updateProfileField(
                                            "martName",
                                            martNameController.text.trim(),
                                            ref,
                                          );
                                          profileNotifier.updateProfileField(
                                            "martContact",
                                            martContactController.text.trim(),
                                            ref,
                                          );
                                          profileNotifier.updateProfileField(
                                            "martAddress",
                                            martAddressController.text.trim(),
                                            ref,
                                          );
                                          profileNotifier.updateProfileField(
                                            "martCity",
                                            martCityController.text.trim(),
                                            ref,
                                          );

                                          if (profileState
                                              .martState
                                              .isNotEmpty) {
                                            profileNotifier.updateProfileField(
                                              "martState",
                                              profileState.martState,
                                              ref,
                                            );
                                          }

                                          profileNotifier.updateProfileField(
                                            "martPinCode",
                                            martPinCodeController.text.trim(),
                                            ref,
                                          );
                                          profileNotifier.updateProfileField(
                                            "martGstin",
                                            martGstinController.text.trim(),
                                            ref,
                                          );
                                          profileNotifier.updateProfileField(
                                            "martCin",
                                            martCinController.text.trim(),
                                            ref,
                                          );

                                          debugPrint(
                                            "\u23F3 Calling saveProfile...",
                                          );
                                          await profileNotifier.saveProfile(
                                            context,
                                            ref,
                                          );
                                          debugPrint(
                                            "\u2705 Finished saveProfile call",
                                          );

                                          debugPrint(
                                            "\uD83D\uDCBE Attempting to set last route as /bank-details...",
                                          );
                                          await AppRoutes.setLastRoute(
                                            '/bank-details',
                                          );
                                          debugPrint(
                                            "\u2705 last_route saved as /bank-details",
                                          );

                                          if (context.mounted) {
                                            debugPrint(
                                              "\u27A1\uFE0F Navigating to /bank-details screen...",
                                            );
                                            Navigator.pushReplacementNamed(
                                              context,
                                              "/bank-details",
                                            );
                                          }
                                        } else {
                                          debugPrint(
                                            "\u274C Mart form validation failed",
                                          );
                                        }
                                      },

                              child:
                                  profileState.isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                      : const Text(
                                        "Save & Next",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'dart:io';

// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/data/state_data.dart';
// import 'package:nexabill/ui/widgets/custom_dropdown.dart';
// import 'package:nexabill/ui/widgets/custom_textfield.dart';

// class MartDetailsScreen extends ConsumerStatefulWidget {
//   const MartDetailsScreen({super.key});

//   @override
//   ConsumerState<MartDetailsScreen> createState() => _MartDetailsScreenState();
// }

// class _MartDetailsScreenState extends ConsumerState<MartDetailsScreen> {
//   final TextEditingController martNameController = TextEditingController();
//   final TextEditingController contactController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController cityController = TextEditingController();
//   final TextEditingController gstinController = TextEditingController();
//   final TextEditingController cinController = TextEditingController();

//   String? selectedState;
//   File? martLogo;
//   List<File> martCoverImages = [];

//   Future<void> pickMartLogo() async {
//     final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() => martLogo = File(picked.path));
//     }
//   }

//   Future<void> pickMartCoverImages() async {
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
//                             final picked = await ImagePicker().pickMultiImage();
//                             if (picked.isNotEmpty) {
//                               setModalState(
//                                 () => martCoverImages.addAll(
//                                   picked.map((e) => File(e.path)),
//                                 ),
//                               );
//                               setState(() {});
//                             }
//                           },
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     SizedBox(
//                       height: 100,
//                       child: ListView.separated(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: martCoverImages.length,
//                         separatorBuilder: (_, __) => const SizedBox(width: 10),
//                         itemBuilder: (context, index) {
//                           return Stack(
//                             children: [
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   martCoverImages[index],
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
//                                     setModalState(
//                                       () => martCoverImages.removeAt(index),
//                                     );
//                                     setState(() {});
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

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Mart Details')),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Stack(
//               alignment: Alignment.bottomCenter,
//               clipBehavior: Clip.none,
//               children: [
//                 SizedBox(
//                   height: 280,
//                   width: double.infinity,
//                   child: Stack(
//                     children: [
//                       martCoverImages.isNotEmpty
//                           ? CarouselSlider(
//                             options: CarouselOptions(
//                               viewportFraction: 1.0,
//                               autoPlay: true,
//                               height: 280,
//                             ),
//                             items:
//                                 martCoverImages.map((img) {
//                                   return Image.file(
//                                     img,
//                                     fit: BoxFit.cover,
//                                     width: double.infinity,
//                                     height: 280,
//                                   );
//                                 }).toList(),
//                           )
//                           : Container(
//                             height: 280,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: AppTheme.primaryColor.withOpacity(0.1),
//                               image: const DecorationImage(
//                                 fit: BoxFit.cover,
//                                 image: NetworkImage(
//                                   "https://www.w3schools.com/w3images/mountains.jpg",
//                                 ),
//                               ),
//                             ),
//                           ),
//                       Positioned(
//                         right: 10,
//                         bottom: 10,
//                         child: GestureDetector(
//                           onTap: pickMartCoverImages,
//                           child: const CircleAvatar(
//                             radius: 20,
//                             backgroundColor: Colors.white,
//                             child: Icon(Icons.camera_alt, color: Colors.blue),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Positioned(
//                   bottom: -55,
//                   child: Stack(
//                     alignment: Alignment.bottomRight,
//                     children: [
//                       GestureDetector(
//                         onTap: pickMartLogo,
//                         child: CircleAvatar(
//                           radius: 55,
//                           backgroundColor: Colors.white,
//                           child:
//                               martLogo != null
//                                   ? CircleAvatar(
//                                     radius: 50,
//                                     backgroundImage: FileImage(martLogo!),
//                                   )
//                                   : const CircleAvatar(
//                                     radius: 50,
//                                     backgroundImage: NetworkImage(
//                                       "https://www.w3schools.com/w3images/avatar2.png",
//                                     ),
//                                   ),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 4,
//                         right: 4,
//                         child: Material(
//                           color: Colors.transparent, // makes sure it's tappable
//                           shape: const CircleBorder(),
//                           child: InkWell(
//                             customBorder: const CircleBorder(),
//                             onTap: () {
//                               debugPrint("📸 Camera icon tapped");
//                               pickMartLogo();
//                             },
//                             child: const Padding(
//                               padding: EdgeInsets.all(4.0),
//                               child: CircleAvatar(
//                                 radius: 16,
//                                 backgroundColor: Colors.white,
//                                 child: Icon(
//                                   Icons.camera_alt,
//                                   size: 16,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 70),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   CustomTextField(
//                     controller: martNameController,
//                     label: "Mart Name",
//                     hintText: "Enter mart name",
//                     prefixIcon: Icons.store,
//                     labelColor: isDarkMode ? Colors.white : Colors.black,
//                     prefixIconColor:
//                         isDarkMode ? Colors.white70 : Colors.black54,
//                     fillColor: isDarkMode ? Colors.white : Colors.black12,
//                     textColor: isDarkMode ? Colors.black : Colors.black,
//                   ),
//                   CustomTextField(
//                     controller: contactController,
//                     label: "Contact Number",
//                     hintText: "Enter contact number",
//                     keyboardType: TextInputType.phone,
//                     prefixIcon: Icons.phone,
//                     labelColor: isDarkMode ? Colors.white : Colors.black,
//                     prefixIconColor:
//                         isDarkMode ? Colors.white70 : Colors.black54,
//                   ),
//                   CustomTextField(
//                     controller: addressController,
//                     label: "Mart Address",
//                     hintText: "Enter mart address",
//                     prefixIcon: Icons.location_on,
//                     labelColor: isDarkMode ? Colors.white : Colors.black,
//                     prefixIconColor:
//                         isDarkMode ? Colors.white70 : Colors.black54,
//                   ),
//                   CustomTextField(
//                     controller: cityController,
//                     label: "City",
//                     hintText: "Enter city",
//                     prefixIcon: Icons.location_city,
//                     labelColor: isDarkMode ? Colors.white : Colors.black,
//                     prefixIconColor:
//                         isDarkMode ? Colors.white70 : Colors.black54,
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "State",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isDarkMode ? Colors.white : Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       CustomDropdown(
//                         value: selectedState,
//                         hintText: "Select State",
//                         items: StateData.stateList,
//                         onChanged:
//                             (value) => setState(() => selectedState = value),
//                         textColor: isDarkMode ? Colors.black : Colors.white,
//                         hintColor: isDarkMode ? Colors.black54 : Colors.white70,
//                         fillColor: isDarkMode ? Colors.white : Colors.black,
//                         prefixIcon: Icons.map,
//                         suffixIcon: Icons.arrow_drop_down,
//                         iconColor: isDarkMode ? Colors.black54 : Colors.white,
//                       ),
//                     ],
//                   ),
//                   CustomTextField(
//                     controller: gstinController,
//                     label: "GSTIN",
//                     hintText: "Enter GSTIN",
//                     prefixIcon: Icons.confirmation_number,
//                     labelColor: isDarkMode ? Colors.white : Colors.black,
//                     prefixIconColor:
//                         isDarkMode ? Colors.white70 : Colors.black54,
//                   ),
//                   CustomTextField(
//                     controller: cinController,
//                     label: "CIN (Optional)",
//                     hintText: "Enter CIN (Optional)",
//                     prefixIcon: Icons.description,
//                     labelColor: isDarkMode ? Colors.white : Colors.black,
//                     prefixIconColor:
//                         isDarkMode ? Colors.white70 : Colors.black54,
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       ElevatedButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text("Previous"),
//                       ),
//                       ElevatedButton(
//                         onPressed: () {
//                           Navigator.pushNamed(context, "/admin/bankDetails");
//                         },
//                         child: const Text("Next & Save"),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
