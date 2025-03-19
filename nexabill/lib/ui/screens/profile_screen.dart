import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/widgets/custom_dropdown.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';
import 'package:nexabill/data/state_data.dart';
import 'dart:io';

class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController pinController;
  late TextEditingController dobController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    fullNameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    cityController = TextEditingController();
    pinController = TextEditingController();
    dobController = TextEditingController();

    // Fetch Profile Data after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(profileNotifierProvider);

      final profileData = ref
          .read(profileFutureProvider)
          .maybeWhen(data: (data) => data, orElse: () => null);

      // Update controllers with fetched or existing data
      fullNameController.text =
          profileData?["fullName"] ?? profileState.fullName;
      phoneController.text =
          profileData?["phoneNumber"] ?? profileState.phoneNumber;
      emailController.text = profileData?["email"] ?? profileState.email;
      addressController.text = profileData?["address"] ?? profileState.address;
      cityController.text = profileData?["city"] ?? profileState.city;
      pinController.text = profileData?["pin"] ?? profileState.pin;

      // DateTime? dob =
      //     profileData?["dob"] != null
      //         ? DateTime.tryParse(profileData?["dob"])
      //         : profileState.dob;
      // dobController.text =
      //     dob != null ? "${dob.day}-${dob.month}-${dob.year}" : "";
      // ✅ Ensure DOB is not reset
      final dobFromFirebase = profileData?["dob"];
      if (dobFromFirebase != null) {
        DateTime? parsedDate = DateTime.tryParse(dobFromFirebase);
        if (parsedDate != null) {
          dobController.text =
              "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
          ref
              .read(profileNotifierProvider.notifier)
              .updateProfileField("dob", parsedDate);
        }
      }
    });
  }

  @override
  void dispose() {
    // Proper cleanup
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    pinController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profileNotifier = ref.read(profileNotifierProvider.notifier);
    final selectedGender = ref.watch(selectedGenderProvider);
    final selectedState = ref.watch(selectedStateProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 230,
                  decoration: const BoxDecoration(
                    color: AppTheme.blueColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(100),
                      bottomRight: Radius.circular(100),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 80),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                profileState.profileImage != null
                                    ? FileImage(profileState.profileImage!)
                                        as ImageProvider<Object>
                                    : const NetworkImage(
                                      "https://www.w3schools.com/w3images/avatar2.png",
                                    ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => profileNotifier.pickImage(),
                            child: const CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt, color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _profileFormKey,
                        child: Column(
                          children: [
                            // CustomTextField(
                            //   controller: TextEditingController.fromValue(
                            //     TextEditingValue(
                            //       text: ref
                            //           .watch(profileFutureProvider)
                            //           .when(
                            //             data:
                            //                 (profileData) =>
                            //                     profileData["fullName"] ??
                            //                     profileState.fullName,
                            //             loading:
                            //                 () =>
                            //                     profileState
                            //                         .fullName, // Keep previous value while loading
                            //             error:
                            //                 (error, _) =>
                            //                     profileState
                            //                         .fullName, // Keep previous value on error
                            //           ),
                            //     ),
                            //   ),
                            //   label: "Full Name",
                            //   hintText: "Enter your full name",
                            //   labelColor:
                            //       isDarkMode
                            //           ? Colors.white
                            //           : Colors.black, // ✅ White in dark mode
                            //   prefixIcon: Icons.person,
                            //   prefixIconColor:
                            //       isDarkMode
                            //           ? AppTheme.secondaryColor
                            //           : Colors
                            //               .black54, // ✅ Secondary color in dark mode
                            //   onChanged:
                            //       (value) => profileNotifier.updateProfileField(
                            //         "fullName",
                            //         value,
                            //       ),
                            // ),
                            CustomTextField(
                              controller: fullNameController,
                              label: "Full Name",
                              hintText: "Enter your full name",
                              labelColor:
                                  isDarkMode
                                      ? Colors.white
                                      : Colors.black, // ✅ White in dark mode
                              prefixIcon: Icons.person,
                              prefixIconColor:
                                  isDarkMode
                                      ? AppTheme.secondaryColor
                                      : Colors
                                          .black54, // ✅ Secondary color in dark mode
                              onChanged: (value) {
                                profileNotifier.updateProfileField(
                                  "fullName",
                                  value,
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start, // ✅ Align label to the left
                              children: [
                                // ✅ Gender Label Positioned Above the Buttons
                                Text(
                                  "Gender",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors
                                                .black, // ✅ White in dark mode
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ), // ✅ Space between label and buttons

                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          ref
                                              .read(
                                                profileNotifierProvider
                                                    .notifier,
                                              )
                                              .updateProfileField(
                                                "gender",
                                                "Male",
                                              );
                                        },
                                        icon: Icon(
                                          Icons.male,
                                          color:
                                              isDarkMode
                                                  ? AppTheme.secondaryColor
                                                  : Colors.black54,
                                        ),
                                        label: Text(
                                          "Male",
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              profileState.gender == "Male"
                                                  ? AppTheme.primaryColor
                                                  : Colors
                                                      .grey[300], // ✅ Correctly Updates State
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          ref
                                              .read(
                                                profileNotifierProvider
                                                    .notifier,
                                              )
                                              .updateProfileField(
                                                "gender",
                                                "Female",
                                              );
                                        },
                                        icon: Icon(
                                          Icons.female,
                                          color:
                                              isDarkMode
                                                  ? AppTheme.secondaryColor
                                                  : Colors.black54,
                                        ),
                                        label: Text(
                                          "Female",
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              profileState.gender == "Female"
                                                  ? AppTheme.primaryColor
                                                  : Colors
                                                      .grey[300], // ✅ Correctly Updates State
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            CustomTextField(
                              controller: TextEditingController(
                                text:
                                    profileState.dob != null
                                        ? "${profileState.dob!.day}-${profileState.dob!.month}-${profileState.dob!.year}"
                                        : "",
                              ),
                              label: "Date of Birth",
                              hintText: "Select your date of birth",
                              labelColor:
                                  isDarkMode
                                      ? Colors.white
                                      : Colors.black, // ✅ White in dark mode
                              prefixIcon: Icons.calendar_today,
                              prefixIconColor:
                                  isDarkMode
                                      ? AppTheme.secondaryColor
                                      : Colors
                                          .black54, // ✅ Secondary color in dark mode
                              readOnly: true,
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      profileState.dob ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  profileNotifier.updateProfileField(
                                    "dob",
                                    pickedDate,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 10),

                            // CustomTextField(
                            //   controller: TextEditingController(
                            //     text: ref
                            //         .watch(profileFutureProvider)
                            //         .when(
                            //           data:
                            //               (profileData) =>
                            //                   profileData["email"] ??
                            //                   profileState.email,
                            //           loading:
                            //               () =>
                            //                   profileState
                            //                       .email, // Show existing state while loading
                            //           error:
                            //               (error, _) =>
                            //                   profileState
                            //                       .email, // Keep previous value on error
                            //         ),
                            //   ),
                            //   label: "Email",
                            //   hintText: "Enter your email",
                            //   labelColor:
                            //       isDarkMode
                            //           ? Colors.white
                            //           : Colors.black, // ✅ White in dark mode
                            //   prefixIcon: Icons.email,
                            //   prefixIconColor:
                            //       isDarkMode
                            //           ? AppTheme.secondaryColor
                            //           : Colors
                            //               .black54, // ✅ Secondary color in dark mode
                            //   readOnly: true,
                            // ),
                            // const SizedBox(height: 10),

                            // CustomTextField(
                            //   controller: TextEditingController(
                            //     text: ref
                            //         .watch(profileFutureProvider)
                            //         .when(
                            //           data:
                            //               (profileData) =>
                            //                   profileData["phoneNumber"] ??
                            //                   profileState.phoneNumber,
                            //           loading:
                            //               () =>
                            //                   profileState
                            //                       .phoneNumber, // Show existing state while loading
                            //           error:
                            //               (error, _) =>
                            //                   profileState
                            //                       .phoneNumber, // Keep previous value on error
                            //         ),
                            //   ),
                            //   label: "Phone Number",
                            //   hintText: "Enter your phone number",
                            //   labelColor:
                            //       isDarkMode
                            //           ? Colors.white
                            //           : Colors.black, // ✅ White in dark mode
                            //   prefixIcon: Icons.phone,
                            //   prefixIconColor:
                            //       isDarkMode
                            //           ? AppTheme.secondaryColor
                            //           : Colors
                            //               .black54, // ✅ Secondary color in dark mode
                            //   onChanged:
                            //       (value) => profileNotifier.updateProfileField(
                            //         "phoneNumber",
                            //         value,
                            //       ),
                            // ),
                            // Email Field (Read-Only)
                            CustomTextField(
                              controller:
                                  emailController, // ✅ Uses initialized controller
                              label: "Email",
                              hintText: "Enter your email",
                              labelColor:
                                  isDarkMode
                                      ? Colors.white
                                      : Colors.black, // ✅ White in dark mode
                              prefixIcon: Icons.email,
                              prefixIconColor:
                                  isDarkMode
                                      ? AppTheme.secondaryColor
                                      : Colors
                                          .black54, // ✅ Secondary color in dark mode
                              readOnly: true, // ✅ Email should not be editable
                            ),
                            const SizedBox(height: 10),

                            // Phone Number Field
                            CustomTextField(
                              controller:
                                  phoneController, // ✅ Uses initialized controller
                              label: "Phone Number",
                              hintText: "Enter your phone number",
                              labelColor:
                                  isDarkMode
                                      ? Colors.white
                                      : Colors.black, // ✅ White in dark mode
                              prefixIcon: Icons.phone,
                              prefixIconColor:
                                  isDarkMode
                                      ? AppTheme.secondaryColor
                                      : Colors
                                          .black54, // ✅ Secondary color in dark mode
                              onChanged:
                                  (value) => profileNotifier.updateProfileField(
                                    "phoneNumber",
                                    value,
                                  ),
                            ),

                            const SizedBox(height: 10),

                            // ✅ Address Field (Newly Added)
                            // CustomTextField(
                            //   controller: TextEditingController(
                            //     text: profileState.address,
                            //   ),
                            //   label: "Address",
                            //   hintText: "Enter your address",
                            //   labelColor:
                            //       isDarkMode
                            //           ? Colors.white
                            //           : Colors.black, // ✅ White in dark mode
                            //   prefixIcon: Icons.location_on,
                            //   prefixIconColor:
                            //       isDarkMode
                            //           ? AppTheme.secondaryColor
                            //           : Colors
                            //               .black54, // ✅ Secondary color in dark mode
                            //   onChanged:
                            //       (value) => profileNotifier.updateProfileField(
                            //         "address",
                            //         value,
                            //       ),
                            // ),
                            CustomTextField(
                              controller: addressController,
                              label: "Address",
                              hintText: "Enter your address",
                              labelColor:
                                  isDarkMode
                                      ? Colors.white
                                      : Colors.black, // ✅ White in dark mode
                              prefixIcon: Icons.location_on,
                              prefixIconColor:
                                  isDarkMode
                                      ? AppTheme.secondaryColor
                                      : Colors
                                          .black54, // ✅ Secondary color in dark mode
                              onChanged:
                                  (value) => profileNotifier.updateProfileField(
                                    "address",
                                    value,
                                  ),
                            ),
                            const SizedBox(height: 10),

                            // CustomTextField(
                            //   controller: TextEditingController(
                            //     text: profileState.city,
                            //   ),
                            //   label: "City",
                            //   hintText: "Enter your city",
                            //   labelColor:
                            //       isDarkMode
                            //           ? Colors.white
                            //           : Colors.black, // ✅ White in dark mode
                            //   prefixIcon: Icons.location_city,
                            //   prefixIconColor:
                            //       isDarkMode
                            //           ? AppTheme.secondaryColor
                            //           : Colors
                            //               .black54, // ✅ Secondary color in dark mode
                            //   onChanged:
                            //       (value) => profileNotifier.updateProfileField(
                            //         "city",
                            //         value,
                            //       ),
                            // ),

                            // City Field
                            CustomTextField(
                              controller:
                                  cityController, // ✅ Uses initialized controller
                              label: "City",
                              hintText: "Enter your city",
                              labelColor:
                                  isDarkMode
                                      ? Colors.white
                                      : Colors.black, // ✅ White in dark mode
                              prefixIcon: Icons.location_city,
                              prefixIconColor:
                                  isDarkMode
                                      ? AppTheme.secondaryColor
                                      : Colors
                                          .black54, // ✅ Secondary color in dark mode
                              onChanged:
                                  (value) => profileNotifier.updateProfileField(
                                    "city",
                                    value,
                                  ),
                            ),

                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "State",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors
                                                .black, // ✅ White in dark mode
                                  ),
                                ),
                                const SizedBox(height: 5),
                                CustomDropdown(
                                  value: selectedState,
                                  hintText: "Select your state",
                                  items: StateData.stateList,
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      ref
                                          .read(selectedStateProvider.notifier)
                                          .state = newValue;
                                      profileNotifier.updateProfileField(
                                        "selectedState",
                                        newValue,
                                      ); // ✅ Ensure state is saved
                                    }
                                  },
                                  textColor:
                                      isDarkMode ? Colors.black : Colors.white,
                                  hintColor:
                                      isDarkMode
                                          ? Colors.black54
                                          : Colors
                                              .white70, // ✅ Fixed Hint Color
                                  fillColor:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black, // ✅ Fixed Background
                                  prefixIcon:
                                      Icons
                                          .location_on, // ✅ Optional Prefix Icon
                                  suffixIcon:
                                      Icons
                                          .arrow_drop_down, // ✅ Optional Suffix Icon
                                  iconColor:
                                      isDarkMode
                                          ? AppTheme.secondaryColor
                                          : Colors
                                              .black54, // ✅ Secondary color in dark mode
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),
                            // Pin Code Field
                            CustomTextField(
                              controller:
                                  pinController, // ✅ Uses initialized controller
                              keyboardType: TextInputType.number,
                              label: "Pin Code",
                              hintText: "Enter your pin code",
                              labelColor:
                                  isDarkMode
                                      ? Colors.white
                                      : Colors.black, // ✅ White in dark mode
                              prefixIcon: Icons.pin,
                              prefixIconColor:
                                  isDarkMode
                                      ? AppTheme.secondaryColor
                                      : Colors
                                          .black54, // ✅ Secondary color in dark mode
                              onChanged:
                                  (value) => profileNotifier.updateProfileField(
                                    "pin",
                                    value,
                                  ),
                            ),

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child:
                              // ElevatedButton(
                              //   style: ElevatedButton.styleFrom(
                              //     backgroundColor:
                              //         AppTheme
                              //             .primaryColor, // ✅ Use primary color from theme
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(
                              //         10,
                              //       ), // ✅ Matches text field shape
                              //     ),
                              //     padding: const EdgeInsets.symmetric(
                              //       vertical: 14,
                              //     ), // ✅ Consistent padding
                              //   ),
                              //   onPressed:
                              //       profileState.isLoading
                              //           ? null
                              //           : () async {
                              //             if (_profileFormKey.currentState!
                              //                 .validate()) {
                              //               // ✅ Ensure all data is updated before saving
                              //               profileNotifier.updateProfileField(
                              //                 "fullName",
                              //                 fullNameController.text.trim(),
                              //               );
                              //               profileNotifier.updateProfileField(
                              //                 "phoneNumber",
                              //                 phoneController.text.trim(),
                              //               );
                              //               profileNotifier.updateProfileField(
                              //                 "address",
                              //                 addressController.text.trim(),
                              //               );
                              //               profileNotifier.updateProfileField(
                              //                 "city",
                              //                 cityController.text.trim(),
                              //               );
                              //               profileNotifier.updateProfileField(
                              //                 "pin",
                              //                 pinController.text.trim(),
                              //               );
                              //               await profileNotifier.saveProfile(
                              //                 context,
                              //                 ref,
                              //               );
                              //             }
                              //           },
                              //   child:
                              //       profileState.isLoading
                              //           ? const CircularProgressIndicator(
                              //             color: Colors.white,
                              //           )
                              //           : const Text(
                              //             "Save",
                              //             style: TextStyle(
                              //               fontSize: 18,
                              //               color: Colors.white,
                              //             ),
                              //           ),
                              // ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme
                                          .primaryColor, // ✅ Use primary color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed:
                                    profileState.isLoading
                                        ? null
                                        : () async {
                                          if (_profileFormKey.currentState!
                                              .validate()) {
                                            // ✅ Update all fields before saving
                                            profileNotifier.updateProfileField(
                                              "fullName",
                                              fullNameController.text.trim(),
                                            );
                                            profileNotifier.updateProfileField(
                                              "phoneNumber",
                                              phoneController.text.trim(),
                                            );
                                            profileNotifier.updateProfileField(
                                              "address",
                                              addressController.text.trim(),
                                            );
                                            profileNotifier.updateProfileField(
                                              "city",
                                              cityController.text.trim(),
                                            );
                                            profileNotifier.updateProfileField(
                                              "pin",
                                              pinController.text.trim(),
                                            );

                                            // ✅ Save Profile and Rebuild UI
                                            await profileNotifier.saveProfile(
                                              context,
                                              ref,
                                            );
                                          }
                                        },
                                child:
                                    profileState.isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : const Text(
                                          "Save",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/ui/widgets/custom_textfield.dart';
// import 'package:nexabill/data/state_data.dart'; // ✅ Corrected import path

// class ProfileScreen extends ConsumerWidget {
//   ProfileScreen({super.key});

//   // final _formKey = GlobalKey<FormState>();
//   final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final profileState = ref.watch(profileNotifierProvider);
//     final profileFuture = ref.watch(profileFutureProvider);

//     final selectedGender = ref.watch(selectedGenderProvider);
//     final selectedState = ref.watch(selectedStateProvider);
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     const TextStyle labelStyle = TextStyle(
//       fontSize: 16,
//       fontWeight: FontWeight.bold,
//     );

//     return Scaffold(
//       body: SingleChildScrollView(
//         child: SizedBox(
//           width: double.infinity,
//           child: Stack(
//             children: [
//               // ✅ Background Blue Design
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   height: 230,
//                   decoration: const BoxDecoration(
//                     color: Colors.blue,
//                     borderRadius: BorderRadius.only(
//                       bottomLeft: Radius.circular(100),
//                       bottomRight: Radius.circular(100),
//                     ),
//                   ),
//                 ),
//               ),

//               SafeArea(
//                 child: profileFuture.when(
//                   loading:
//                       () => const Center(child: CircularProgressIndicator()),
//                   error:
//                       (error, stackTrace) =>
//                           Center(child: Text("Error: ${error.toString()}")),
//                   data: (profileData) {
//                     final nameController = TextEditingController.fromValue(
//                       TextEditingValue(text: profileState.fullName),
//                     );

//                     final phoneController = TextEditingController.fromValue(
//                       TextEditingValue(text: profileState.phoneNumber),
//                     );

//                     final emailController = TextEditingController.fromValue(
//                       TextEditingValue(text: profileState.email),
//                     );

//                     final addressController = TextEditingController.fromValue(
//                       TextEditingValue(text: profileState.address),
//                     );

//                     final cityController = TextEditingController.fromValue(
//                       TextEditingValue(text: profileState.city),
//                     );

//                     final pinController = TextEditingController.fromValue(
//                       TextEditingValue(text: profileState.pin),
//                     );

//                     DateTime? selectedDate =
//                         profileData["dob"] != null
//                             ? DateTime.tryParse(profileData["dob"])
//                             : null;

//                     return SizedBox(
//                       width: double.infinity,
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 30),
//                           const Text(
//                             "Profile",
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),

//                           const SizedBox(height: 80),

//                           // ✅ Profile Image with Camera Icon
//                           Stack(
//                             alignment: Alignment.center,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(5),
//                                 decoration: const BoxDecoration(
//                                   color: Colors.white,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: CircleAvatar(
//                                   radius: 50,
//                                   backgroundImage:
//                                       profileState.profileImage != null
//                                           ? FileImage(
//                                             profileState.profileImage!,
//                                           )
//                                           : const NetworkImage(
//                                                 "https://www.w3schools.com/w3images/avatar2.png",
//                                               )
//                                               as ImageProvider,
//                                 ),
//                               ),
//                               Positioned(
//                                 bottom: 2,
//                                 right: 2,
//                                 child: GestureDetector(
//                                   onTap:
//                                       () =>
//                                           ref
//                                               .read(
//                                                 profileNotifierProvider
//                                                     .notifier,
//                                               )
//                                               .pickImage(),
//                                   child: const CircleAvatar(
//                                     radius: 15,
//                                     backgroundColor: Colors.white,
//                                     child: Icon(
//                                       Icons.camera_alt,
//                                       color: Colors.blue,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 20),

//                           Padding(
//                             padding: const EdgeInsets.all(20),
//                             child: Form(
//                               // key: _formKey,
//                               key: _profileFormKey,
//                               child: SizedBox(
//                                 width: double.infinity,
//                                 child: Column(
//                                   children: [
//                                     CustomTextField(
//                                       // controller: nameController,
//                                       controller: TextEditingController(
//                                         text:
//                                             ref
//                                                 .watch(profileNotifierProvider)
//                                                 .fullName,
//                                       ),
//                                       label: "Full Name",
//                                       hintText: "Enter your full name",
//                                       labelColor:
//                                           isDarkMode
//                                               ? AppTheme.whiteColor
//                                               : AppTheme
//                                                   .blackColor, // ✅ Dynamic label color
//                                       prefixIcon:
//                                           Icons.person, // ✅ Profile Icon
//                                       prefixIconColor:
//                                           isDarkMode
//                                               ? AppTheme.secondaryColor
//                                               : AppTheme
//                                                   .blackColor, // ✅ Dynamic icon color
//                                       onChanged: (value) {
//                                         ref
//                                             .read(
//                                               profileNotifierProvider.notifier,
//                                             )
//                                             .updateProfileField(
//                                               "fullName",
//                                               value,
//                                             );
//                                       },
//                                     ),

//                                     // ✅ Modern Gender Selection
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           "Gender",
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                             color:
//                                                 Theme.of(context).brightness ==
//                                                         Brightness.dark
//                                                     ? Colors
//                                                         .white // ✅ White in dark mode
//                                                     : Colors
//                                                         .black, // ✅ Black in light mode
//                                           ),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Row(
//                                           children: [
//                                             Expanded(
//                                               child: ElevatedButton.icon(
//                                                 onPressed: () {
//                                                   ref
//                                                       .read(
//                                                         selectedGenderProvider
//                                                             .notifier,
//                                                       )
//                                                       .state = "Male";
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                   backgroundColor:
//                                                       selectedGender == "Male"
//                                                           ? AppTheme
//                                                               .primaryColor
//                                                           : Colors.grey[300],
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           12,
//                                                         ),
//                                                   ),
//                                                 ),
//                                                 icon: Icon(
//                                                   Icons.male,
//                                                   color:
//                                                       Theme.of(
//                                                                 context,
//                                                               ).brightness ==
//                                                               Brightness.dark
//                                                           ? AppTheme
//                                                               .secondaryColor // ✅ Bright Cyan in Dark Mode
//                                                           : Colors
//                                                               .white, // ✅ White in Light Mode
//                                                 ),
//                                                 label: Text(
//                                                   "Male",
//                                                   style: TextStyle(
//                                                     color:
//                                                         selectedGender == "Male"
//                                                             ? Colors.white
//                                                             : Colors.black,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(height: 10),

//                                             const SizedBox(height: 10),

//                                             // ✅ Date of Birth Field with Date Picker
//                                             CustomTextField(
//                                               controller: TextEditingController(
//                                                 text:
//                                                     ref
//                                                                 .watch(
//                                                                   profileNotifierProvider,
//                                                                 )
//                                                                 .dob !=
//                                                             null
//                                                         ? "${ref.watch(profileNotifierProvider).dob!.day}-${ref.watch(profileNotifierProvider).dob!.month}-${ref.watch(profileNotifierProvider).dob!.year}"
//                                                         : "", // ✅ Show Selected Date
//                                               ),
//                                               label: "Date of Birth",
//                                               hintText:
//                                                   "Select your date of birth",
//                                               labelColor:
//                                                   isDarkMode
//                                                       ? Colors.white
//                                                       : Colors.black,
//                                               prefixIcon: Icons.calendar_today,
//                                               prefixIconColor:
//                                                   isDarkMode
//                                                       ? AppTheme.secondaryColor
//                                                       : Colors.black54,
//                                               readOnly: true,
//                                               onTap: () async {
//                                                 DateTime?
//                                                 pickedDate = await showDatePicker(
//                                                   context: context,
//                                                   initialDate:
//                                                       ref
//                                                           .watch(
//                                                             profileNotifierProvider,
//                                                           )
//                                                           .dob ??
//                                                       DateTime.now(),
//                                                   firstDate: DateTime(1900),
//                                                   lastDate: DateTime.now(),
//                                                 );

//                                                 if (pickedDate != null) {
//                                                   ref
//                                                       .read(
//                                                         profileNotifierProvider
//                                                             .notifier,
//                                                       )
//                                                       .updateProfileField(
//                                                         "dob",
//                                                         pickedDate,
//                                                       );
//                                                 }
//                                               },
//                                             ),

//                                             const SizedBox(width: 10),
//                                             Expanded(
//                                               child: ElevatedButton.icon(
//                                                 onPressed: () {
//                                                   ref
//                                                       .read(
//                                                         selectedGenderProvider
//                                                             .notifier,
//                                                       )
//                                                       .state = "Female";
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                   backgroundColor:
//                                                       selectedGender == "Female"
//                                                           ? AppTheme
//                                                               .primaryColor
//                                                           : Colors.grey[300],
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           12,
//                                                         ),
//                                                   ),
//                                                 ),
//                                                 icon: Icon(
//                                                   Icons.female,
//                                                   color:
//                                                       Theme.of(
//                                                                 context,
//                                                               ).brightness ==
//                                                               Brightness.dark
//                                                           ? AppTheme
//                                                               .secondaryColor // ✅ Bright Cyan in Dark Mode
//                                                           : Colors
//                                                               .white, // ✅ White in Light Mode
//                                                 ),
//                                                 label: Text(
//                                                   "Female",
//                                                   style: TextStyle(
//                                                     color:
//                                                         selectedGender ==
//                                                                 "Female"
//                                                             ? Colors.white
//                                                             : Colors.black,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),

//                                     const SizedBox(height: 10),

//                                     CustomTextField(
//                                       controller: TextEditingController(
//                                         text:
//                                             ref
//                                                 .watch(profileNotifierProvider)
//                                                 .phoneNumber,
//                                       ),
//                                       label: "Phone Number",
//                                       hintText: "Enter your phone number",
//                                       labelColor:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors
//                                                   .black, // ✅ Dynamic label color
//                                       prefixIcon: Icons.phone,
//                                       prefixIconColor:
//                                           isDarkMode
//                                               ? AppTheme.secondaryColor
//                                               : Colors
//                                                   .black54, // ✅ Secondary color in dark mode
//                                       onChanged: (value) {
//                                         ref
//                                             .read(
//                                               profileNotifierProvider.notifier,
//                                             )
//                                             .updateProfileField(
//                                               "phoneNumber",
//                                               value,
//                                             );
//                                       },
//                                     ),

//                                     CustomTextField(
//                                       controller: TextEditingController(
//                                         text:
//                                             ref
//                                                 .watch(profileNotifierProvider)
//                                                 .email,
//                                       ),
//                                       label: "Email",
//                                       hintText: "Enter your email",
//                                       readOnly: true,
//                                       labelColor:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors
//                                                   .black, // ✅ Dynamic label color
//                                       prefixIcon: Icons.email,
//                                       prefixIconColor:
//                                           isDarkMode
//                                               ? AppTheme.secondaryColor
//                                               : Colors
//                                                   .black54, // ✅ Secondary color in dark mode
//                                     ),

//                                     CustomTextField(
//                                       controller: TextEditingController(
//                                         text:
//                                             ref
//                                                 .watch(profileNotifierProvider)
//                                                 .address,
//                                       ),
//                                       label: "Address",
//                                       hintText: "Enter your address",
//                                       labelColor:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors
//                                                   .black, // ✅ Dynamic label color
//                                       prefixIcon: Icons.location_on,
//                                       prefixIconColor:
//                                           isDarkMode
//                                               ? AppTheme.secondaryColor
//                                               : Colors
//                                                   .black54, // ✅ Secondary color in dark mode
//                                       onChanged: (value) {
//                                         ref
//                                             .read(
//                                               profileNotifierProvider.notifier,
//                                             )
//                                             .updateProfileField(
//                                               "address",
//                                               value,
//                                             );
//                                       },
//                                     ),

//                                     CustomTextField(
//                                       controller: TextEditingController(
//                                         text:
//                                             ref
//                                                 .watch(profileNotifierProvider)
//                                                 .city,
//                                       ),
//                                       label: "City",
//                                       hintText: "Enter your city",
//                                       labelColor:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors
//                                                   .black, // ✅ Dynamic label color
//                                       prefixIcon: Icons.location_city,
//                                       prefixIconColor:
//                                           isDarkMode
//                                               ? AppTheme.secondaryColor
//                                               : Colors
//                                                   .black54, // ✅ Secondary color in dark mode
//                                       onChanged: (value) {
//                                         ref
//                                             .read(
//                                               profileNotifierProvider.notifier,
//                                             )
//                                             .updateProfileField("city", value);
//                                       },
//                                     ),

//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           "State",
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                             color:
//                                                 Theme.of(context).brightness ==
//                                                         Brightness.dark
//                                                     ? AppTheme
//                                                         .whiteColor // ✅ White text in dark mode
//                                                     : AppTheme.blackColor,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 5),

//                                         DropdownButtonFormField<String>(
//                                           value:
//                                               ref
//                                                   .watch(
//                                                     profileNotifierProvider,
//                                                   )
//                                                   .selectedState, // ✅ Persist State
//                                           hint: Text(
//                                             "Select your state",
//                                             style: TextStyle(
//                                               color:
//                                                   Theme.of(
//                                                             context,
//                                                           ).brightness ==
//                                                           Brightness.dark
//                                                       ? AppTheme
//                                                           .lightGrey // ✅ Grey hint text in dark mode
//                                                       : AppTheme.textColor,
//                                             ),
//                                           ),
//                                           onChanged: (String? newValue) {
//                                             if (newValue != null) {
//                                               ref
//                                                   .read(
//                                                     profileNotifierProvider
//                                                         .notifier,
//                                                   )
//                                                   .updateProfileField(
//                                                     "selectedState",
//                                                     newValue,
//                                                   );
//                                             }
//                                           },
//                                           items:
//                                               StateData.stateList
//                                                   .map(
//                                                     (state) => DropdownMenuItem<
//                                                       String
//                                                     >(
//                                                       value: state,
//                                                       child: Text(
//                                                         state,
//                                                         style: TextStyle(
//                                                           color:
//                                                               Theme.of(
//                                                                         context,
//                                                                       ).brightness ==
//                                                                       Brightness
//                                                                           .dark
//                                                                   ? AppTheme
//                                                                       .blackColor // ✅ Black text in dark mode
//                                                                   : AppTheme
//                                                                       .textColor,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   )
//                                                   .toList(),
//                                           decoration: InputDecoration(
//                                             filled: true,
//                                             fillColor:
//                                                 Theme.of(context).brightness ==
//                                                         Brightness.dark
//                                                     ? AppTheme
//                                                         .whiteColor // ✅ White field in dark mode
//                                                     : AppTheme.whiteColor,
//                                             border: OutlineInputBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                               borderSide: BorderSide(
//                                                 color: AppTheme.primaryColor,
//                                               ), // ✅ Border color
//                                             ),
//                                             prefixIcon: Icon(
//                                               Icons.location_on,
//                                               color:
//                                                   AppTheme
//                                                       .secondaryColor, // ✅ Bright Cyan for Prefix Icon
//                                             ),
//                                             suffixIcon: Icon(
//                                               Icons.arrow_drop_down,
//                                               color:
//                                                   AppTheme
//                                                       .primaryColor, // ✅ Deep Blue for Suffix Icon
//                                             ),
//                                           ),
//                                           dropdownColor:
//                                               AppTheme
//                                                   .whiteColor, // ✅ Dropdown menu white in dark mode
//                                         ),
//                                       ],
//                                     ),

//                                     const SizedBox(height: 15),

//                                     CustomTextField(
//                                       controller: TextEditingController(
//                                         text:
//                                             ref
//                                                 .watch(profileNotifierProvider)
//                                                 .pin,
//                                       ),
//                                       label: "Pin Code",
//                                       hintText: "Enter your pin code",
//                                       labelColor:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors
//                                                   .black, // ✅ Dynamic label color
//                                       prefixIcon: Icons.pin,
//                                       prefixIconColor:
//                                           isDarkMode
//                                               ? AppTheme.secondaryColor
//                                               : Colors
//                                                   .black54, // ✅ Secondary color in dark mode
//                                       onChanged: (value) {
//                                         ref
//                                             .read(
//                                               profileNotifierProvider.notifier,
//                                             )
//                                             .updateProfileField("pin", value);
//                                       },
//                                     ),

//                                     const SizedBox(height: 20),

//                                     SizedBox(
//                                       width: double.infinity,
//                                       child: ElevatedButton(
//                                         style: ElevatedButton.styleFrom(
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 12,
//                                           ),
//                                           backgroundColor:
//                                               ref
//                                                       .watch(
//                                                         profileNotifierProvider,
//                                                       )
//                                                       .isLoading
//                                                   ? Colors
//                                                       .grey // ✅ Disabled color when saving
//                                                   : AppTheme
//                                                       .primaryColor, // ✅ Primary Color from Theme
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               12,
//                                             ),
//                                           ),
//                                         ),
//                                         onPressed:
//                                             profileState.isLoading
//                                                 ? null
//                                                 : () {
//                                                   if (_profileFormKey
//                                                       .currentState!
//                                                       .validate()) {
//                                                     final notifier = ref.read(
//                                                       profileNotifierProvider
//                                                           .notifier,
//                                                     );

//                                                     Map<String, dynamic>
//                                                     updatedFields = {
//                                                       "fullName":
//                                                           nameController.text
//                                                               .trim(),
//                                                       "phoneNumber":
//                                                           phoneController.text
//                                                               .trim(),
//                                                       "gender": selectedGender,
//                                                       "dob":
//                                                           profileState.dob
//                                                               ?.toIso8601String(),
//                                                       "address":
//                                                           addressController.text
//                                                               .trim(),
//                                                       "city":
//                                                           cityController.text
//                                                               .trim(),
//                                                       "selectedState":
//                                                           selectedState!,
//                                                       "pin":
//                                                           pinController.text
//                                                               .trim(),
//                                                     };

//                                                     // ✅ Only update fields that have changed
//                                                     updatedFields.forEach((
//                                                       key,
//                                                       value,
//                                                     ) {
//                                                       if (profileState
//                                                               .toJson()[key] !=
//                                                           value) {
//                                                         notifier
//                                                             .updateProfileField(
//                                                               key,
//                                                               value,
//                                                             );
//                                                       }
//                                                     });

//                                                     notifier.saveProfile();
//                                                   }
//                                                 },

//                                         child:
//                                             ref
//                                                     .watch(
//                                                       profileNotifierProvider,
//                                                     )
//                                                     .isLoading
//                                                 ? const CircularProgressIndicator(
//                                                   color:
//                                                       Colors
//                                                           .white, // ✅ Loading Indicator while saving
//                                                 )
//                                                 : const Text(
//                                                   "Save",
//                                                   style: TextStyle(
//                                                     fontSize: 18,
//                                                     color: Colors.white,
//                                                   ),
//                                                 ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/ui/widgets/custom_textfield.dart';
// import 'package:nexabill/data/state_data.dart'; // ✅ Corrected import path

// class ProfileScreen extends ConsumerWidget {
//   ProfileScreen({super.key});

//   // final _formKey = GlobalKey<FormState>();
//   final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final profileState = ref.watch(profileNotifierProvider);
//     final profileFuture = ref.watch(profileFutureProvider);

//     final selectedGender = ref.watch(selectedGenderProvider);
//     final selectedState = ref.watch(selectedStateProvider);
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     const TextStyle labelStyle = TextStyle(
//       fontSize: 16,
//       fontWeight: FontWeight.bold,
//     );

//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Stack(
//           children: [
//             // ✅ Background Blue Design
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 height: 230,
//                 decoration: const BoxDecoration(
//                   color: Colors.blue,
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(100),
//                     bottomRight: Radius.circular(100),
//                   ),
//                 ),
//               ),
//             ),

//             SafeArea(
//               child: profileFuture.when(
//                 loading: () => const Center(child: CircularProgressIndicator()),
//                 error:
//                     (error, stackTrace) =>
//                         Center(child: Text("Error: ${error.toString()}")),
//                 data: (profileData) {
//                   final nameController = TextEditingController(
//                     text: profileData["fullName"] ?? "",
//                   );
//                   final phoneController = TextEditingController(
//                     text: profileData["phoneNumber"] ?? "",
//                   );
//                   final emailController = TextEditingController(
//                     text: profileData["email"] ?? "",
//                   );
//                   final addressController = TextEditingController(
//                     text: profileData["address"] ?? "",
//                   );
//                   final cityController = TextEditingController(
//                     text: profileData["city"] ?? "",
//                   );
//                   final pinController = TextEditingController(
//                     text: profileData["pin"] ?? "",
//                   );

//                   DateTime? selectedDate =
//                       profileData["dob"] != null
//                           ? DateTime.tryParse(profileData["dob"])
//                           : null;

//                   return Column(
//                     children: [
//                       const SizedBox(height: 30),
//                       const Text(
//                         "Profile",
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),

//                       const SizedBox(height: 80),

//                       // ✅ Profile Image with Camera Icon
//                       Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(5),
//                             decoration: const BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                             ),
//                             child: CircleAvatar(
//                               radius: 50,
//                               backgroundImage:
//                                   profileState.profileImage != null
//                                       ? FileImage(profileState.profileImage!)
//                                       : const NetworkImage(
//                                             "https://www.w3schools.com/w3images/avatar2.png",
//                                           )
//                                           as ImageProvider,
//                             ),
//                           ),
//                           Positioned(
//                             bottom: 2,
//                             right: 2,
//                             child: GestureDetector(
//                               onTap:
//                                   () =>
//                                       ref
//                                           .read(
//                                             profileNotifierProvider.notifier,
//                                           )
//                                           .pickImage(),
//                               child: const CircleAvatar(
//                                 radius: 15,
//                                 backgroundColor: Colors.white,
//                                 child: Icon(
//                                   Icons.camera_alt,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 20),

//                       Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Form(
//                           // key: _formKey,
//                           key: _profileFormKey,
//                           child: Column(
//                             children: [
//                               CustomTextField(
//                                 // controller: nameController,
//                                 controller: TextEditingController(
//                                   text:
//                                       ref
//                                           .watch(profileNotifierProvider)
//                                           .fullName,
//                                 ),
//                                 label: "Full Name",
//                                 hintText: "Enter your full name",
//                                 labelColor:
//                                     isDarkMode
//                                         ? AppTheme.whiteColor
//                                         : AppTheme
//                                             .blackColor, // ✅ Dynamic label color
//                                 prefixIcon: Icons.person, // ✅ Profile Icon
//                                 prefixIconColor:
//                                     isDarkMode
//                                         ? AppTheme.secondaryColor
//                                         : AppTheme
//                                             .blackColor, // ✅ Dynamic icon color
//                                 onChanged: (value) {
//                                   ref
//                                       .read(profileNotifierProvider.notifier)
//                                       .updateProfileField("fullName", value);
//                                 },
//                               ),

//                               // ✅ Modern Gender Selection
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "Gender",
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color:
//                                           Theme.of(context).brightness ==
//                                                   Brightness.dark
//                                               ? Colors
//                                                   .white // ✅ White in dark mode
//                                               : Colors
//                                                   .black, // ✅ Black in light mode
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: ElevatedButton.icon(
//                                           onPressed: () {
//                                             ref
//                                                 .read(
//                                                   selectedGenderProvider
//                                                       .notifier,
//                                                 )
//                                                 .state = "Male";
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 selectedGender == "Male"
//                                                     ? AppTheme.primaryColor
//                                                     : Colors.grey[300],
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           icon: Icon(
//                                             Icons.male,
//                                             color:
//                                                 Theme.of(context).brightness ==
//                                                         Brightness.dark
//                                                     ? AppTheme
//                                                         .secondaryColor // ✅ Bright Cyan in Dark Mode
//                                                     : Colors
//                                                         .white, // ✅ White in Light Mode
//                                           ),
//                                           label: Text(
//                                             "Male",
//                                             style: TextStyle(
//                                               color:
//                                                   selectedGender == "Male"
//                                                       ? Colors.white
//                                                       : Colors.black,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 10),

//                                       const SizedBox(height: 10),

//                                       // ✅ Date of Birth Field with Date Picker
//                                       CustomTextField(
//                                         controller: TextEditingController(
//                                           text:
//                                               ref
//                                                           .watch(
//                                                             profileNotifierProvider,
//                                                           )
//                                                           .dob !=
//                                                       null
//                                                   ? "${ref.watch(profileNotifierProvider).dob!.day}-${ref.watch(profileNotifierProvider).dob!.month}-${ref.watch(profileNotifierProvider).dob!.year}"
//                                                   : "", // ✅ Show Selected Date if available
//                                         ),
//                                         label: "Date of Birth",
//                                         hintText: "Select your date of birth",
//                                         labelColor:
//                                             isDarkMode
//                                                 ? Colors.white
//                                                 : Colors
//                                                     .black, // ✅ Dynamic label color
//                                         prefixIcon:
//                                             Icons
//                                                 .calendar_today, // ✅ Calendar Icon
//                                         prefixIconColor:
//                                             isDarkMode
//                                                 ? AppTheme.secondaryColor
//                                                 : Colors.black54,
//                                         readOnly:
//                                             true, // ✅ Prevent Keyboard Input
//                                         onTap: () async {
//                                           // ✅ Open Date Picker on Tap
//                                           DateTime?
//                                           pickedDate = await showDatePicker(
//                                             context: context,
//                                             initialDate:
//                                                 ref
//                                                     .watch(
//                                                       profileNotifierProvider,
//                                                     )
//                                                     .dob ??
//                                                 DateTime.now(),
//                                             firstDate: DateTime(1900),
//                                             lastDate: DateTime.now(),
//                                           );

//                                           if (pickedDate != null) {
//                                             ref
//                                                 .read(
//                                                   profileNotifierProvider
//                                                       .notifier,
//                                                 )
//                                                 .updateProfileField(
//                                                   "dob",
//                                                   pickedDate,
//                                                 );
//                                           }
//                                         },
//                                       ),

//                                       const SizedBox(width: 10),
//                                       Expanded(
//                                         child: ElevatedButton.icon(
//                                           onPressed: () {
//                                             ref
//                                                 .read(
//                                                   selectedGenderProvider
//                                                       .notifier,
//                                                 )
//                                                 .state = "Female";
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 selectedGender == "Female"
//                                                     ? AppTheme.primaryColor
//                                                     : Colors.grey[300],
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           icon: Icon(
//                                             Icons.female,
//                                             color:
//                                                 Theme.of(context).brightness ==
//                                                         Brightness.dark
//                                                     ? AppTheme
//                                                         .secondaryColor // ✅ Bright Cyan in Dark Mode
//                                                     : Colors
//                                                         .white, // ✅ White in Light Mode
//                                           ),
//                                           label: Text(
//                                             "Female",
//                                             style: TextStyle(
//                                               color:
//                                                   selectedGender == "Female"
//                                                       ? Colors.white
//                                                       : Colors.black,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),

//                               const SizedBox(height: 10),

//                               CustomTextField(
//                                 controller: TextEditingController(
//                                   text:
//                                       ref
//                                           .watch(profileNotifierProvider)
//                                           .phoneNumber,
//                                 ),
//                                 label: "Phone Number",
//                                 hintText: "Enter your phone number",
//                                 labelColor:
//                                     isDarkMode
//                                         ? Colors.white
//                                         : Colors.black, // ✅ Dynamic label color
//                                 prefixIcon: Icons.phone,
//                                 prefixIconColor:
//                                     isDarkMode
//                                         ? AppTheme.secondaryColor
//                                         : Colors
//                                             .black54, // ✅ Secondary color in dark mode
//                                 onChanged: (value) {
//                                   ref
//                                       .read(profileNotifierProvider.notifier)
//                                       .updateProfileField("phoneNumber", value);
//                                 },
//                               ),

//                               CustomTextField(
//                                 controller: TextEditingController(
//                                   text:
//                                       ref.watch(profileNotifierProvider).email,
//                                 ),
//                                 label: "Email",
//                                 hintText: "Enter your email",
//                                 readOnly: true,
//                                 labelColor:
//                                     isDarkMode
//                                         ? Colors.white
//                                         : Colors.black, // ✅ Dynamic label color
//                                 prefixIcon: Icons.email,
//                                 prefixIconColor:
//                                     isDarkMode
//                                         ? AppTheme.secondaryColor
//                                         : Colors
//                                             .black54, // ✅ Secondary color in dark mode
//                               ),

//                               CustomTextField(
//                                 controller: TextEditingController(
//                                   text:
//                                       ref
//                                           .watch(profileNotifierProvider)
//                                           .address,
//                                 ),
//                                 label: "Address",
//                                 hintText: "Enter your address",
//                                 labelColor:
//                                     isDarkMode
//                                         ? Colors.white
//                                         : Colors.black, // ✅ Dynamic label color
//                                 prefixIcon: Icons.location_on,
//                                 prefixIconColor:
//                                     isDarkMode
//                                         ? AppTheme.secondaryColor
//                                         : Colors
//                                             .black54, // ✅ Secondary color in dark mode
//                                 onChanged: (value) {
//                                   ref
//                                       .read(profileNotifierProvider.notifier)
//                                       .updateProfileField("address", value);
//                                 },
//                               ),

//                               CustomTextField(
//                                 controller: TextEditingController(
//                                   text: ref.watch(profileNotifierProvider).city,
//                                 ),
//                                 label: "City",
//                                 hintText: "Enter your city",
//                                 labelColor:
//                                     isDarkMode
//                                         ? Colors.white
//                                         : Colors.black, // ✅ Dynamic label color
//                                 prefixIcon: Icons.location_city,
//                                 prefixIconColor:
//                                     isDarkMode
//                                         ? AppTheme.secondaryColor
//                                         : Colors
//                                             .black54, // ✅ Secondary color in dark mode
//                                 onChanged: (value) {
//                                   ref
//                                       .read(profileNotifierProvider.notifier)
//                                       .updateProfileField("city", value);
//                                 },
//                               ),

//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "State",
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color:
//                                           Theme.of(context).brightness ==
//                                                   Brightness.dark
//                                               ? AppTheme
//                                                   .whiteColor // ✅ White text in dark mode
//                                               : AppTheme.blackColor,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 5),

//                                   DropdownButtonFormField<String>(
//                                     value:
//                                         ref
//                                             .watch(profileNotifierProvider)
//                                             .selectedState, // ✅ Persist State
//                                     hint: Text(
//                                       "Select your state",
//                                       style: TextStyle(
//                                         color:
//                                             Theme.of(context).brightness ==
//                                                     Brightness.dark
//                                                 ? AppTheme
//                                                     .lightGrey // ✅ Grey hint text in dark mode
//                                                 : AppTheme.textColor,
//                                       ),
//                                     ),
//                                     onChanged: (String? newValue) {
//                                       if (newValue != null) {
//                                         ref
//                                             .read(
//                                               profileNotifierProvider.notifier,
//                                             )
//                                             .updateProfileField(
//                                               "selectedState",
//                                               newValue,
//                                             );
//                                       }
//                                     },
//                                     items:
//                                         StateData.stateList
//                                             .map(
//                                               (
//                                                 state,
//                                               ) => DropdownMenuItem<String>(
//                                                 value: state,
//                                                 child: Text(
//                                                   state,
//                                                   style: TextStyle(
//                                                     color:
//                                                         Theme.of(
//                                                                   context,
//                                                                 ).brightness ==
//                                                                 Brightness.dark
//                                                             ? AppTheme
//                                                                 .blackColor // ✅ Black text in dark mode
//                                                             : AppTheme
//                                                                 .textColor,
//                                                   ),
//                                                 ),
//                                               ),
//                                             )
//                                             .toList(),
//                                     decoration: InputDecoration(
//                                       filled: true,
//                                       fillColor:
//                                           Theme.of(context).brightness ==
//                                                   Brightness.dark
//                                               ? AppTheme
//                                                   .whiteColor // ✅ White field in dark mode
//                                               : AppTheme.whiteColor,
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                         borderSide: BorderSide(
//                                           color: AppTheme.primaryColor,
//                                         ), // ✅ Border color
//                                       ),
//                                       prefixIcon: Icon(
//                                         Icons.location_on,
//                                         color:
//                                             AppTheme
//                                                 .secondaryColor, // ✅ Bright Cyan for Prefix Icon
//                                       ),
//                                       suffixIcon: Icon(
//                                         Icons.arrow_drop_down,
//                                         color:
//                                             AppTheme
//                                                 .primaryColor, // ✅ Deep Blue for Suffix Icon
//                                       ),
//                                     ),
//                                     dropdownColor:
//                                         AppTheme
//                                             .whiteColor, // ✅ Dropdown menu white in dark mode
//                                   ),
//                                 ],
//                               ),

//                               const SizedBox(height: 15),

//                               CustomTextField(
//                                 controller: TextEditingController(
//                                   text: ref.watch(profileNotifierProvider).pin,
//                                 ),
//                                 label: "Pin Code",
//                                 hintText: "Enter your pin code",
//                                 labelColor:
//                                     isDarkMode
//                                         ? Colors.white
//                                         : Colors.black, // ✅ Dynamic label color
//                                 prefixIcon: Icons.pin,
//                                 prefixIconColor:
//                                     isDarkMode
//                                         ? AppTheme.secondaryColor
//                                         : Colors
//                                             .black54, // ✅ Secondary color in dark mode
//                                 onChanged: (value) {
//                                   ref
//                                       .read(profileNotifierProvider.notifier)
//                                       .updateProfileField("pin", value);
//                                 },
//                               ),

//                               const SizedBox(height: 20),

//                               SizedBox(
//                                 width: double.infinity,
//                                 child: ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     backgroundColor:
//                                         ref
//                                                 .watch(profileNotifierProvider)
//                                                 .isLoading
//                                             ? Colors
//                                                 .grey // ✅ Disabled color when saving
//                                             : AppTheme
//                                                 .primaryColor, // ✅ Primary Color from Theme
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   onPressed:
//                                       ref
//                                               .watch(profileNotifierProvider)
//                                               .isLoading
//                                           ? null // ✅ Disable button while saving
//                                           : () {
//                                             if (_profileFormKey.currentState!
//                                                 .validate()) {
//                                               final notifier = ref.read(
//                                                 profileNotifierProvider
//                                                     .notifier,
//                                               );

//                                               notifier.updateProfileField(
//                                                 "fullName",
//                                                 nameController.text.trim(),
//                                               );
//                                               notifier.updateProfileField(
//                                                 "phoneNumber",
//                                                 phoneController.text.trim(),
//                                               );
//                                               notifier.updateProfileField(
//                                                 "gender",
//                                                 selectedGender,
//                                               );
//                                               notifier.updateProfileField(
//                                                 "dob",
//                                                 ref
//                                                     .watch(
//                                                       profileNotifierProvider,
//                                                     )
//                                                     .dob, // ✅ Updated DOB logic
//                                               );
//                                               notifier.updateProfileField(
//                                                 "address",
//                                                 addressController.text.trim(),
//                                               );
//                                               notifier.updateProfileField(
//                                                 "city",
//                                                 cityController.text.trim(),
//                                               );
//                                               notifier.updateProfileField(
//                                                 "selectedState",
//                                                 selectedState!,
//                                               );
//                                               notifier.updateProfileField(
//                                                 "pin",
//                                                 pinController.text.trim(),
//                                               );

//                                               notifier
//                                                   .saveProfile(); // ✅ Saves updated fields
//                                             }
//                                           },
//                                   child:
//                                       ref
//                                               .watch(profileNotifierProvider)
//                                               .isLoading
//                                           ? const CircularProgressIndicator(
//                                             color:
//                                                 Colors
//                                                     .white, // ✅ Loading Indicator while saving
//                                           )
//                                           : const Text(
//                                             "Save",
//                                             style: TextStyle(
//                                               fontSize: 18,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
