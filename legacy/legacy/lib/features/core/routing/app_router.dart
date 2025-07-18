import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../../auth/screens/auth_gate.dart';
import '../../party/screens/simple_party_list_screen.dart';
import '../../party/screens/simple_join_party_screen.dart';
import '../../challenge/screens/simple_dashboard.dart';
import '../../challenge/screens/challenge_setup_screen.dart';
import '../../challenge/screens/challenge_lockin_screen.dart';
import '../../challenge/screens/create_multi_party_challenge_screen.dart';
import '../../../screens/user/user_info_screen.dart';
import '../../goals/screens/my_goals_screen.dart';
import '../../goals/screens/goal_templates_screen.dart';
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
      builder: (context, state) => const AppScaffold(child: SimpleDashboard()),
    ),
    GoRoute(
      path: '/party',
      builder: (context, state) => const AppScaffold(child: SimplePartyListScreen()),
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
      path: '/goal-templates',
      builder: (context, state) => const AppScaffold(child: GoalTemplatesScreen()),
    ),
    GoRoute(
      path: '/time-machine',
      builder: (context, state) =>
          const AppScaffold(child: TimeMachineScreen()),
    ),
    GoRoute(
      path: '/join-party',
      builder: (context, state) =>
          const AppScaffold(child: SimpleJoinPartyScreen()),
    ),
    GoRoute(
      path: '/challenge-setup',
      builder: (context, state) =>
          const AppScaffold(child: ChallengeSetupScreen()),
    ),
    GoRoute(
      path: '/challenge-lockin',
      builder: (context, state) =>
          const AppScaffold(child: ChallengeLockinScreen()),
    ),
    GoRoute(
      path: '/create-multi-party-challenge',
      builder: (context, state) =>
          const AppScaffold(child: CreateMultiPartyChallengeScreen()),
    ),
    // GoRoute(
    //   path: '/sandbox',
    //   builder: (context, state) =>
    //       AppScaffold(child: SandboxScreen()), // Add the SandboxScreen route
    // ),
  ],
);
