import 'package:auth_test/features/challenge/screens/simple_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import '../../core/routing/app_scaffold.dart';
import '../services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check if snapshot data is changing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Create a builder to safely access providers after the widget tree is built
          return _AuthenticatedFlow(user: snapshot.data!);
        }
        // User is not logged in
        else {
          // Handle logout
          return _UnauthenticatedFlow();
        }
      },
    );
  }
}

// Separate widget for authenticated state to avoid rebuild issues
class _AuthenticatedFlow extends StatefulWidget {
  final User user;

  const _AuthenticatedFlow({required this.user});

  @override
  State<_AuthenticatedFlow> createState() => _AuthenticatedFlowState();
}

class _AuthenticatedFlowState extends State<_AuthenticatedFlow> {
  final AuthService _authService = AuthService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // Create Firestore user if new
    await _authService.createUserInFirestore(widget.user);

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // New providers automatically initialize streams in constructor

    return const AppScaffold(child: SimpleDashboard());
  }
}

// Separate widget for unauthenticated state
class _UnauthenticatedFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // New providers automatically handle state cleanup via streams

    return Scaffold(
      body: SignInScreen(
        providers: [
          EmailAuthProvider(),
        ],
      ),
    );
  }
}
