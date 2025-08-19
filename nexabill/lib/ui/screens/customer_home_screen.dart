import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexabill/core/theme.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/providers/cam_verification_provider.dart';
import 'package:nexabill/ui/widgets/custom_drawer.dart';
import 'package:nexabill/ui/widgets/bottom_input_bar.dart';
import 'package:nexabill/ui/widgets/bill_container.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';
import 'package:nexabill/providers/customer_home_provider.dart'
    hide camVerificationProvider;
import 'dart:convert';

final bluetoothItemCountProvider = StateProvider<int>((ref) => 0);
final bluetoothClassicInstanceProvider = Provider((ref) => BluetoothClassic());
final connectedDeviceProvider = StateProvider<Device?>((ref) => null);
final scannedProductsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);
final selectedAdminUidProvider = StateProvider<String?>((ref) => null);
final basketNumberProvider = StateProvider<String>((ref) => '');
final bluetoothDeviceProvider = StateProvider<Device?>((ref) => null);
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final adminUid = ref.watch(selectedAdminUidProvider);
  if (adminUid == null) return [];
  final snapshot =
      await FirebaseFirestore.instance
          .collection("products")
          .doc(adminUid)
          .collection("items")
          .get();
  return snapshot.docs.map((doc) => doc.data()).toList();
});

const serialUUID = '00001101-0000-1000-8000-00805f9b34fb';

// === MAC addresses of ESP32 ===
final List<String> espMacIds = ['7B:33:36:BE:D9:EC', 'FD:76:5A:02:36:C8'];

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final TextEditingController _basketController = TextEditingController();
  bool _isConnecting = false;
  bool _isConnected = false;
  late BluetoothClassic bluetooth;
  bool _isInitRunning = false;

  @override
  void initState() {
    super.initState();
    bluetooth = ref.read(bluetoothClassicInstanceProvider);
  }

  Future<void> fetchCamVerificationStatus(String? adminUid) async {
    if (adminUid == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(adminUid)
            .get();
    final isEnabled = doc.data()?['camVerification'] ?? false;
    ref.read(camVerificationProvider.notifier).state = isEnabled;
  }

  void onMartSelected(String martName) async {
    final martMap = ref.read(adminMartMapProvider);
    final adminUid = martMap[martName];
    ref.read(selectedMartProvider.notifier).state = martName;
    ref.read(selectedAdminUidProvider.notifier).state = adminUid;
    ref.read(basketNumberProvider.notifier).state = '';
    _basketController.clear();
    BillData.resetBillData();
    ref.invalidate(productsProvider);
    ref.invalidate(profileFutureProvider);
    ref.read(scannedProductsProvider.notifier).state = [];
    await fetchCamVerificationStatus(adminUid);
  }

  // Future<void> _connectToESP32() async {
  //   setState(() => _isConnecting = true);

  //   final basketCode = ref.read(basketNumberProvider);
  //   if (basketCode != '1001') {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("❌ Invalid basket number!")));
  //     setState(() => _isConnecting = false);
  //     return;
  //   }

  //   try {
  //     await bluetooth.initPermissions();

  //     try {
  //       if (_isConnected || ref.read(connectedDeviceProvider) != null) {
  //         await bluetooth.disconnect();
  //         debugPrint('🔌 Previous connection disconnected.');
  //       }
  //     } catch (_) {}

  //     final pairedDevices = await bluetooth.getPairedDevices();
  //     debugPrint('🔍 Paired devices: ${pairedDevices.length}');
  //     for (final dev in pairedDevices) {
  //       debugPrint('🔹 ${dev.name} (${dev.address})');
  //     }

  //     for (final device in pairedDevices) {
  //       if (device.name == 'ESP32-CAM-Counter' ||
  //           espMacIds.contains(device.address)) {
  //         debugPrint('✅ Matching ESP32 found: ${device.name}');
  //         await bluetooth.connect(device.address, serialUUID);

  //         ref.read(connectedDeviceProvider.notifier).state = device;
  //         ref.read(bluetoothItemCountProvider.notifier).state =
  //             0; // Reset count
  //         setState(() => _isConnected = true);

  //         String buffer = '';
  //         bluetooth.onDeviceDataReceived().listen((data) {
  //           buffer += String.fromCharCodes(data);
  //           if (buffer.contains('\n')) {
  //             final lines = buffer.trim().split('\n');
  //             for (var line in lines) {
  //               final count = int.tryParse(line.trim());
  //               if (count != null) {
  //                 final current = ref.read(bluetoothItemCountProvider);
  //                 final newCount = count.clamp(0, 9999);

  //                 ref.read(bluetoothItemCountProvider.notifier).state =
  //                     newCount;
  //                 debugPrint("📦 Basket Count: $newCount");
  //               }
  //             }
  //             buffer = '';
  //           }
  //         });

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("✅ Connected to ESP32: ${device.name}")),
  //         );
  //         break;
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Bluetooth error: $e");
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("❌ Connection failed: $e")));
  //   } finally {
  //     setState(() => _isConnecting = false);
  //   }
  // }

  Future<void> _connectToESP32() async {
    if (_isInitRunning) {
      debugPrint("⏳ Bluetooth init already in progress...");
      return;
    }

    setState(() => _isConnecting = true);
    _isInitRunning = true;

    final basketCode = ref.read(basketNumberProvider);
    if (basketCode != '1001') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Invalid basket number!")));
      setState(() => _isConnecting = false);
      _isInitRunning = false;
      return;
    }

    try {
      try {
        await bluetooth.initPermissions();
      } catch (e) {
        debugPrint("⚠️ Permissions already granted or in progress: $e");
      }

      if (_isConnected || ref.read(connectedDeviceProvider) != null) {
        try {
          await bluetooth.disconnect();
          debugPrint("🔌 Disconnected previous device.");
        } catch (e) {
          debugPrint("⚠️ Error during disconnect: $e");
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final pairedDevices = await bluetooth.getPairedDevices();
      debugPrint("🔍 Found ${pairedDevices.length} paired devices.");
      for (final device in pairedDevices) {
        debugPrint("🔹 ${device.name} (${device.address})");
      }

      for (final device in pairedDevices) {
        if (device.name == 'ESP32-CAM-Counter' ||
            espMacIds.contains(device.address)) {
          debugPrint("✅ Connecting to ${device.name}...");
          await bluetooth.connect(device.address, serialUUID);

          ref.read(connectedDeviceProvider.notifier).state = device;
          ref.read(bluetoothItemCountProvider.notifier).state = 0;
          setState(() => _isConnected = true);

          //         int? _baselineRawValue; // Declare this at class level

          // bluetooth.onDeviceDataReceived().listen((data) {
          //   try {
          //     final rawStr = utf8.decode(data.map((b) => b & 0xFF).toList()).trim();
          //     debugPrint("📥 Raw string received: $rawStr");

          //     final raw = int.tryParse(rawStr);
          //     if (raw == null) {
          //       debugPrint("❌ Invalid data received, skipping");
          //       return;
          //     }

          //     if (_baselineRawValue == null) {
          //       _baselineRawValue = raw;
          //       ref.read(bluetoothItemCountProvider.notifier).state = 0;
          //       debugPrint("🔰 Baseline set: $_baselineRawValue → Basket Count: 0");
          //       return;
          //     }

          //     int adjustedCount = raw - _baselineRawValue!;
          //     if (adjustedCount < 0) adjustedCount = 0;

          //     ref.read(bluetoothItemCountProvider.notifier).state = adjustedCount;
          //     debugPrint("📦 Basket Count: $adjustedCount");
          //   } catch (e) {
          //     debugPrint("❌ Error decoding Bluetooth data: $e");
          //   }
          // });

          int? baselineRawValue;
          final List<int> initialRawValues = [];
          const int initialWindowSize = 3;

          bluetooth.onDeviceDataReceived().listen((data) {
            try {
              final rawStr =
                  utf8.decode(data.map((b) => b & 0xFF).toList()).trim();
              debugPrint("📥 Raw string received: $rawStr");

              final raw = int.tryParse(rawStr);
              if (raw == null) {
                debugPrint("❌ Invalid data received, skipping");
                return;
              }

              // 🧠 Bootstrapping with initial readings
              if (baselineRawValue == null &&
                  initialRawValues.length < initialWindowSize) {
                initialRawValues.add(raw);
                debugPrint("🕵️ Bootstrapping... collected: $initialRawValues");

                if (initialRawValues.length >= initialWindowSize) {
                  baselineRawValue = initialRawValues.reduce(
                    (a, b) => a < b ? a : b,
                  );
                  debugPrint(
                    "✅ Baseline dynamically set to: $baselineRawValue",
                  );
                }

                ref.read(bluetoothItemCountProvider.notifier).state = 0;
                return;
              }

              // 🛡️ Dynamically shift baseline if new lower raw value found
              if (baselineRawValue != null && raw < baselineRawValue!) {
                debugPrint(
                  "📉 New lower raw value detected: $raw → resetting baseline",
                );
                baselineRawValue = raw;
              }

              // ✅ Compute adjusted count
              if (baselineRawValue != null) {
                int adjustedCount = raw - baselineRawValue!;
                if (adjustedCount < 0) adjustedCount = 0;

                ref.read(bluetoothItemCountProvider.notifier).state =
                    adjustedCount;
                debugPrint("📦 Basket Count: $adjustedCount");
              }
            } catch (e) {
              debugPrint("❌ Error decoding Bluetooth data: $e");
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Connected to ESP32: ${device.name}")),
          );
          break;
        }
      }
    } catch (e) {
      debugPrint("❌ Bluetooth error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Connection failed: $e")));
    } finally {
      setState(() => _isConnecting = false);
      _isInitRunning = false;
    }
  }

  @override
  void dispose() {
    _basketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final profileImage = ref.watch(profileImageProvider);
    final selectedMart = ref.watch(selectedMartProvider);
    final adminMarts = ref.watch(adminMartsProvider);
    final scannedProducts = ref.watch(scannedProductsProvider);
    final ScrollController scrollController = ScrollController();
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool camVerification = ref.watch(camVerificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("NexaBill"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.whiteColor,
        elevation: 2,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(fromHome: true),
                    ),
                  ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                    isDarkMode ? Colors.white24 : Colors.grey.shade300,
                child: profileImage.when(
                  data:
                      (imageData) =>
                          imageData != null
                              ? ClipOval(
                                child: Image.memory(
                                  imageData,
                                  fit: BoxFit.cover,
                                  width: 44,
                                  height: 44,
                                ),
                              )
                              : Icon(
                                Icons.person,
                                color: isDarkMode ? Colors.white : Colors.black,
                                size: 28,
                              ),
                  loading:
                      () => const CircularProgressIndicator(strokeWidth: 2),
                  error:
                      (_, __) =>
                          const Icon(Icons.error, color: Colors.red, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(isCustomer: true),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: adminMarts.when(
                  data: (marts) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMart,
                        icon: const Icon(
                          Icons.storefront,
                          color: Colors.blueAccent,
                        ),
                        isExpanded: true,
                        dropdownColor:
                            isDarkMode ? Colors.grey[850] : Colors.white,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        hint: const Text("Select a mart..."),
                        onChanged: (String? newMart) {
                          if (newMart != null) onMartSelected(newMart);
                        },
                        items:
                            marts.map((String mart) {
                              return DropdownMenuItem<String>(
                                value: mart,
                                child: Text(mart),
                              );
                            }).toList(),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text("Error loading marts: $error"),
                ),
              ),
              if (camVerification)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _basketController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            labelText: "Enter 4-digit Basket Number",
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) =>
                                  ref
                                      .read(basketNumberProvider.notifier)
                                      .state = value,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed:
                            _isConnecting || _isConnected
                                ? null
                                : _connectToESP32,
                        child:
                            _isConnecting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(_isConnected ? 'Connected' : 'Connect'),
                      ),
                    ],
                  ),
                ),

              // Consumer(
              //   builder: (context, ref, _) {
              //     final count = ref.watch(bluetoothItemCountProvider);
              //     return Padding(
              //       padding: const EdgeInsets.only(top: 8.0),
              //       child: Text(
              //         "🧺 Items in Basket: $count",
              //         style: TextStyle(
              //           fontSize: 16,
              //           fontWeight: FontWeight.bold,
              //           color: Colors.green[700],
              //         ),
              //       ),
              //     );
              //   },
              // ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableHeight = constraints.maxHeight;
                    final double spacing = availableHeight * 0.15;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedMart == null
                              ? "Please select a mart to generate a bill"
                              : "🛒 Welcome to $selectedMart 🛒",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        SizedBox(height: spacing),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (selectedMart != null)
            BillContainer(
              scrollController: scrollController,
              billItems: scannedProducts,
              isKeyboardOpen: isKeyboardOpen,
            ),
          if (selectedMart != null)
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomInputBar(),
            ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/data/bill_data.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/ui/widgets/custom_drawer.dart';
// import 'package:nexabill/ui/widgets/bottom_input_bar.dart';
// import 'package:nexabill/ui/widgets/bill_container.dart';
// import 'package:nexabill/ui/screens/profile_screen.dart';
// import 'package:nexabill/providers/customer_home_provider.dart';

// // ✅ Provider to hold scanned products added via QR screen
// final scannedProductsProvider = StateProvider<List<Map<String, dynamic>>>(
//   (ref) => [],
// );

// // ✅ Admin UID selected after mart selection
// final selectedAdminUidProvider = StateProvider<String?>((ref) => null);

// // ✅ Load all products of selected mart
// final productsProvider = FutureProvider<List<Map<String, dynamic>>>((
//   ref,
// ) async {
//   final adminUid = ref.watch(selectedAdminUidProvider);
//   if (adminUid == null) return [];

//   final snapshot =
//       await FirebaseFirestore.instance
//           .collection("products")
//           .doc(adminUid)
//           .collection("items")
//           .get();

//   return snapshot.docs.map((doc) => doc.data()).toList();
// });

// class CustomerHomeScreen extends ConsumerWidget {
//   const CustomerHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;
//     final profileImage = ref.watch(profileImageProvider);
//     final selectedMart = ref.watch(selectedMartProvider);
//     final adminMarts = ref.watch(adminMartsProvider);
//     final scannedProducts = ref.watch(scannedProductsProvider);
//     final ScrollController scrollController = ScrollController();

//     void onMartSelected(String martName) {
//       final martMap = ref.read(adminMartMapProvider);
//       debugPrint("💡 Mart Map: $martMap");

//       final adminUid = martMap[martName];
//       debugPrint("🔐 onMartSelected -> UID for $martName: $adminUid");

//       // ✅ Clear previous bill session completely
//       BillData.resetBillData(); // Use the method inside BillData class

//       // ✅ Update the selected mart name and admin UID
//       ref.read(selectedMartProvider.notifier).state = martName;
//       ref.read(selectedAdminUidProvider.notifier).state = adminUid;

//       // 🔁 Invalidate dependencies so that new data gets reloaded
//       ref.invalidate(productsProvider);
//       ref.invalidate(profileFutureProvider);

//       // 🧹 Clear any previously scanned items
//       ref.read(scannedProductsProvider.notifier).state = [];

//       debugPrint("🧹 BillData and UI state reset successfully for: $martName");
//     }

//     final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
//     final bool isKeyboardOpen = keyboardHeight > 0;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("NexaBill"),
//         backgroundColor: theme.appBarTheme.backgroundColor,
//         foregroundColor: AppTheme.whiteColor,
//         elevation: 2,
//         leading: Builder(
//           builder:
//               (context) => IconButton(
//                 icon: const Icon(Icons.menu),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: GestureDetector(
//               onTap:
//                   () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ProfileScreen(fromHome: true),
//                     ),
//                   ),
//               child: CircleAvatar(
//                 radius: 22,
//                 backgroundColor:
//                     isDarkMode ? Colors.white24 : Colors.grey.shade300,
//                 child: profileImage.when(
//                   data:
//                       (imageData) =>
//                           imageData != null
//                               ? ClipOval(
//                                 child: Image.memory(
//                                   imageData,
//                                   fit: BoxFit.cover,
//                                   width: 44,
//                                   height: 44,
//                                 ),
//                               )
//                               : Icon(
//                                 Icons.person,
//                                 color: isDarkMode ? Colors.white : Colors.black,
//                                 size: 28,
//                               ),
//                   loading:
//                       () => const CircularProgressIndicator(strokeWidth: 2),
//                   error:
//                       (_, __) =>
//                           const Icon(Icons.error, color: Colors.red, size: 28),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       drawer: const CustomDrawer(isCustomer: true),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: adminMarts.when(
//                   data: (marts) {
//                     return DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: selectedMart,
//                         icon: const Icon(
//                           Icons.storefront,
//                           color: Colors.blueAccent,
//                         ),
//                         isExpanded: true,
//                         dropdownColor:
//                             isDarkMode ? Colors.grey[850] : Colors.white,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isDarkMode ? Colors.white : Colors.black,
//                         ),
//                         hint: const Text("Select a mart..."),
//                         onChanged: (String? newMart) {
//                           if (newMart != null) onMartSelected(newMart);
//                         },
//                         items:
//                             marts.map((String mart) {
//                               return DropdownMenuItem<String>(
//                                 value: mart,
//                                 child: Text(mart),
//                               );
//                             }).toList(),
//                       ),
//                     );
//                   },
//                   loading: () => const CircularProgressIndicator(),
//                   error: (error, _) => Text("Error loading marts: $error"),
//                 ),
//               ),
//               Expanded(
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     final double availableHeight = constraints.maxHeight;
//                     final double spacing = availableHeight * 0.15;

//                     return Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           selectedMart == null
//                               ? "Please select a mart to generate a bill"
//                               : "🛒 Welcome to $selectedMart 🛒",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: isDarkMode ? Colors.white70 : Colors.black87,
//                           ),
//                         ),
//                         SizedBox(height: spacing),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),

//           // ✅ Bill Container with dynamic scanned product list
//           if (selectedMart != null)
//             BillContainer(
//               scrollController: scrollController,
//               billItems: scannedProducts,
//               isKeyboardOpen: isKeyboardOpen,
//             ),

//           // ✅ Bottom Input Bar
//           if (selectedMart != null)
//             const Align(
//               alignment: Alignment.bottomCenter,
//               child: BottomInputBar(),
//             ),
//         ],
//       ),
//     );
//   }
// }
