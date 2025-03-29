import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexabill/core/theme.dart';
import 'package:nexabill/providers/auth_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/services/role_routes.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
            debugPrint("👤 No user, going to SignInScreen");
            return const SignInScreen();
          }

          final profileState = ref.watch(profileFutureProvider);

          return profileState.when(
            data: (profileData) {
              final role = profileData['role'] ?? 'customer';
              final isComplete = profileData['isProfileComplete'] ?? false;

              // Check if there's a saved last route
              if (_lastRoute != null && _lastRoute!.isNotEmpty) {
                debugPrint("🚀 Redirecting to saved route: $_lastRoute");

                // Generate route based on string (if needed)
                final routeWidget = AppRoutes.getScreenFromRoute(_lastRoute!);
                if (routeWidget != null) return routeWidget;
              }

              // Else, fallback based on role/profile
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

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/providers/auth_provider.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/services/role_routes.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   runApp(const ProviderScope(child: NexaBillApp()));
// }

// class NexaBillApp extends ConsumerWidget {
//   const NexaBillApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final userState = ref.watch(authProvider);

//     return MaterialApp(
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,
//       debugShowCheckedModeBanner: false,
//       onGenerateRoute: AppRoutes.generateRoute,
//       initialRoute: '/',
//       home: userState.when(
//         data: (user) {
//           if (user == null) {
//             return const SignInScreen();
//           }

//           final profileState = ref.watch(profileFutureProvider);

//           return profileState.when(
//             data: (profileData) {
//               bool isComplete = profileData['isProfileComplete'] ?? false;
//               String role = profileData['role'] ?? 'Customer';

//               return AppRoutes.getHomeScreen(role, isComplete);
//             },
//             loading:
//                 () => const Scaffold(
//                   body: Center(child: CircularProgressIndicator()),
//                 ),
//             error: (_, __) => const SignInScreen(),
//           );
//         },
//         loading:
//             () => const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             ),
//         error: (_, __) => const SignInScreen(),
//       ),
//     );
//   }
// }
