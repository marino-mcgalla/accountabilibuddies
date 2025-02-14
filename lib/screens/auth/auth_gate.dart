import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../screens/home/home_screen.dart';
import '../../services/auth_service.dart'; // Import AuthService

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
          return const AppScaffold(child: HomeScreen());
        }

        return Scaffold(
          body: SignInScreen(
            providers: [
              EmailAuthProvider(),
            ],
          ),
        );
      },
    );
  }
}
