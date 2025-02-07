import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_scaffold.dart';
import '../../screens/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: SignInScreen(
              providers: [
                EmailAuthProvider(),
              ],
            ),
          );
        }

        // ✅ Wrap HomeScreen inside AppScaffold to fix the missing navigation drawer
        return const AppScaffold(child: HomeScreen());
      },
    );
  }
}
