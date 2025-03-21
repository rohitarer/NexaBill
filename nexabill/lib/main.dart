import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/auth_provider.dart';
import 'package:nexabill/providers/profile_provider.dart';
import 'package:nexabill/ui/screens/home_screen.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';
import 'package:nexabill/ui/screens/profile_screen.dart';
import 'package:nexabill/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: NexaBillApp()));
}

class NexaBillApp extends ConsumerWidget {
  const NexaBillApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authProvider);
    // final profileState = ref.watch(profileFutureProvider);

    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: userState.when(
        data: (user) {
          if (user == null) {
            return const SignInScreen(); // ✅ No User → Show Sign-In
          }

          // ✅ Now fetch profile only if user is logged in
          final profileState = ref.watch(profileFutureProvider);

          return profileState.when(
            data: (profileData) {
              bool isComplete = profileData['isProfileComplete'] ?? false;
              return isComplete ? const HomeScreen() : ProfileScreen();
            },
            loading:
                () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
            error: (_, __) => const SignInScreen(), // ✅ If error, go to Sign-In
          );
        },
        loading:
            () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        error: (_, __) => const SignInScreen(),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/providers/auth_provider.dart';
// import 'package:nexabill/providers/profile_provider.dart';
// import 'package:nexabill/ui/screens/home_screen.dart';
// import 'package:nexabill/ui/screens/signin_screen.dart';
// import 'package:nexabill/ui/screens/profile_screen.dart';
// import 'package:nexabill/core/theme.dart';

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

//     final profileState = ref.watch(profileFutureProvider);

//     return MaterialApp(
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,
//       debugShowCheckedModeBanner: false,
//       home: userState.when(
//         data: (user) {
//           if (user == null) {
//             return const SignInScreen(); // ✅ No User → Show Sign-In
//           }

//           return profileState.when(
//             data: (profileData) {
//               bool isComplete = profileData['isProfileCompleted'] ?? false;
//               return isComplete ? const HomeScreen() : ProfileScreen();
//             },

//             loading:
//                 () => const Scaffold(
//                   body: Center(child: CircularProgressIndicator()),
//                 ),
//             error: (_, __) => const SignInScreen(), // ✅ If error, go to Sign-In
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


