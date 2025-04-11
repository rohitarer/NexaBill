import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/auth_provider.dart';
import 'package:nexabill/ui/screens/signin_screen.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            child: const Text(
              "NexaBill Menu",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              bool confirmLogout = await _showLogoutDialog(context);
              if (confirmLogout) {
                final navigator = Navigator.of(context);
                ref.read(authNotifierProvider.notifier).logOut(ref);
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to log out?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nexabill/providers/auth_provider.dart';

// class CustomDrawer extends ConsumerWidget {
//   const CustomDrawer({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     final authNotifier = ref.read(
//       authNotifierProvider.notifier,
//     ); // ✅ Use Notifier

//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: theme.primaryColor),
//             child: const Text(
//               "NexaBill Menu",
//               style: TextStyle(color: Colors.white, fontSize: 22),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.dashboard),
//             title: const Text("Dashboard"),
//             onTap: () {
//               // TODO: Navigate to dashboard
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text("Settings"),
//             onTap: () {
//               // TODO: Navigate to settings
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.logout, color: Colors.redAccent),
//             title: const Text(
//               "Logout",
//               style: TextStyle(color: Colors.redAccent),
//             ),
//             onTap: () async {
//               bool confirmLogout = await _showLogoutDialog(context);
//               if (confirmLogout) {
//                 // ✅ Call Logout Function from AuthNotifier (Riverpod)
//                 await authNotifier.logOut(ref);
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ **Logout Confirmation Dialog**
//   Future<bool> _showLogoutDialog(BuildContext context) async {
//     return await showDialog(
//           context: context,
//           builder:
//               (context) => AlertDialog(
//                 title: const Text("Logout"),
//                 content: const Text("Are you sure you want to log out?"),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context, false), // Cancel
//                     child: const Text("Cancel"),
//                   ),
//                   TextButton(
//                     onPressed:
//                         () => Navigator.pop(context, true), // Confirm Logout
//                     child: const Text(
//                       "Logout",
//                       style: TextStyle(color: Colors.redAccent),
//                     ),
//                   ),
//                 ],
//               ),
//         ) ??
//         false; // Return false if dismissed
//   }
// }

