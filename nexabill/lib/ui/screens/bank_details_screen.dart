import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/services/role_routes.dart';
import 'package:nexabill/ui/screens/mart_details_screen.dart';
import 'package:nexabill/ui/widgets/custom_textfield.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  final bool isInsideTabs;
  const BankDetailsScreen({super.key, this.isInsideTabs = false});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final GlobalKey<FormState> _bankFormKey = GlobalKey<FormState>();
  late TextEditingController accountHolderController;
  late TextEditingController accountNumberController;
  late TextEditingController ifscController;
  late TextEditingController upiController;

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(profileNotifierProvider);

    accountHolderController = TextEditingController(
      text: profileState.bankHolder,
    );
    accountNumberController = TextEditingController(
      text: profileState.bankAccountNumber,
    );
    ifscController = TextEditingController(text: profileState.bankIFSC);
    upiController = TextEditingController(text: profileState.bankUPI);
  }

  @override
  void dispose() {
    accountHolderController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profileNotifier = ref.read(profileNotifierProvider.notifier);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final passbookImage = profileState.passbookImage;
    final panImage = profileState.panImage;
    final aadharImage = profileState.aadharImage;
    final uploadedDocs = [
      if (passbookImage != null) passbookImage,
      if (panImage != null) panImage,
      if (aadharImage != null) aadharImage,
    ];

    return Scaffold(
      appBar:
          widget.isInsideTabs
              ? null
              : AppBar(title: const Text('Bank Details')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child:
                  uploadedDocs.isNotEmpty
                      ? CarouselSlider(
                        options: CarouselOptions(
                          viewportFraction: 1.0,
                          autoPlay: true,
                          height: 200,
                        ),
                        items:
                            uploadedDocs.map((img) {
                              return Image.file(
                                img,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            }).toList(),
                      )
                      : Container(
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
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _bankFormKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: accountHolderController,
                      label: "Account Holder Name",
                      hintText: "Enter account holder name",
                      prefixIcon: Icons.person,
                      labelColor: isDarkMode ? Colors.white : Colors.black,
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                    CustomTextField(
                      controller: accountNumberController,
                      label: "Account Number",
                      hintText: "Enter account number",
                      prefixIcon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      labelColor: isDarkMode ? Colors.white : Colors.black,
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                    CustomTextField(
                      controller: ifscController,
                      label: "IFSC Code",
                      hintText: "Enter IFSC code",
                      prefixIcon: Icons.account_balance,
                      labelColor: isDarkMode ? Colors.white : Colors.black,
                      validator: (value) => value!.isEmpty ? "Required" : null,
                      onChanged: (value) {
                        if (value.trim().length == 11) {
                          profileNotifier.fetchBankDetailsFromIFSC(
                            value.trim(),
                          );
                        } else {
                          profileNotifier.updateProfileField(
                            "bankName",
                            "",
                            ref,
                          );
                        }
                      },
                    ),
                    if (profileState.bankName != null &&
                        profileState.bankName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "\u{1F3E6} ${profileState.bankName!}",
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDocButton(
                          label: "Passbook",
                          image: passbookImage,
                          onTap:
                              () =>
                                  profileNotifier.pickBankDocument("passbook"),
                        ),
                        _buildDocButton(
                          label: "PAN",
                          image: panImage,
                          onTap: () => profileNotifier.pickBankDocument("pan"),
                        ),
                        _buildDocButton(
                          label: "Aadhar",
                          image: aadharImage,
                          onTap:
                              () => profileNotifier.pickBankDocument("aadhar"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: upiController,
                      label: "UPI ID",
                      hintText: "Enter UPI ID",
                      prefixIcon: Icons.qr_code,
                      labelColor: isDarkMode ? Colors.white : Colors.black,
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 24),
                    if (!widget.isInsideTabs)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 🔙 Previous Button
                          ElevatedButton(
                            onPressed: () {
                              final state = ref.read(profileNotifierProvider);
                              final role = state.role.toLowerCase();
                              final isProfileComplete = state.isProfileComplete;

                              if (role == 'admin') {
                                if (!isProfileComplete) {
                                  // 🔙 Go to MartDetails if profile not complete
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MartDetailsScreen(),
                                    ),
                                  );
                                } else {
                                  // ✅ If complete, go to admin home
                                  AppRoutes.navigateToHomeByRole(context, role);
                                }
                              } else {
                                // 🔁 For non-admin roles, simply pop
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  AppRoutes.navigateToHomeByRole(context, role);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            child: const Text(
                              "Previous",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),

                          // 💾 Save Button
                          ElevatedButton(
                            onPressed:
                                profileState.isLoading
                                    ? null
                                    : () async {
                                      if (_bankFormKey.currentState!
                                          .validate()) {
                                        // Update all bank fields
                                        profileNotifier.updateProfileField(
                                          "bankHolder",
                                          accountHolderController.text.trim(),
                                          ref,
                                        );
                                        profileNotifier.updateProfileField(
                                          "bankAccountNumber",
                                          accountNumberController.text.trim(),
                                          ref,
                                        );
                                        profileNotifier.updateProfileField(
                                          "bankIFSC",
                                          ifscController.text.trim(),
                                          ref,
                                        );
                                        profileNotifier.updateProfileField(
                                          "bankUPI",
                                          upiController.text.trim(),
                                          ref,
                                        );

                                        // Save profile
                                        await profileNotifier.saveProfile(
                                          context,
                                          ref,
                                        );

                                        // ✅ Navigate to home if profile is now complete and role is admin
                                        final state = ref.read(
                                          profileNotifierProvider,
                                        );
                                        if (state.isProfileComplete &&
                                            state.role.toLowerCase() ==
                                                'admin') {
                                          AppRoutes.navigateToHomeByRole(
                                            context,
                                            state.role,
                                          );
                                        }
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
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
                                      "Save",
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocButton({
    required String label,
    required File? image,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 45),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 16),
                  const SizedBox(width: 4),
                  Text(label, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          if (image != null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
    );
  }
}

// import 'dart:convert';
// import 'dart:io';

// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/ui/widgets/custom_textfield.dart';

// class BankDetailsScreen extends ConsumerStatefulWidget {
//   const BankDetailsScreen({super.key});

//   @override
//   ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
// }

// class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   late TextEditingController accountHolderController;
//   late TextEditingController accountNumberController;
//   late TextEditingController ifscController;
//   late TextEditingController upiController;

//   File? passbookImage;
//   File? panImage;
//   File? aadharImage;

//   String? _bankInfo;

//   @override
//   void initState() {
//     super.initState();
//     accountHolderController = TextEditingController();
//     accountNumberController = TextEditingController();
//     ifscController = TextEditingController();
//     upiController = TextEditingController();
//   }

//   @override
//   void dispose() {
//     accountHolderController.dispose();
//     accountNumberController.dispose();
//     ifscController.dispose();
//     upiController.dispose();
//     super.dispose();
//   }

//   Future<void> pickDocumentImage(String type) async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         final image = File(picked.path);
//         switch (type) {
//           case 'passbook':
//             passbookImage = image;
//             break;
//           case 'pan':
//             panImage = image;
//             break;
//           case 'aadhar':
//             aadharImage = image;
//             break;
//         }
//       });
//     }
//   }

//   List<File> get uploadedDocs => [
//     if (passbookImage != null) passbookImage!,
//     if (panImage != null) panImage!,
//     if (aadharImage != null) aadharImage!,
//   ];

//   Future<void> fetchBankDetails(String ifscCode) async {
//     final url = Uri.parse("https://ifsc.razorpay.com/$ifscCode");

//     try {
//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final bank = data['BANK'];
//         final branch = data['BRANCH'];

//         if (bank != null && branch != null) {
//           setState(() {
//             _bankInfo = "$bank, $branch";
//           });
//         } else {
//           setState(() {
//             _bankInfo = "Bank details not found";
//           });
//         }
//       } else {
//         setState(() {
//           _bankInfo = "Invalid IFSC code";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _bankInfo = "Error fetching bank details";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Bank Details")),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Stack(
//               children: [
//                 SizedBox(
//                   height: 200,
//                   width: double.infinity,
//                   child:
//                       uploadedDocs.isNotEmpty
//                           ? CarouselSlider(
//                             options: CarouselOptions(
//                               viewportFraction: 1.0,
//                               autoPlay: true,
//                               height: 200,
//                             ),
//                             items:
//                                 uploadedDocs.map((img) {
//                                   return Image.file(
//                                     img,
//                                     fit: BoxFit.cover,
//                                     width: double.infinity,
//                                   );
//                                 }).toList(),
//                           )
//                           : Container(
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
//                 ),
//               ],
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     CustomTextField(
//                       controller: accountHolderController,
//                       label: "Account Holder Name",
//                       hintText: "Enter account holder name",
//                       prefixIcon: Icons.person,
//                       labelColor: isDarkMode ? Colors.white : Colors.black,
//                       validator: (value) => value!.isEmpty ? "Required" : null,
//                     ),
//                     CustomTextField(
//                       controller: accountNumberController,
//                       label: "Account Number",
//                       hintText: "Enter account number",
//                       prefixIcon: Icons.credit_card,
//                       keyboardType: TextInputType.number,
//                       labelColor: isDarkMode ? Colors.white : Colors.black,
//                       validator: (value) => value!.isEmpty ? "Required" : null,
//                     ),
//                     CustomTextField(
//                       controller: ifscController,
//                       label: "IFSC Code",
//                       hintText: "Enter IFSC code",
//                       prefixIcon: Icons.account_balance,
//                       labelColor: isDarkMode ? Colors.white : Colors.black,
//                       validator: (value) => value!.isEmpty ? "Required" : null,
//                       onChanged: (value) {
//                         if (value.trim().length == 11) {
//                           fetchBankDetails(value.trim().toUpperCase());
//                         } else {
//                           setState(() {
//                             _bankInfo = null;
//                           });
//                         }
//                       },
//                     ),
//                     if (_bankInfo != null)
//                       Padding(
//                         padding: const EdgeInsets.only(left: 4),
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             "🏦 $_bankInfo",
//                             style: TextStyle(
//                               color:
//                                   isDarkMode ? Colors.white70 : Colors.black87,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildDocButton(
//                           "Passbook",
//                           passbookImage,
//                           () => pickDocumentImage("passbook"),
//                         ),
//                         _buildDocButton(
//                           "PAN",
//                           panImage,
//                           () => pickDocumentImage("pan"),
//                         ),
//                         _buildDocButton(
//                           "Aadhar",
//                           aadharImage,
//                           () => pickDocumentImage("aadhar"),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     CustomTextField(
//                       controller: upiController,
//                       label: "UPI ID",
//                       hintText: "Enter UPI ID",
//                       prefixIcon: Icons.qr_code,
//                       labelColor: isDarkMode ? Colors.white : Colors.black,
//                       validator: (value) => value!.isEmpty ? "Required" : null,
//                     ),
//                     const SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.grey[300],
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 20,
//                               vertical: 14,
//                             ),
//                           ),
//                           onPressed: () => Navigator.pop(context),
//                           child: const Text(
//                             "Previous",
//                             style: TextStyle(color: Colors.black),
//                           ),
//                         ),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppTheme.primaryColor,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 24,
//                               vertical: 14,
//                             ),
//                           ),
//                           onPressed: () {
//                             if (_formKey.currentState!.validate()) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text("Bank details saved."),
//                                 ),
//                               );
//                               // TODO: Save and navigate or persist last route
//                             }
//                           },
//                           child: const Text(
//                             "Save",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDocButton(String label, File? image, VoidCallback onTap) {
//     return SizedBox(
//       width: 100,
//       child: Column(
//         children: [
//           ElevatedButton(
//             onPressed: onTap,
//             style: ElevatedButton.styleFrom(
//               minimumSize: const Size(100, 45),
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//             ),
//             child: FittedBox(
//               fit: BoxFit.scaleDown,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.image, size: 16),
//                   const SizedBox(width: 4),
//                   Text(label, style: const TextStyle(fontSize: 13)),
//                 ],
//               ),
//             ),
//           ),
//           if (image != null)
//             const Padding(
//               padding: EdgeInsets.only(top: 6),
//               child: Icon(Icons.check_circle, color: Colors.green),
//             ),
//         ],
//       ),
//     );
//   }
// }
