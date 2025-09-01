import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/data/marts_data.dart';
import 'package:nexabill/providers/home_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/widgets/custom_dropdown.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';
import 'package:nexabill/data/state_data.dart';

// final adminMartNamesProvider = FutureProvider<List<String>>((ref) async {
//   final snapshot =
//       await FirebaseFirestore.instance
//           .collection('users')
//           .where('role', isEqualTo: 'Admin')
//           .get();

//   for (var doc in snapshot.docs) {
//     debugPrint("👤 Admin found: ${doc.data()}");
//   }

//   // final marts =
//   //     snapshot.docs
//   //         .map((doc) => doc.data()['martName'] as String?)
//   //         .where((name) => name != null && name.isNotEmpty)
//   //         .cast<String>()
//   //         .toList();

//   // return marts;

//   final martNames = snapshot.docs
//       .map((doc) {
//         final data = doc.data();
//         // Handle inconsistent field names
//         return data['martName'] ??
//             data['mart'] ??
//             data['MartName'];
//       })
//       .whereType<String>() // remove nulls
//       .where((name) => name.trim().isNotEmpty) // remove empty
//       .toSet()
//       .toList();

//   debugPrint("✅ Loaded Admin Mart Names: $martNames");
//   return martNames;
// });

final adminMartNamesProvider = FutureProvider<List<String>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('users').get();

  final martNames =
      snapshot.docs
          .where(
            (doc) =>
                doc.data()['role']?.toString().toLowerCase() == 'admin' &&
                (doc.data()['martName'] ?? '').toString().trim().isNotEmpty,
          )
          .map((doc) => doc.data()['martName'].toString().trim())
          .toSet()
          .toList();

  debugPrint("✅ Loaded Admin Mart Names: $martNames");

  return martNames;
});

class ProfileScreen extends ConsumerStatefulWidget {
  final bool fromHome;
  final bool isInsideTabs;
  const ProfileScreen({
    super.key,
    this.fromHome = false,
    this.isInsideTabs = false,
  }); // default = false

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

    // Load profile and update controllers after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(ref);

      final profileState = ref.read(profileNotifierProvider);

      // Update controllers
      fullNameController.text = profileState.fullName;
      phoneController.text = profileState.phoneNumber;
      emailController.text = profileState.email;
      addressController.text = profileState.address;
      cityController.text = profileState.city;
      pinController.text = profileState.pin;

      // Update DOB text
      if (profileState.dob != null) {
        dobController.text =
            "${profileState.dob!.day}-${profileState.dob!.month}-${profileState.dob!.year}";
      }

      // Update gender/state providers
      ref.read(selectedGenderProvider.notifier).state = profileState.gender;
      ref.read(selectedStateProvider.notifier).state =
          profileState.selectedState;
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
    // 📦 Create a FutureProvider to fetch mart names from Firestore
    final availableAdminMartsProvider = FutureProvider<List<String>>((
      ref,
    ) async {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Admin')
              .get();

      return snapshot.docs
          .map((doc) => doc.data()['martName']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    });

    return Scaffold(
      appBar:
          widget.fromHome && !widget.isInsideTabs
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
                                () => profileNotifier.pickAndUploadImage(
                                  ref: ref,
                                  targetField:
                                      'profileImageUrl', // or any appropriate field
                                ),

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
                                dobController.text =
                                    "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                                profileNotifier.updateProfileField(
                                  "dob",
                                  pickedDate,
                                  ref,
                                ); // ✅ Include ref
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

                            // 🔐 Role Field (Read-only)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Role",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                IgnorePointer(
                                  child: AbsorbPointer(
                                    child: CustomDropdown(
                                      // value:
                                      //     profileState.role.isNotEmpty
                                      //         ? profileState.role
                                      //         : null,
                                      value: roles.map((e) => e.toLowerCase()).contains(profileState.role.toLowerCase())
    ? roles.firstWhere((e) => e.toLowerCase() == profileState.role.toLowerCase())
    : null,
                                      hintText: "Select your role",
                                      items: roles,
                                      onChanged:
                                          (_) {}, // Will not be triggered
                                      textColor:
                                          isDarkMode
                                              ? Colors.black
                                              : Colors.black,
                                      hintColor:
                                          isDarkMode
                                              ? Colors.black54
                                              : Colors.white70,
                                      fillColor:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.white,
                                      prefixIcon: Icons.person_pin,
                                      suffixIcon: Icons.lock,
                                      iconColor:
                                          isDarkMode
                                              ? Colors.black54
                                              : Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
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
                                      isDarkMode ? Colors.black : Colors.black,
                                  hintColor:
                                      isDarkMode
                                          ? Colors.black54
                                          : Colors
                                              .black54, // ✅ Fixed Hint Color
                                  fillColor:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.white, // ✅ Fixed Background
                                  prefixIcon:
                                      Icons
                                          .location_on, // ✅ Optional Prefix Icon

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
                            if (profileState.role.toLowerCase() ==
                                "cashier") ...[
                              const SizedBox(height: 5),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Role",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  IgnorePointer(
                                    // 👈 Prevents user interaction
                                    child: AbsorbPointer(
                                      child: CustomDropdown(
                                        // value:
                                        //     profileState.role.isNotEmpty
                                        //         ? profileState.role
                                        //         : null,
                                        value: roles.map((e) => e.toLowerCase()).contains(profileState.role.toLowerCase())
    ? roles.firstWhere((e) => e.toLowerCase() == profileState.role.toLowerCase())
    : null,
                                        hintText: "Select your role",
                                        items: roles,
                                        onChanged:
                                            (
                                              _,
                                            ) {}, // 👈 Will not be called due to IgnorePointer
                                        textColor:
                                            isDarkMode
                                                ? Colors.black
                                                : Colors.black,
                                        hintColor:
                                            isDarkMode
                                                ? Colors.black54
                                                : Colors.black54,
                                        fillColor:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.white,
                                        prefixIcon: Icons.manage_accounts,
                                        suffixIcon:
                                            Icons
                                                .lock, // 🔒 Icon for read-only field
                                        iconColor:
                                            isDarkMode
                                                ? Colors.black54
                                                : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     Text(
                              //       "Mart",
                              //       style: TextStyle(
                              //         fontSize: 16,
                              //         fontWeight: FontWeight.bold,
                              //         color:
                              //             isDarkMode
                              //                 ? Colors.white
                              //                 : Colors.black,
                              //       ),
                              //     ),
                              //     const SizedBox(height: 5),
                              //     CustomDropdown(
                              //       value:
                              //           profileState.mart.isNotEmpty
                              //               ? profileState.mart
                              //               : null,
                              //       hintText: "Select your mart",
                              //       items: marts,
                              //       onChanged: (newValue) {
                              //         profileNotifier.updateProfileField(
                              //           "mart",
                              //           newValue,
                              //           ref,
                              //         );
                              //       },
                              //       textColor:
                              //           isDarkMode
                              //               ? Colors.black
                              //               : Colors.white,
                              //       hintColor:
                              //           isDarkMode
                              //               ? Colors.black54
                              //               : Colors.white70,
                              //       fillColor:
                              //           isDarkMode
                              //               ? Colors.white
                              //               : Colors.black,
                              //       prefixIcon: Icons.store,
                              //       suffixIcon: Icons.arrow_drop_down,
                              //       iconColor:
                              //           isDarkMode
                              //               ? Colors.black54
                              //               : Colors.black54,
                              //     ),
                              //   ],
                              // ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Mart",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ref
                                      .watch(adminMartNamesProvider)
                                      .when(
                                        data: (martsList) {
                                          final uniqueMarts =
                                              martsList
                                                  .toSet()
                                                  .toList(); // Ensure unique

                                          debugPrint(
                                            "📦 Loaded marts list: $uniqueMarts",
                                          );

                                          final selectedMart = ref.watch(
                                            selectedMartProvider,
                                          );

                                          if (selectedMart != null &&
                                              !uniqueMarts.contains(
                                                selectedMart,
                                              )) {
                                            debugPrint(
                                              "⚠️ Selected mart '$selectedMart' not in list. Resetting.",
                                            );
                                            ref
                                                .read(
                                                  selectedMartProvider.notifier,
                                                )
                                                .state = null;
                                          }

                                          return CustomDropdown(
                                            value: selectedMart,
                                            hintText: "Select your mart",
                                            items: uniqueMarts,
                                            onChanged: (newValue) {
                                              debugPrint(
                                                "✅ Selected mart: $newValue",
                                              );
                                              ref
                                                  .read(
                                                    selectedMartProvider
                                                        .notifier,
                                                  )
                                                  .state = newValue;
                                              profileNotifier
                                                  .updateProfileField(
                                                    "mart",
                                                    newValue,
                                                    ref,
                                                  );
                                            },
                                            textColor:
                                                isDarkMode
                                                    ? Colors.black
                                                    : Colors.black,
                                            hintColor:
                                                isDarkMode
                                                    ? Colors.black54
                                                    : Colors.black54,
                                            fillColor:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.white,
                                            prefixIcon: Icons.store,
                                            iconColor:
                                                isDarkMode
                                                    ? Colors.black54
                                                    : Colors.black54,
                                          );
                                        },
                                        loading: () {
                                          debugPrint(
                                            "⏳ Loading marts from Firestore...",
                                          );
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                        error: (err, stack) {
                                          debugPrint(
                                            "❌ Error loading marts: $err",
                                          );
                                          return const Text(
                                            'Error loading marts',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          );
                                        },
                                      ),
                                ],
                              ),

                              // // ✅ Replace the current CustomDropdown for Mart with this block
                              // Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     Text(
                              //       "Mart",
                              //       style: TextStyle(
                              //         fontSize: 16,
                              //         fontWeight: FontWeight.bold,
                              //         color:
                              //             isDarkMode
                              //                 ? Colors.white
                              //                 : Colors.black,
                              //       ),
                              //     ),
                              //     const SizedBox(height: 5),
                              //     ref
                              //         .watch(availableAdminMartsProvider)
                              //         .when(
                              //           data:
                              //               (martsList) => CustomDropdown(
                              //                 value:
                              //                     profileState.mart.isNotEmpty
                              //                         ? profileState.mart
                              //                         : null,
                              //                 hintText: "Select your mart",
                              //                 items: martsList,
                              //                 onChanged: (newValue) {
                              //                   profileNotifier
                              //                       .updateProfileField(
                              //                         "mart",
                              //                         newValue,
                              //                         ref,
                              //                       );
                              //                 },
                              //                 textColor:
                              //                     isDarkMode
                              //                         ? Colors.black
                              //                         : Colors.white,
                              //                 hintColor:
                              //                     isDarkMode
                              //                         ? Colors.black54
                              //                         : Colors.white70,
                              //                 fillColor:
                              //                     isDarkMode
                              //                         ? Colors.white
                              //                         : Colors.black,
                              //                 prefixIcon: Icons.store,
                              //                 suffixIcon: Icons.arrow_drop_down,
                              //                 iconColor:
                              //                     isDarkMode
                              //                         ? Colors.black54
                              //                         : Colors.black54,
                              //               ),
                              //           loading:
                              //               () =>
                              //                   const CircularProgressIndicator(),
                              //           error:
                              //               (error, _) => Text(
                              //                 'Error loading marts',
                              //                 style: TextStyle(
                              //                   color: Colors.redAccent,
                              //                 ),
                              //               ),
                              //         ),
                              //   ],
                              // ),
                              const SizedBox(height: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Counter",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  CustomDropdown(
                                    value:
                                        profileState.counterNumber.isNotEmpty
                                            ? profileState.counterNumber
                                            : null,
                                    hintText: "Select your counter",
                                    items: counters,
                                    onChanged: (newValue) {
                                      profileNotifier.updateProfileField(
                                        "counterNumber",
                                        newValue,
                                        ref,
                                      );
                                    },
                                    textColor:
                                        isDarkMode
                                            ? Colors.black
                                            : Colors.black,
                                    hintColor:
                                        isDarkMode
                                            ? Colors.black54
                                            : Colors.black54,
                                    fillColor:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.white,
                                    prefixIcon: Icons.confirmation_number,
                                    iconColor:
                                        isDarkMode
                                            ? Colors.black54
                                            : Colors.black54,
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),

                            if (!widget.isInsideTabs)
                              profileState.role.toLowerCase() == "admin"
                                  ? Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                                if (_profileFormKey
                                                    .currentState!
                                                    .validate()) {
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "fullName",
                                                        fullNameController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "phoneNumber",
                                                        phoneController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "address",
                                                        addressController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "city",
                                                        cityController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "pin",
                                                        pinController.text
                                                            .trim(),
                                                        ref,
                                                      );

                                                  await profileNotifier
                                                      .saveProfile(
                                                        context,
                                                        ref,
                                                      );

                                                  if (context.mounted) {
                                                    Navigator.pushNamed(
                                                      context,
                                                      "/mart-details",
                                                    ); // ✅ Updated route
                                                  }
                                                }
                                              },
                                      child:
                                          profileState.isLoading
                                              ? const CircularProgressIndicator(
                                                color: Colors.white,
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
                                  : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      onPressed:
                                          profileState.isLoading
                                              ? null
                                              : () async {
                                                if (_profileFormKey
                                                    .currentState!
                                                    .validate()) {
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "fullName",
                                                        fullNameController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "phoneNumber",
                                                        phoneController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "address",
                                                        addressController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "city",
                                                        cityController.text
                                                            .trim(),
                                                        ref,
                                                      );
                                                  profileNotifier
                                                      .updateProfileField(
                                                        "pin",
                                                        pinController.text
                                                            .trim(),
                                                        ref,
                                                      );

                                                  await profileNotifier
                                                      .saveProfile(
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

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/data/marts_data.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/ui/widgets/custom_dropdown.dart';
// import 'package:nexabill/ui/widgets/custom_textfield.dart';
// import 'package:nexabill/data/state_data.dart';

// final adminMartNamesProvider = FutureProvider<List<String>>((ref) async {
//   final snapshot =
//       await FirebaseFirestore.instance
//           .collection('users')
//           .where('role', isEqualTo: 'admin')
//           .get();

//   final marts =
//       snapshot.docs
//           .map((doc) => doc.data()['martName'] as String?)
//           .where((name) => name != null && name.isNotEmpty)
//           .cast<String>()
//           .toList();

//   return marts;
// });

// class ProfileScreen extends ConsumerStatefulWidget {
//   final bool fromHome;
//   final bool isInsideTabs;
//   const ProfileScreen({
//     super.key,
//     this.fromHome = false,
//     this.isInsideTabs = false,
//   }); // default = false

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

//     // Initialize controllers
//     fullNameController = TextEditingController();
//     phoneController = TextEditingController();
//     emailController = TextEditingController();
//     addressController = TextEditingController();
//     cityController = TextEditingController();
//     pinController = TextEditingController();
//     dobController = TextEditingController();

//     // Load profile and update controllers after the first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final notifier = ref.read(profileNotifierProvider.notifier);
//       await notifier.loadProfile(ref);

//       final profileState = ref.read(profileNotifierProvider);

//       // Update controllers
//       fullNameController.text = profileState.fullName;
//       phoneController.text = profileState.phoneNumber;
//       emailController.text = profileState.email;
//       addressController.text = profileState.address;
//       cityController.text = profileState.city;
//       pinController.text = profileState.pin;

//       // Update DOB text
//       if (profileState.dob != null) {
//         dobController.text =
//             "${profileState.dob!.day}-${profileState.dob!.month}-${profileState.dob!.year}";
//       }

//       // Update gender/state providers
//       ref.read(selectedGenderProvider.notifier).state = profileState.gender;
//       ref.read(selectedStateProvider.notifier).state =
//           profileState.selectedState;
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
//     // ✅ Fetch the latest profile data from Firebase
//     final profileDataAsync = ref.watch(profileFutureProvider);
//     // 📦 Create a FutureProvider to fetch mart names from Firestore
//     final availableAdminMartsProvider = FutureProvider<List<String>>((
//       ref,
//     ) async {
//       final snapshot =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .where('role', isEqualTo: 'Admin')
//               .get();

//       return snapshot.docs
//           .map((doc) => doc.data()['martName']?.toString() ?? '')
//           .where((name) => name.isNotEmpty)
//           .toList();
//     });

//     return Scaffold(
//       appBar:
//           widget.fromHome && !widget.isInsideTabs
//               ? AppBar(
//                 title: const Text("Edit Profile"),
//                 backgroundColor: theme.appBarTheme.backgroundColor,
//                 leading: IconButton(
//                   icon: const Icon(Icons.arrow_back),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               )
//               : null,

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
//                         CircleAvatar(
//                           radius:
//                               55, // ✅ Ensure the outer avatar size remains large
//                           backgroundColor: Colors.white,
//                           child:
//                               profileState.profileImage != null
//                                   ? CircleAvatar(
//                                     radius:
//                                         50, // ✅ Inner avatar for image remains large
//                                     backgroundImage: FileImage(
//                                       profileState.profileImage!,
//                                     ),
//                                   )
//                                   : CircleAvatar(
//                                     radius:
//                                         50, // ✅ Default avatar remains the same size
//                                     backgroundImage: NetworkImage(
//                                       "https://www.w3schools.com/w3images/avatar2.png",
//                                     ),
//                                   ),
//                         ),
//                         Positioned(
//                           bottom: 2,
//                           right: 2,
//                           child: GestureDetector(
//                             // onTap: () => profileNotifier.pickImage(ref),
//                             onTap:
//                                 () => profileNotifier.pickAndUploadImage(
//                                   ref: ref,
//                                   targetField:
//                                       'profileImageUrl', // or any appropriate field
//                                 ),

//                             child: const CircleAvatar(
//                               radius: 18, // ✅ Slightly bigger camera button
//                               backgroundColor: Colors.white,
//                               child: Icon(
//                                 Icons.camera_alt,
//                                 color: Colors.blue,
//                                 size: 18,
//                               ),
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
//                                 // if (pickedDate != null) {
//                                 //   profileNotifier.updateProfileField(
//                                 //     "dob",
//                                 //     pickedDate,
//                                 //     ref,
//                                 //   );
//                                 // }
//                                 if (pickedDate != null) {
//                                   dobController.text =
//                                       "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
//                                   profileNotifier.updateProfileField(
//                                     "dob",
//                                     pickedDate,
//                                     ref,
//                                   ); // ✅ Include ref
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

//                             // 🔐 Role Field (Read-only)
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Role",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color:
//                                         isDarkMode
//                                             ? Colors.white
//                                             : Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 IgnorePointer(
//                                   child: AbsorbPointer(
//                                     child: CustomDropdown(
//                                       value:
//                                           profileState.role.isNotEmpty
//                                               ? profileState.role
//                                               : null,
//                                       hintText: "Select your role",
//                                       items: roles,
//                                       onChanged:
//                                           (_) {}, // Will not be triggered
//                                       textColor:
//                                           isDarkMode
//                                               ? Colors.black
//                                               : Colors.black,
//                                       hintColor:
//                                           isDarkMode
//                                               ? Colors.black54
//                                               : Colors.white70,
//                                       fillColor:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors.white,
//                                       prefixIcon: Icons.person_pin,
//                                       suffixIcon: Icons.lock,
//                                       iconColor:
//                                           isDarkMode
//                                               ? Colors.black54
//                                               : Colors.black54,
//                                     ),
//                                   ),
//                                 ),
//                               ],
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
//                                   value:
//                                       StateData.stateList.contains(
//                                             selectedState,
//                                           )
//                                           ? selectedState
//                                           : null,
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
//                                       isDarkMode ? Colors.black : Colors.black,
//                                   hintColor:
//                                       isDarkMode
//                                           ? Colors.black54
//                                           : Colors
//                                               .black54, // ✅ Fixed Hint Color
//                                   fillColor:
//                                       isDarkMode
//                                           ? Colors.white
//                                           : Colors.white, // ✅ Fixed Background
//                                   prefixIcon:
//                                       Icons
//                                           .location_on, // ✅ Optional Prefix Icon

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
//                             if (profileState.role.toLowerCase() ==
//                                 "cashier") ...[
//                               const SizedBox(height: 5),

//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "Role",
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors.black,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 5),
//                                   IgnorePointer(
//                                     // 👈 Prevents user interaction
//                                     child: AbsorbPointer(
//                                       child: CustomDropdown(
//                                         value:
//                                             profileState.role.isNotEmpty
//                                                 ? profileState.role
//                                                 : null,
//                                         hintText: "Select your role",
//                                         items: roles,
//                                         onChanged:
//                                             (
//                                               _,
//                                             ) {}, // 👈 Will not be called due to IgnorePointer
//                                         textColor:
//                                             isDarkMode
//                                                 ? Colors.black
//                                                 : Colors.white,
//                                         hintColor:
//                                             isDarkMode
//                                                 ? Colors.black54
//                                                 : Colors.white70,
//                                         fillColor:
//                                             isDarkMode
//                                                 ? Colors.white
//                                                 : Colors.black,
//                                         prefixIcon: Icons.manage_accounts,
//                                         suffixIcon:
//                                             Icons
//                                                 .lock, // 🔒 Icon for read-only field
//                                         iconColor:
//                                             isDarkMode
//                                                 ? Colors.black54
//                                                 : Colors.black54,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),

//                               const SizedBox(height: 15),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "Mart",
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors.black,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 5),
//                                   CustomDropdown(
//                                     value:
//                                         profileState.mart.isNotEmpty
//                                             ? profileState.mart
//                                             : null,
//                                     hintText: "Select your mart",
//                                     items: marts,
//                                     onChanged: (newValue) {
//                                       profileNotifier.updateProfileField(
//                                         "mart",
//                                         newValue,
//                                         ref,
//                                       );
//                                     },
//                                     textColor:
//                                         isDarkMode
//                                             ? Colors.black
//                                             : Colors.white,
//                                     hintColor:
//                                         isDarkMode
//                                             ? Colors.black54
//                                             : Colors.white70,
//                                     fillColor:
//                                         isDarkMode
//                                             ? Colors.white
//                                             : Colors.black,
//                                     prefixIcon: Icons.store,
//                                     suffixIcon: Icons.arrow_drop_down,
//                                     iconColor:
//                                         isDarkMode
//                                             ? Colors.black54
//                                             : Colors.black54,
//                                   ),
//                                 ],
//                               ),

//                               // // ✅ Replace the current CustomDropdown for Mart with this block
//                               // Column(
//                               //   crossAxisAlignment: CrossAxisAlignment.start,
//                               //   children: [
//                               //     Text(
//                               //       "Mart",
//                               //       style: TextStyle(
//                               //         fontSize: 16,
//                               //         fontWeight: FontWeight.bold,
//                               //         color:
//                               //             isDarkMode
//                               //                 ? Colors.white
//                               //                 : Colors.black,
//                               //       ),
//                               //     ),
//                               //     const SizedBox(height: 5),
//                               //     ref
//                               //         .watch(availableAdminMartsProvider)
//                               //         .when(
//                               //           data:
//                               //               (martsList) => CustomDropdown(
//                               //                 value:
//                               //                     profileState.mart.isNotEmpty
//                               //                         ? profileState.mart
//                               //                         : null,
//                               //                 hintText: "Select your mart",
//                               //                 items: martsList,
//                               //                 onChanged: (newValue) {
//                               //                   profileNotifier
//                               //                       .updateProfileField(
//                               //                         "mart",
//                               //                         newValue,
//                               //                         ref,
//                               //                       );
//                               //                 },
//                               //                 textColor:
//                               //                     isDarkMode
//                               //                         ? Colors.black
//                               //                         : Colors.white,
//                               //                 hintColor:
//                               //                     isDarkMode
//                               //                         ? Colors.black54
//                               //                         : Colors.white70,
//                               //                 fillColor:
//                               //                     isDarkMode
//                               //                         ? Colors.white
//                               //                         : Colors.black,
//                               //                 prefixIcon: Icons.store,
//                               //                 suffixIcon: Icons.arrow_drop_down,
//                               //                 iconColor:
//                               //                     isDarkMode
//                               //                         ? Colors.black54
//                               //                         : Colors.black54,
//                               //               ),
//                               //           loading:
//                               //               () =>
//                               //                   const CircularProgressIndicator(),
//                               //           error:
//                               //               (error, _) => Text(
//                               //                 'Error loading marts',
//                               //                 style: TextStyle(
//                               //                   color: Colors.redAccent,
//                               //                 ),
//                               //               ),
//                               //         ),
//                               //   ],
//                               // ),
//                               const SizedBox(height: 15),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "Counter",
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color:
//                                           isDarkMode
//                                               ? Colors.white
//                                               : Colors.black,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 5),
//                                   CustomDropdown(
//                                     value:
//                                         profileState.counterNumber.isNotEmpty
//                                             ? profileState.counterNumber
//                                             : null,
//                                     hintText: "Select your counter",
//                                     items: counters,
//                                     onChanged: (newValue) {
//                                       profileNotifier.updateProfileField(
//                                         "counterNumber",
//                                         newValue,
//                                         ref,
//                                       );
//                                     },
//                                     textColor:
//                                         isDarkMode
//                                             ? Colors.black
//                                             : Colors.white,
//                                     hintColor:
//                                         isDarkMode
//                                             ? Colors.black54
//                                             : Colors.white70,
//                                     fillColor:
//                                         isDarkMode
//                                             ? Colors.white
//                                             : Colors.black,
//                                     prefixIcon: Icons.confirmation_number,
//                                     suffixIcon: Icons.arrow_drop_down,
//                                     iconColor:
//                                         isDarkMode
//                                             ? Colors.black54
//                                             : Colors.black54,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                             const SizedBox(height: 20),

//                             if (!widget.isInsideTabs)
//                               profileState.role.toLowerCase() == "admin"
//                                   ? Align(
//                                     alignment: Alignment.centerRight,
//                                     child: ElevatedButton(
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: AppTheme.primaryColor,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             10,
//                                           ),
//                                         ),
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 24,
//                                           vertical: 14,
//                                         ),
//                                       ),
//                                       onPressed:
//                                           profileState.isLoading
//                                               ? null
//                                               : () async {
//                                                 if (_profileFormKey
//                                                     .currentState!
//                                                     .validate()) {
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "fullName",
//                                                         fullNameController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "phoneNumber",
//                                                         phoneController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "address",
//                                                         addressController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "city",
//                                                         cityController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "pin",
//                                                         pinController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );

//                                                   await profileNotifier
//                                                       .saveProfile(
//                                                         context,
//                                                         ref,
//                                                       );

//                                                   if (context.mounted) {
//                                                     Navigator.pushNamed(
//                                                       context,
//                                                       "/mart-details",
//                                                     ); // ✅ Updated route
//                                                   }
//                                                 }
//                                               },
//                                       child:
//                                           profileState.isLoading
//                                               ? const CircularProgressIndicator(
//                                                 color: Colors.white,
//                                               )
//                                               : const Text(
//                                                 "Save & Next",
//                                                 style: TextStyle(
//                                                   fontSize: 18,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                     ),
//                                   )
//                                   : SizedBox(
//                                     width: double.infinity,
//                                     child: ElevatedButton(
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: AppTheme.primaryColor,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             10,
//                                           ),
//                                         ),
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 14,
//                                         ),
//                                       ),
//                                       onPressed:
//                                           profileState.isLoading
//                                               ? null
//                                               : () async {
//                                                 if (_profileFormKey
//                                                     .currentState!
//                                                     .validate()) {
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "fullName",
//                                                         fullNameController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "phoneNumber",
//                                                         phoneController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "address",
//                                                         addressController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "city",
//                                                         cityController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );
//                                                   profileNotifier
//                                                       .updateProfileField(
//                                                         "pin",
//                                                         pinController.text
//                                                             .trim(),
//                                                         ref,
//                                                       );

//                                                   await profileNotifier
//                                                       .saveProfile(
//                                                         context,
//                                                         ref,
//                                                       );
//                                                 }
//                                               },
//                                       child:
//                                           profileState.isLoading
//                                               ? const CircularProgressIndicator(
//                                                 color: Colors.white,
//                                               )
//                                               : const Text(
//                                                 "Save",
//                                                 style: TextStyle(
//                                                   fontSize: 18,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                     ),
//                                   ),
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
