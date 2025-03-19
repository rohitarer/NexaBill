import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/providers/auth_provider.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authNotifier = ref.read(
      authNotifierProvider.notifier,
    ); // ✅ Use Notifier

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
            onTap: () {
              // TODO: Navigate to dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              // TODO: Navigate to settings
            },
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
                // ✅ Call Logout Function from AuthNotifier (Riverpod)
                await authNotifier.logOut();
              }
            },
          ),
        ],
      ),
    );
  }

  // ✅ **Logout Confirmation Dialog**
  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to log out?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false), // Cancel
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.pop(context, true), // Confirm Logout
                    child: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
        ) ??
        false; // Return false if dismissed
  }
}



// import 'package:flutter/material.dart';
// import 'package:nexabill/core/theme.dart';
// import 'package:nexabill/services/auth_service.dart';

// class CustomDrawer extends StatelessWidget {
//   const CustomDrawer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

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
//               // ✅ Show Confirmation Dialog Before Logout
//               bool confirmLogout = await _showLogoutDialog(context);
//               if (confirmLogout) {
//                 // ✅ Call Logout Function in AuthService
//                 await AuthService().forceLogout(context);
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

