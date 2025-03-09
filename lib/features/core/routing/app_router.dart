import 'package:auth_test/features/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../../auth/screens/auth_gate.dart';
import '../../../screens/home/home_screen.dart';
import '../../party/screens/party_screen.dart';
import '../../../screens/user/user_info_screen.dart';
import '../../goals/screens/my_goals_screen.dart';
import '../../time_machine/screens/time_machine.dart';
import 'app_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/', // ✅ Start at AuthGate instead of /home
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const AuthGate(), // ✅ Ensure AuthGate loads first
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => Scaffold(
        body: SignInScreen(
          providers: [
            EmailAuthProvider(),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const AppScaffold(child: HomeScreen()),
    ),
    GoRoute(
      path: '/party',
      builder: (context, state) => const AppScaffold(child: PartyScreen()),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const AppScaffold(child: ChatScreen()),
    ),
    GoRoute(
      path: '/user-info',
      builder: (context, state) => const AppScaffold(child: UserInfoScreen()),
    ),
    GoRoute(
      path: '/goals',
      builder: (context, state) => const AppScaffold(child: MyGoalsScreen()),
    ),
    GoRoute(
      path: '/time-machine',
      builder: (context, state) =>
          const AppScaffold(child: TimeMachineScreen()),
    ),
    // GoRoute(
    //   path: '/sandbox',
    //   builder: (context, state) =>
    //       AppScaffold(child: SandboxScreen()), // Add the SandboxScreen route
    // ),
  ],
);
