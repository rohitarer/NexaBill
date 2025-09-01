import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/utils/clear_bill_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/auth_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/services/role_routes.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint("🔥 Firebase projectId: ${Firebase.app().options.projectId}");

  // App Check: ONLY enable in release. Skip entirely in debug.
  if (kReleaseMode) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
      debugPrint("✅ Firebase App Check activated (release).");
    } catch (e) {
      debugPrint("⚠️ Firebase App Check activation failed: $e");
    }
  } else {
    debugPrint("🧪 Debug build detected — skipping Firebase App Check.");
  }

  runApp(const ProviderScope(child: NexaBillApp()));
}

class NexaBillApp extends ConsumerStatefulWidget {
  const NexaBillApp({super.key});

  @override
  ConsumerState<NexaBillApp> createState() => _NexaBillAppState();
}

class _NexaBillAppState extends ConsumerState<NexaBillApp> {
  String? _lastRoute;
  bool _routeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLastRoute();
  }

  Future<void> _loadLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    _lastRoute = prefs.getString('last_route');
    debugPrint("✅ Loaded last_route: $_lastRoute");
    setState(() => _routeLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authProvider);

    if (!_routeLoaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.generateRoute,
      home: userState.when(
        data: (user) {
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              clearAllBillState(ref);
            });
            debugPrint("👤 No user, going to SignInScreen");
            return const SignInScreen();
          }

          final profileState = ref.watch(profileFutureProvider);

          return profileState.when(
            data: (profileData) {
              final role =
                  (profileData['role'] as String?)?.toLowerCase() ?? 'customer';
              final isComplete =
                  (profileData['isProfileComplete'] as bool?) ?? false;

              if (_lastRoute != null && _lastRoute!.isNotEmpty) {
                debugPrint("🚀 Redirecting to saved route: $_lastRoute");
                final routeWidget = AppRoutes.getScreenFromRoute(_lastRoute!);
                if (routeWidget != null) return routeWidget;
              }

              final screen = AppRoutes.getHomeScreen(role, isComplete);
              debugPrint("🚀 Fallback to computed screen: $screen");
              return screen;
            },
            loading:
                () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
            error: (e, _) {
              debugPrint("❌ Error loading profile: $e");
              return const SignInScreen();
            },
          );
        },
        loading:
            () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        error: (e, _) {
          debugPrint("❌ Error loading auth: $e");
          return const SignInScreen();
        },
      ),
    );
  }
}

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/utils/clear_bill_state.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/providers/auth_provider.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/services/role_routes.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   // ✅ Safely activate Firebase App Check for dev
//   if (!kReleaseMode) {
//       await FirebaseAppCheck.instance.activate(
//     androidProvider: AndroidProvider.debug,
//     appleProvider: AppleProvider.debug,
//   );

//   } else {
//     try {
//       await FirebaseAppCheck.instance.activate(
//         androidProvider: AndroidProvider.playIntegrity,
//         appleProvider: AppleProvider.deviceCheck,
//       );
//       debugPrint("✅ Firebase App Check activated in debug mode.");
//     } catch (e) {
//       debugPrint("⚠️ Firebase App Check activation failed: $e");
//     }

//     runApp(const ProviderScope(child: NexaBillApp()));
//   }
// }

// class NexaBillApp extends ConsumerStatefulWidget {
//   const NexaBillApp({super.key});

//   @override
//   ConsumerState<NexaBillApp> createState() => _NexaBillAppState();
// }

// class _NexaBillAppState extends ConsumerState<NexaBillApp> {
//   String? _lastRoute;
//   bool _routeLoaded = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadLastRoute();
//   }

//   Future<void> _loadLastRoute() async {
//     final prefs = await SharedPreferences.getInstance();
//     _lastRoute = prefs.getString('last_route');
//     debugPrint("✅ Loaded last_route: $_lastRoute");
//     setState(() => _routeLoaded = true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userState = ref.watch(authProvider);

//     if (!_routeLoaded) {
//       return const MaterialApp(
//         home: Scaffold(body: Center(child: CircularProgressIndicator())),
//       );
//     }

//     return MaterialApp(
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,
//       debugShowCheckedModeBanner: false,
//       onGenerateRoute: AppRoutes.generateRoute,
//       home: userState.when(
//         data: (user) {
//           if (user == null) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               clearAllBillState(ref);
//             });
//             debugPrint("👤 No user, going to SignInScreen");
//             return const SignInScreen();
//           }

//           final profileState = ref.watch(profileFutureProvider);

//           return profileState.when(
//             data: (profileData) {
//               // final role = profileData['role'] ?? 'customer';
//               // final isComplete = profileData['isProfileComplete'] ?? false;

//               final role =
//                   (profileData['role'] as String?)?.toLowerCase() ?? 'customer';
//               final isComplete =
//                   (profileData['isProfileComplete'] as bool?) ?? false;

//               if (_lastRoute != null && _lastRoute!.isNotEmpty) {
//                 debugPrint("🚀 Redirecting to saved route: $_lastRoute");
//                 final routeWidget = AppRoutes.getScreenFromRoute(_lastRoute!);
//                 if (routeWidget != null) return routeWidget;
//               }

//               final screen = AppRoutes.getHomeScreen(role, isComplete);
//               debugPrint("🚀 Fallback to computed screen: $screen");
//               return screen;
//             },
//             loading:
//                 () => const Scaffold(
//                   body: Center(child: CircularProgressIndicator()),
//                 ),
//             error: (e, _) {
//               debugPrint("❌ Error loading profile: $e");
//               return const SignInScreen();
//             },
//           );
//         },
//         loading:
//             () => const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             ),
//         error: (e, _) {
//           debugPrint("❌ Error loading auth: $e");
//           return const SignInScreen();
//         },
//       ),
//     );
//   }
// }
