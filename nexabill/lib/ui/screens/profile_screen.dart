import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/widgets/custom_dropdown.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';
import 'package:nexabill/data/state_data.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool fromHome;
  ProfileScreen({super.key, this.fromHome = false}); // default = false

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).loadProfile(ref);
    });

    // Initialize controllers
    fullNameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    cityController = TextEditingController();
    pinController = TextEditingController();
    dobController = TextEditingController();

    // Fetch Profile Data after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileData = await ref.read(profileFutureProvider.future);

      // ref.refresh(profileNotifierProvider);
      // ref.refresh(profileFutureProvider);

      // ✅ Ensure gender and state update when fetched
      ref.read(selectedGenderProvider.notifier).state =
          profileData["gender"] ?? "Male";
      ref.read(selectedStateProvider.notifier).state =
          profileData["state"] ?? null;

      // ✅ Update controllers
      fullNameController.text = profileData["fullName"] ?? "";
      phoneController.text = profileData["phoneNumber"] ?? "";
      emailController.text = profileData["email"] ?? "";
      addressController.text = profileData["address"] ?? "";
      cityController.text = profileData["city"] ?? "";
      pinController.text = profileData["pin"] ?? "";

      // ✅ Ensure DOB is properly formatted
      if (profileData["dob"] != null) {
        DateTime? parsedDate = DateTime.tryParse(profileData["dob"]);
        if (parsedDate != null) {
          dobController.text =
              "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
          ref
              .read(profileNotifierProvider.notifier)
              .updateProfileField("dob", parsedDate, ref);
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
    // ✅ Fetch the latest profile data from Firebase
    final profileDataAsync = ref.watch(profileFutureProvider);

    return Scaffold(
      appBar:
          widget.fromHome
              ? AppBar(
                title: const Text("Edit Profile"),
                backgroundColor: theme.appBarTheme.backgroundColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
              : null,

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
                          radius:
                              55, // ✅ Ensure the outer avatar size remains large
                          backgroundColor: Colors.white,
                          child:
                              profileState.profileImage != null
                                  ? CircleAvatar(
                                    radius:
                                        50, // ✅ Inner avatar for image remains large
                                    backgroundImage: FileImage(
                                      profileState.profileImage!,
                                    ),
                                  )
                                  : CircleAvatar(
                                    radius:
                                        50, // ✅ Default avatar remains the same size
                                    backgroundImage: NetworkImage(
                                      "https://www.w3schools.com/w3images/avatar2.png",
                                    ),
                                  ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            // onTap: () => profileNotifier.pickImage(ref),
                            onTap:
                                () => profileNotifier.pickAndUploadImage(ref),
                            child: const CircleAvatar(
                              radius: 18, // ✅ Slightly bigger camera button
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.blue,
                                size: 18,
                              ),
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
                                  ref,
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
                                                ref,
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
                                                ref,
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
                                // if (pickedDate != null) {
                                //   profileNotifier.updateProfileField(
                                //     "dob",
                                //     pickedDate,
                                //     ref,
                                //   );
                                // }
                                if (pickedDate != null) {
                                  dobController.text =
                                      "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                                  profileNotifier.updateProfileField(
                                    "dob",
                                    pickedDate,
                                    ref,
                                  ); // ✅ Include ref
                                }
                              },
                            ),
                            const SizedBox(height: 10),

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
                                    ref,
                                  ),
                            ),

                            const SizedBox(height: 10),

                            // ✅ Address Field (Newly Added)
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
                                    ref,
                                  ),
                            ),
                            const SizedBox(height: 10),

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
                                    ref,
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
                                  value:
                                      StateData.stateList.contains(
                                            selectedState,
                                          )
                                          ? selectedState
                                          : null,
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
                                        ref,
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
                                    ref,
                                  ),
                            ),

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
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
                                              ref,
                                            );
                                            profileNotifier.updateProfileField(
                                              "phoneNumber",
                                              phoneController.text.trim(),
                                              ref,
                                            );
                                            profileNotifier.updateProfileField(
                                              "address",
                                              addressController.text.trim(),
                                              ref,
                                            );
                                            profileNotifier.updateProfileField(
                                              "city",
                                              cityController.text.trim(),
                                              ref,
                                            );
                                            profileNotifier.updateProfileField(
                                              "pin",
                                              pinController.text.trim(),
                                              ref,
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

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/ui/widgets/custom_dropdown.dart';
// import 'package:nexabill/ui/widgets/custom_textfield.dart';
// import 'package:nexabill/data/state_data.dart';

// class ProfileScreen extends ConsumerStatefulWidget {
//   ProfileScreen({super.key});

//   @override
//   _ProfileScreenState createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends ConsumerState<ProfileScreen> {
//   final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

//   late TextEditingController fullNameController;
//   late TextEditingController phoneController;
//   late TextEditingController emailController;
//   late TextEditingController addressController;
//   late TextEditingController cityController;
//   late TextEditingController pinController;
//   late TextEditingController dobController;

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(profileNotifierProvider.notifier).loadProfile(ref);
//     });

//     // Initialize controllers
//     fullNameController = TextEditingController();
//     phoneController = TextEditingController();
//     emailController = TextEditingController();
//     addressController = TextEditingController();
//     cityController = TextEditingController();
//     pinController = TextEditingController();
//     dobController = TextEditingController();

//     // Fetch Profile Data after frame renders
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       // final profileState = ref.read(profileNotifierProvider);

//       // final profileData = ref
//       //     .read(profileFutureProvider)
//       //     .maybeWhen(data: (data) => data, orElse: () => null);
//       final profileData = await ref.read(profileFutureProvider.future);

//       // ✅ Ensure gender and state update when fetched
//       ref.read(selectedGenderProvider.notifier).state =
//           profileData["gender"] ?? "Male";
//       ref.read(selectedStateProvider.notifier).state =
//           profileData["state"] ?? null;

//       // Update controllers with fetched or existing data
//       // fullNameController.text =
//       //     profileData?["fullName"] ?? profileState.fullName;
//       // phoneController.text =
//       //     profileData?["phoneNumber"] ?? profileState.phoneNumber;
//       // emailController.text = profileData?["email"] ?? profileState.email;
//       // addressController.text = profileData?["address"] ?? profileState.address;
//       // cityController.text = profileData?["city"] ?? profileState.city;
//       // pinController.text = profileData?["pin"] ?? profileState.pin;
//       // ✅ Update controllers
//       fullNameController.text = profileData["fullName"] ?? "";
//       phoneController.text = profileData["phoneNumber"] ?? "";
//       emailController.text = profileData["email"] ?? "";
//       addressController.text = profileData["address"] ?? "";
//       cityController.text = profileData["city"] ?? "";
//       pinController.text = profileData["pin"] ?? "";

//       // ✅ Ensure DOB is not reset
//       // final dobFromFirebase = profileData?["dob"];
//       // if (dobFromFirebase != null) {
//       //   DateTime? parsedDate = DateTime.tryParse(dobFromFirebase);
//       //   if (parsedDate != null) {
//       //     dobController.text =
//       //         "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
//       //     ref
//       //         .read(profileNotifierProvider.notifier)
//       //         .updateProfileField("dob", parsedDate);
//       //   }
//       // }
//       // ✅ Ensure DOB is properly formatted
//       if (profileData["dob"] != null) {
//         DateTime? parsedDate = DateTime.tryParse(profileData["dob"]);
//         if (parsedDate != null) {
//           dobController.text =
//               "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
//           ref
//               .read(profileNotifierProvider.notifier)
//               .updateProfileField("dob", parsedDate, ref);
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     // Proper cleanup
//     fullNameController.dispose();
//     phoneController.dispose();
//     emailController.dispose();
//     addressController.dispose();
//     cityController.dispose();
//     pinController.dispose();
//     dobController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final profileState = ref.watch(profileNotifierProvider);
//     final profileNotifier = ref.read(profileNotifierProvider.notifier);
//     final selectedGender = ref.watch(selectedGenderProvider);
//     final selectedState = ref.watch(selectedStateProvider);
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     return Scaffold(
//       body: SingleChildScrollView(
//         child: SizedBox(
//           width: double.infinity,
//           child: Stack(
//             children: [
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   height: 230,
//                   decoration: const BoxDecoration(
//                     color: AppTheme.blueColor,
//                     borderRadius: BorderRadius.only(
//                       bottomLeft: Radius.circular(100),
//                       bottomRight: Radius.circular(100),
//                     ),
//                   ),
//                 ),
//               ),
//               SafeArea(
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 30),
//                     const Text(
//                       "Profile",
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 80),
//                     Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         // CircleAvatar(
//                         //   radius: 55,
//                         //   backgroundColor: Colors.white,
//                         //   child:
//                         //       profileState.profileImage != null
//                         //           ? CircleAvatar(
//                         //             radius: 50,
//                         //             backgroundImage: FileImage(
//                         //               profileState.profileImage!,
//                         //             ),
//                         //           )
//                         //           : const CircleAvatar(
//                         //             radius: 50,
//                         //             backgroundImage: NetworkImage(
//                         //               "https://www.w3schools.com/w3images/avatar2.png",
//                         //             ),
//                         //           ),
//                         // ),
//                         CircleAvatar(
//                           radius: 55,
//                           backgroundColor: Colors.white,
//                           child:
//                               profileState.profileImage != null
//                                   ? CircleAvatar(
//                                     radius: 50,
//                                     backgroundImage: FileImage(
//                                       profileState.profileImage!,
//                                     ),
//                                   )
//                                   : profileState.profileImageUrl.isNotEmpty
//                                   ? CircleAvatar(
//                                     radius: 50,
//                                     backgroundImage: MemoryImage(
//                                       base64Decode(
//                                         profileState.profileImageUrl,
//                                       ),
//                                     ),
//                                   )
//                                   : const CircleAvatar(
//                                     radius: 50,
//                                     backgroundImage: NetworkImage(
//                                       "https://www.w3schools.com/w3images/avatar2.png",
//                                     ),
//                                   ),
//                         ),

//                         Positioned(
//                           bottom: 2,
//                           right: 2,
//                           child: GestureDetector(
//                             onTap: () => profileNotifier.pickImage(),
//                             child: const CircleAvatar(
//                               radius: 15,
//                               backgroundColor: Colors.white,
//                               child: Icon(Icons.camera_alt, color: Colors.blue),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                     Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Form(
//                         key: _profileFormKey,
//                         child: Column(
//                           children: [
//                             CustomTextField(
//                               controller: fullNameController,
//                               label: "Full Name",
//                               hintText: "Enter your full name",
//                               labelColor:
//                                   isDarkMode
//                                       ? Colors.white
//                                       : Colors.black, // ✅ White in dark mode
//                               prefixIcon: Icons.person,
//                               prefixIconColor:
//                                   isDarkMode
//                                       ? AppTheme.secondaryColor
//                                       : Colors
//                                           .black54, // ✅ Secondary color in dark mode
//                               onChanged: (value) {
//                                 profileNotifier.updateProfileField(
//                                   "fullName",
//                                   value,
//                                   ref,
//                                 );
//                               },
//                             ),
//                             const SizedBox(height: 10),
//                             Column(
//                               crossAxisAlignment:
//                                   CrossAxisAlignment
//                                       .start, // ✅ Align label to the left
//                               children: [
//                                 // ✅ Gender Label Positioned Above the Buttons
//                                 Text(
//                                   "Gender",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color:
//                                         isDarkMode
//                                             ? Colors.white
//                                             : Colors
//                                                 .black, // ✅ White in dark mode
//                                   ),
//                                 ),
//                                 const SizedBox(
//                                   height: 8,
//                                 ), // ✅ Space between label and buttons

//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: ElevatedButton.icon(
//                                         onPressed: () {
//                                           ref
//                                               .read(
//                                                 profileNotifierProvider
//                                                     .notifier,
//                                               )
//                                               .updateProfileField(
//                                                 "gender",
//                                                 "Male",
//                                                 ref,
//                                               );
//                                         },
//                                         icon: Icon(
//                                           Icons.male,
//                                           color:
//                                               isDarkMode
//                                                   ? AppTheme.secondaryColor
//                                                   : Colors.black54,
//                                         ),
//                                         label: Text(
//                                           "Male",
//                                           style: TextStyle(
//                                             color:
//                                                 isDarkMode
//                                                     ? Colors.white
//                                                     : Colors.black,
//                                           ),
//                                         ),
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor:
//                                               profileState.gender == "Male"
//                                                   ? AppTheme.primaryColor
//                                                   : Colors
//                                                       .grey[300], // ✅ Correctly Updates State
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 10),
//                                     Expanded(
//                                       child: ElevatedButton.icon(
//                                         onPressed: () {
//                                           ref
//                                               .read(
//                                                 profileNotifierProvider
//                                                     .notifier,
//                                               )
//                                               .updateProfileField(
//                                                 "gender",
//                                                 "Female",
//                                                 ref,
//                                               );
//                                         },
//                                         icon: Icon(
//                                           Icons.female,
//                                           color:
//                                               isDarkMode
//                                                   ? AppTheme.secondaryColor
//                                                   : Colors.black54,
//                                         ),
//                                         label: Text(
//                                           "Female",
//                                           style: TextStyle(
//                                             color:
//                                                 isDarkMode
//                                                     ? Colors.white
//                                                     : Colors.black,
//                                           ),
//                                         ),
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor:
//                                               profileState.gender == "Female"
//                                                   ? AppTheme.primaryColor
//                                                   : Colors
//                                                       .grey[300], // ✅ Correctly Updates State
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 10),
//                             CustomTextField(
//                               controller: TextEditingController(
//                                 text:
//                                     profileState.dob != null
//                                         ? "${profileState.dob!.day}-${profileState.dob!.month}-${profileState.dob!.year}"
//                                         : "",
//                               ),
//                               label: "Date of Birth",
//                               hintText: "Select your date of birth",
//                               labelColor:
//                                   isDarkMode
//                                       ? Colors.white
//                                       : Colors.black, // ✅ White in dark mode
//                               prefixIcon: Icons.calendar_today,
//                               prefixIconColor:
//                                   isDarkMode
//                                       ? AppTheme.secondaryColor
//                                       : Colors
//                                           .black54, // ✅ Secondary color in dark mode
//                               readOnly: true,
//                               onTap: () async {
//                                 DateTime? pickedDate = await showDatePicker(
//                                   context: context,
//                                   initialDate:
//                                       profileState.dob ?? DateTime.now(),
//                                   firstDate: DateTime(1900),
//                                   lastDate: DateTime.now(),
//                                 );
//                                 if (pickedDate != null) {
//                                   profileNotifier.updateProfileField(
//                                     "dob",
//                                     pickedDate,
//                                     ref,
//                                   );
//                                 }
//                               },
//                             ),
//                             const SizedBox(height: 10),

//                             // Email Field (Read-Only)
//                             CustomTextField(
//                               controller:
//                                   emailController, // ✅ Uses initialized controller
//                               label: "Email",
//                               hintText: "Enter your email",
//                               labelColor:
//                                   isDarkMode
//                                       ? Colors.white
//                                       : Colors.black, // ✅ White in dark mode
//                               prefixIcon: Icons.email,
//                               prefixIconColor:
//                                   isDarkMode
//                                       ? AppTheme.secondaryColor
//                                       : Colors
//                                           .black54, // ✅ Secondary color in dark mode
//                               readOnly: true, // ✅ Email should not be editable
//                             ),
//                             const SizedBox(height: 10),

//                             // Phone Number Field
//                             CustomTextField(
//                               controller:
//                                   phoneController, // ✅ Uses initialized controller
//                               label: "Phone Number",
//                               hintText: "Enter your phone number",
//                               labelColor:
//                                   isDarkMode
//                                       ? Colors.white
//                                       : Colors.black, // ✅ White in dark mode
//                               prefixIcon: Icons.phone,
//                               prefixIconColor:
//                                   isDarkMode
//                                       ? AppTheme.secondaryColor
//                                       : Colors
//                                           .black54, // ✅ Secondary color in dark mode
//                               onChanged:
//                                   (value) => profileNotifier.updateProfileField(
//                                     "phoneNumber",
//                                     value,
//                                     ref,
//                                   ),
//                             ),

//                             const SizedBox(height: 10),

//                             // ✅ Address Field (Newly Added)
//                             CustomTextField(
//                               controller: addressController,
//                               label: "Address",
//                               hintText: "Enter your address",
//                               labelColor:
//                                   isDarkMode
//                                       ? Colors.white
//                                       : Colors.black, // ✅ White in dark mode
//                               prefixIcon: Icons.location_on,
//                               prefixIconColor:
//                                   isDarkMode
//                                       ? AppTheme.secondaryColor
//                                       : Colors
//                                           .black54, // ✅ Secondary color in dark mode
//                               onChanged:
//                                   (value) => profileNotifier.updateProfileField(
//                                     "address",
//                                     value,
//                                     ref,
//                                   ),
//                             ),
//                             const SizedBox(height: 10),

//                             // City Field
//                             CustomTextField(
//                               controller:
//                                   cityController, // ✅ Uses initialized controller
//                               label: "City",
//                               hintText: "Enter your city",
//                               labelColor:
//                                   isDarkMode
//                                       ? Colors.white
//                                       : Colors.black, // ✅ White in dark mode
//                               prefixIcon: Icons.location_city,
//                               prefixIconColor:
//                                   isDarkMode
//                                       ? AppTheme.secondaryColor
//                                       : Colors
//                                           .black54, // ✅ Secondary color in dark mode
//                               onChanged:
//                                   (value) => profileNotifier.updateProfileField(
//                                     "city",
//                                     value,
//                                     ref,
//                                   ),
//                             ),

//                             const SizedBox(height: 10),
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "State",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color:
//                                         isDarkMode
//                                             ? Colors.white
//                                             : Colors
//                                                 .black, // ✅ White in dark mode
//                                   ),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 CustomDropdown(
//                                   value: selectedState,
//                                   hintText: "Select your state",
//                                   items: StateData.stateList,
//                                   onChanged: (newValue) {
//                                     if (newValue != null) {
//                                       ref
//                                           .read(selectedStateProvider.notifier)
//                                           .state = newValue;
//                                       profileNotifier.updateProfileField(
//                                         "selectedState",
//                                         newValue,
//                                         ref,
//                                       ); // ✅ Ensure state is saved
//                                     }
//                                   },
//                                   textColor:
//                                       isDarkMode ? Colors.black : Colors.white,
//                                   hintColor:
//                                       isDarkMode
//                                           ? Colors.black54
//                                           : Colors
//                                               .white70, // ✅ Fixed Hint Color
//                                   fillColor:
//                                       isDarkMode
//                                           ? Colors.white
//                                           : Colors.black, // ✅ Fixed Background
//                                   prefixIcon:
//                                       Icons
//                                           .location_on, // ✅ Optional Prefix Icon
//                                   suffixIcon:
//                                       Icons
//                                           .arrow_drop_down, // ✅ Optional Suffix Icon
//                                   iconColor:
//                                       isDarkMode
//                                           ? AppTheme.secondaryColor
//                                           : Colors
//                                               .black54, // ✅ Secondary color in dark mode
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 15),
//                             // Pin Code Field
//                             CustomTextField(
//                               controller:
//                                   pinController, // ✅ Uses initialized controller
//                               keyboardType: TextInputType.number,
//                               label: "Pin Code",
//                               hintText: "Enter your pin code",
//                               labelColor:
//                                   isDarkMode
//                                       ? Colors.white
//                                       : Colors.black, // ✅ White in dark mode
//                               prefixIcon: Icons.pin,
//                               prefixIconColor:
//                                   isDarkMode
//                                       ? AppTheme.secondaryColor
//                                       : Colors
//                                           .black54, // ✅ Secondary color in dark mode
//                               onChanged:
//                                   (value) => profileNotifier.updateProfileField(
//                                     "pin",
//                                     value,
//                                     ref,
//                                   ),
//                             ),

//                             const SizedBox(height: 20),
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor:
//                                       AppTheme
//                                           .primaryColor, // ✅ Use primary color
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 14,
//                                   ),
//                                 ),
//                                 onPressed:
//                                     profileState.isLoading
//                                         ? null
//                                         : () async {
//                                           if (_profileFormKey.currentState!
//                                               .validate()) {
//                                             // ✅ Update all fields before saving
//                                             profileNotifier.updateProfileField(
//                                               "fullName",
//                                               fullNameController.text.trim(),
//                                               ref,
//                                             );
//                                             profileNotifier.updateProfileField(
//                                               "phoneNumber",
//                                               phoneController.text.trim(),
//                                               ref,
//                                             );
//                                             profileNotifier.updateProfileField(
//                                               "address",
//                                               addressController.text.trim(),
//                                               ref,
//                                             );
//                                             profileNotifier.updateProfileField(
//                                               "city",
//                                               cityController.text.trim(),
//                                               ref,
//                                             );
//                                             profileNotifier.updateProfileField(
//                                               "pin",
//                                               pinController.text.trim(),
//                                               ref,
//                                             );

//                                             // ✅ Save Profile and Rebuild UI
//                                             await profileNotifier.saveProfile(
//                                               context,
//                                               ref,
//                                             );
//                                           }
//                                         },
//                                 child:
//                                     profileState.isLoading
//                                         ? const CircularProgressIndicator(
//                                           color: Colors.white,
//                                         )
//                                         : const Text(
//                                           "Save",
//                                           style: TextStyle(
//                                             fontSize: 18,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
