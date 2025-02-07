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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accountabilibuddies"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigation Drawer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => context.go('/home'),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('My Goals'),
              onTap: () => context.go('/goals'),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Party'),
              onTap: () => context.go('/party'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('User Info'),
              onTap: () => context.go('/user-info'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () => _signOut(context), // ✅ Calls Firebase sign-out first
            ),
          ],
        ),
      ),
      body: child, // Ensures all screens keep the drawer
    );
  }
}
