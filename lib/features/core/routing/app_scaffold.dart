import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // ✅ Actually logs out the user
    if (context.mounted) {
      context.go('/'); // ✅ Redirects to AuthGate
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accountabilibuddies"),
        // For small screens, make sure the title fits
        titleSpacing: isSmallScreen ? 0 : NavigationToolbar.kMiddleSpacing,
      ),
      drawer: Drawer(
        // Make drawer take appropriate width based on screen size
        width: isSmallScreen ? screenWidth * 0.85 : 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigation Drawer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 20 : 24,
                ),
              ),
            ),
            // Increase touch target size for mobile
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => context.go('/home'),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: const Icon(Icons.flag_outlined),
              title: const Text('My Goals'),
              onTap: () => context.go('/goals'),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: const Icon(Icons.group),
              title: const Text('Party'),
              onTap: () => context.go('/party'),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: const Icon(Icons.person),
              title: const Text('User Info'),
              onTap: () => context.go('/user-info'),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: const Icon(Icons.warning),
              title: const Text('Time Machine'),
              onTap: () => context.go('/time-machine'),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () => _signOut(context), // ✅ Calls Firebase sign-out first
            ),
          ],
        ),
      ),
      // Wrap body in SafeArea to avoid notches and system UI elements
      body: SafeArea(
        child: child,
      ),
    );
  }
}
