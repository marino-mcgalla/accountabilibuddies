import 'package:auth_test/features/core/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Actually logs out the user
    if (context.mounted) {
      context.go('/'); // Redirects to AuthGate
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Get the current theme mode
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Accountabilibuddies",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // For small screens, make sure the title fits
        titleSpacing: isSmallScreen ? 0 : NavigationToolbar.kMiddleSpacing,
        // Add theme toggle button to the app bar
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip:
                isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
          ),
        ],
      ),
      drawer: Drawer(
        // Make drawer take appropriate width based on screen size
        width: isSmallScreen ? screenWidth * 0.85 : 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // User avatar or app logo
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 32,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // User email or display name if available
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'Guest User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Increase touch target size for mobile
            _buildDrawerItem(
              context,
              Icons.home,
              'Home',
              '/home',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.flag_outlined,
              'My Goals',
              '/goals',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.group,
              'Party',
              '/party',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.chat_bubble_outline,
              'Chat',
              '/chat',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.person,
              'User Info',
              '/user-info',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.warning,
              'Time Machine',
              '/time-machine',
              isSmallScreen,
            ),

            // Theme toggle in drawer
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              title: Text(
                isDarkMode ? 'Light Theme' : 'Dark Theme',
              ),
              onTap: () {
                themeProvider.toggleTheme();
                // Optionally close the drawer
                Navigator.pop(context);
              },
            ),

            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text(
                'Sign Out',
              ),
              onTap: () => _signOut(context),
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

  // Helper method to build consistent drawer items
  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    bool isSmallScreen,
  ) {
    final isCurrentRoute = GoRouterState.of(context).matchedLocation == route;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
          horizontal: 16.0, vertical: isSmallScreen ? 4.0 : 0.0),
      leading: Icon(
        icon,
        color: isCurrentRoute ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrentRoute ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isCurrentRoute
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      onTap: () => context.go(route),
      // Show subtle indicator when route is active
      shape: isCurrentRoute
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            )
          : null,
    );
  }
}
