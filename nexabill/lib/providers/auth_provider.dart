import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexabill/services/auth_service.dart';

// Provides Access to `AuthService`
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Authentication State Provider (Listens for Firebase Auth Changes)
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// AuthNotifier (Handles Signup, Login, Logout)
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _initializeUser();
  }

  // Initialize & Check Current User
  Future<void> _initializeUser() async {
    try {
      const int maxRetries = 5;
      int attempt = 0;

      while (attempt < maxRetries) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          state = AsyncValue.data(user);
          return;
        }
        attempt++;
        await Future.delayed(const Duration(seconds: 2)); // Retry delay
      }

      state = const AsyncValue.data(null); // No user found after retries
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  // Sign Up
  Future<void> signUp({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required Function(String?) onError, // Error callback
    required Function() onSuccess, // Success callback
  }) async {
    try {
      state = const AsyncValue.loading();
      String? error = await _authService.signUp(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
      );

      if (error == null) {
        await _initializeUser(); // Ensure state is updated
        onSuccess(); // Call success callback
      } else {
        state = AsyncValue.error(error, StackTrace.current);
        onError(error); // Call error callback
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
      onError(e.toString());
    }
  }

  // Log In
  Future<void> logIn({
    required String email,
    required String password,
    required Function(String?) onError, // Error callback
    required Function() onSuccess, // Success callback
  }) async {
    try {
      state = const AsyncValue.loading();
      String? error = await _authService.logIn(
        email: email,
        password: password,
      );

      if (error == null) {
        await _initializeUser(); // Ensure state is updated
        onSuccess(); // Call success callback
      } else {
        state = AsyncValue.error(error, StackTrace.current);
        onError(error); // Call error callback
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
      onError(e.toString());
    }
  }

  // Log Out
  Future<void> logOut() async {
    try {
      state = const AsyncValue.loading();
      await _authService.logOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }
}

// Auth State Notifier Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final authService = ref.read(authServiceProvider);
      return AuthNotifier(authService);
    });



// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:nexabill/services/auth_service.dart';

// // ✅ Provides Access to `AuthService`
// final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// // ✅ Authentication State Provider (Listens for Firebase Auth Changes)
// final authProvider = StreamProvider<User?>((ref) {
//   return FirebaseAuth.instance.authStateChanges();
// });

// // ✅ **AuthNotifier** (Handles Signup, Login, Logout)
// class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
//   final AuthService _authService;

//   AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
//     _checkCurrentUser();
//   }

//   // ✅ **Check & Set Current User**
//   Future<void> _checkCurrentUser() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       state = AsyncValue.data(user);
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e.toString(), stackTrace);
//     }
//   }

//   // ✅ **Sign Up**
//   Future<void> signUp({
//     required String fullName,
//     required String phoneNumber,
//     required String email,
//     required String password,
//     required Function(String?) onError, // Error callback
//     required Function() onSuccess, // Success callback
//   }) async {
//     try {
//       state = const AsyncValue.loading();
//       String? error = await _authService.signUp(
//         fullName: fullName,
//         phoneNumber: phoneNumber,
//         email: email,
//         password: password,
//       );

//       if (error == null) {
//         state = AsyncValue.data(_authService.currentUser);
//         onSuccess(); // Call success callback
//       } else {
//         state = AsyncValue.error(error, StackTrace.current);
//         onError(error); // Call error callback
//       }
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e.toString(), stackTrace);
//       onError(e.toString());
//     }
//   }

//   // ✅ **Log In**
//   Future<void> logIn({
//     required String email,
//     required String password,
//     required Function(String?) onError, // Error callback
//     required Function() onSuccess, // Success callback
//   }) async {
//     try {
//       state = const AsyncValue.loading();
//       String? error = await _authService.logIn(
//         email: email,
//         password: password,
//       );

//       if (error == null) {
//         state = AsyncValue.data(_authService.currentUser);
//         onSuccess(); // Call success callback
//       } else {
//         state = AsyncValue.error(error, StackTrace.current);
//         onError(error); // Call error callback
//       }
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e.toString(), stackTrace);
//       onError(e.toString());
//     }
//   }

//   // ✅ **Log Out**
//   Future<void> logOut() async {
//     try {
//       state = const AsyncValue.loading();
//       await _authService.logOut();
//       state = const AsyncValue.data(null);
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e.toString(), stackTrace);
//     }
//   }
// }

// // ✅ **Auth State Notifier Provider**
// final authNotifierProvider =
//     StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
//       final authService = ref.read(authServiceProvider);
//       return AuthNotifier(authService);
//     });

