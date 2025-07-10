import 'package:auth_test/features/core/themes/theme_provider.dart';
import 'package:auth_test/features/notifications/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _showResetUserDataDialog(BuildContext context) async {
    Navigator.pop(context); // Close the drawer first
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset User Data'),
          content: const Text(
            'This will permanently delete all your data including:\n\n'
            '• All goals and goal templates\n'
            '• All parties and memberships\n'
            '• All progress and proofs\n'
            '• Profile settings\n\n'
            'This action cannot be undone. Are you sure you want to continue?'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reset Everything'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetUserData(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetUserData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final userId = user.uid;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Resetting user data...'),
            ],
          ),
        );
      },
    );

    try {
      // 1. Delete userGoals document (contains all user's goals)
      await firestore.collection('userGoals').doc(userId).delete();
      
      // 2. Delete userGoalsHistory collection (all historical data)
      final historyQuery = await firestore
          .collection('userGoalsHistory')
          .doc(userId)
          .collection('weeks')
          .get();
      
      for (final doc in historyQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete the userGoalsHistory document itself
      await firestore.collection('userGoalsHistory').doc(userId).delete();
      
      // 3. Delete user's goal templates subcollection
      final templatesQuery = await firestore
          .collection('users')
          .doc(userId)
          .collection('goalTemplates')
          .get();
      
      for (final doc in templatesQuery.docs) {
        await doc.reference.delete();
      }

      // 4. Get current user data to see what parties they're in (both old and new systems)
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final parties = userData['parties'] as Map<String, dynamic>? ?? {};
        
        // Remove user from all OLD parties they're a member of
        for (final partyId in parties.keys) {
          final partyDoc = firestore.collection('parties').doc(partyId);
          await partyDoc.update({
            'members': FieldValue.arrayRemove([userId])
          });
          
          // Delete proof events related to this user in this party
          final proofEventsQuery = await firestore
              .collection('parties')
              .doc(partyId)
              .collection('proofEvents')
              .where('userId', isEqualTo: userId)
              .get();
          
          for (final doc in proofEventsQuery.docs) {
            await doc.reference.delete();
          }
        }
      }

      // 4b. Remove user from all NEW simple parties they're a member of
      final simplePartiesQuery = await firestore
          .collection('parties')
          .where('members', arrayContains: userId)
          .get();
      
      for (final doc in simplePartiesQuery.docs) {
        await doc.reference.update({
          'members': FieldValue.arrayRemove([userId]),
          'memberCount': FieldValue.increment(-1),
        });
      }

      // 5. Delete parties where user is the leader
      final partiesQuery = await firestore
          .collection('parties')
          .where('partyOwner', isEqualTo: userId)
          .get();
      
      for (final doc in partiesQuery.docs) {
        // Delete all subcollections first
        final challengeHistoryQuery = await doc.reference
            .collection('challengeHistory')
            .get();
        for (final challengeDoc in challengeHistoryQuery.docs) {
          await challengeDoc.reference.delete();
        }
        
        final proofEventsQuery = await doc.reference
            .collection('proofEvents')
            .get();
        for (final proofEventDoc in proofEventsQuery.docs) {
          await proofEventDoc.reference.delete();
        }
        
        // Delete the party document
        await doc.reference.delete();
      }

      // 6. Delete invitations sent by or to the user
      final sentInvitesQuery = await firestore
          .collection('invites')
          .where('inviterId', isEqualTo: userId)
          .get();
      
      for (final doc in sentInvitesQuery.docs) {
        await doc.reference.delete();
      }
      
      final receivedInvitesQuery = await firestore
          .collection('invites')
          .where('inviteeId', isEqualTo: userId)
          .get();
      
      for (final doc in receivedInvitesQuery.docs) {
        await doc.reference.delete();
      }

      // 7. Delete any legacy goals collection entries
      final legacyGoalsQuery = await firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in legacyGoalsQuery.docs) {
        await doc.reference.delete();
      }

      // 8. Reset user document to fresh state
      await firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': user.email,
        'displayName': user.displayName,
        'username': null,
        'counter': 0,
        'parties': {},
        'activePartyCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'partyId': null,
        'preferences': {
          'notifications': true,
          'timezone': 'America/New_York',
        },
      });

      // Close loading dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data has been reset successfully! App will refresh.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to home to refresh the app state
        context.go('/home');
      }
    } catch (e) {
      // Close loading dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting user data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
          Consumer<NotificationsProvider>(
            builder: (context, notificationsProvider, child) {
              final unreadCount = notificationsProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: 'Notifications',
                    onPressed: () {
                      // For now, just mark all as read
                      notificationsProvider.markAllAsRead();
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
              Icons.library_books,
              'Goal Templates',
              '/goal-templates',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.groups,
              'My Parties',
              '/simple-parties',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.group_add,
              'Join Party',
              '/join-party',
              isSmallScreen,
            ),
            _buildDrawerItem(
              context,
              Icons.person,
              'Profile',
              '/user-info',
              isSmallScreen,
            ),
            // _buildDrawerItem(
            //   context,
            //   Icons.warning,
            //   'Time Machine',
            //   '/time-machine',
            //   isSmallScreen,
            // ),

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
                Icons.refresh,
                color: Colors.orange,
              ),
              title: const Text(
                'Reset User Data',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () => _showResetUserDataDialog(context),
            ),
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
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
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
