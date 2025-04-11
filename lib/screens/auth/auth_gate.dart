import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../screens/home/home_screen.dart';
import '../../services/auth_service.dart'; // Import AuthService
import '../../refactor/goals_provider.dart';
import '../../refactor/party_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // Create an instance of AuthService

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Create Firestore user if new
          authService.createUserInFirestore(snapshot.data!);

          // Initialize providers when user logs in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<GoalsProvider>(context, listen: false)
                .initializeGoalsListener();
            Provider.of<PartyProvider>(context, listen: false)
                .initializePartyState();
          });

          return const AppScaffold(child: HomeScreen());
        } else {
          // Reset state of providers when user logs out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<GoalsProvider>(context, listen: false).resetState();
            Provider.of<PartyProvider>(context, listen: false).resetState();
          });

          return Scaffold(
            body: SignInScreen(
              providers: [
                EmailAuthProvider(),
              ],
            ),
          );
        }
      },
    );
  }
}
