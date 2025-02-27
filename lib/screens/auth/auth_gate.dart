import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../screens/home/home_screen.dart';
import '../../services/auth_service.dart';
import '../../refactor/goals_provider.dart';
import '../../refactor/party_provider.dart';

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

    // Initialize providers once when the user logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final goalsProvider =
            Provider.of<GoalsProvider>(context, listen: false);
        final partyProvider =
            Provider.of<PartyProvider>(context, listen: false);

        goalsProvider.initializeGoalsListener();
        partyProvider.initializePartyState();
      } catch (e) {
        print('Error initializing providers: $e');
      }
    });

    return const AppScaffold(child: HomeScreen());
  }
}

// Separate widget for unauthenticated state
class _UnauthenticatedFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Reset state of providers when user logs out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<GoalsProvider>(context, listen: false).resetState();
        Provider.of<PartyProvider>(context, listen: false).resetState();
      } catch (e) {
        print('Error resetting providers: $e');
      }
    });

    return Scaffold(
      body: SignInScreen(
        providers: [
          EmailAuthProvider(),
        ],
      ),
    );
  }
}
