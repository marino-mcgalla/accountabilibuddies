import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import 'main_navigation_shell.dart';
import 'placeholder_screens.dart' hide LoginScreen, RegisterScreen, ForgotPasswordScreen;
import '../../features/goals/goals.dart';
import '../../features/auth/auth.dart';
import '../../features/parties/presentation/pages/party_detail_page.dart';
import '../../features/parties/presentation/pages/create_party_page.dart';
import '../../features/parties/presentation/pages/join_party_page.dart';
import '../../features/parties/presentation/pages/invite_to_party_page.dart';

// Provider for the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnboarded = authState.isOnboarded;
      
      final currentPath = state.fullPath ?? '';
      
      // Handle authentication redirects
      if (!isAuthenticated) {
        // Allow access to auth routes when not authenticated
        if (currentPath.startsWith('/auth') || 
            currentPath == AppRoutes.splash ||
            currentPath == AppRoutes.onboarding) {
          return null;
        }
        return AppRoutes.authLogin;
      }
      
      // Handle onboarding redirects
      if (isAuthenticated && !isOnboarded) {
        if (currentPath == AppRoutes.onboarding) {
          return null;
        }
        return AppRoutes.onboarding;
      }
      
      // Redirect authenticated users away from auth routes
      if (isAuthenticated && currentPath.startsWith('/auth')) {
        return AppRoutes.dashboard;
      }
      
      // Redirect onboarded users away from onboarding
      if (isOnboarded && currentPath == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: AppRoutes.authLogin,
        name: AppRoutes.authLoginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.authRegister,
        name: AppRoutes.authRegisterName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.authForgotPassword,
        name: AppRoutes.authForgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main Navigation Shell
      ShellRoute(
        builder: (context, state, child) => MainNavigationShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRoutes.dashboardName,
            builder: (context, state) => const DashboardScreen(),
          ),
          
          // Goals
          GoRoute(
            path: AppRoutes.goals,
            name: AppRoutes.goalsName,
            builder: (context, state) => const GoalsScreen(),
            routes: [
              // Note: Goal creation removed - users create templates instead
              GoRoute(
                path: 'edit/:goalId',
                name: AppRoutes.goalsEditName,
                builder: (context, state) => EditGoalScreen(
                  goalId: state.pathParameters['goalId']!,
                ),
              ),
              GoRoute(
                path: ':goalId/details',
                name: AppRoutes.goalsDetailsName,
                builder: (context, state) => GoalDetailsScreen(
                  goalId: state.pathParameters['goalId']!,
                ),
              ),
              GoRoute(
                path: ':goalId/proof',
                name: AppRoutes.goalsProofName,
                builder: (context, state) => SubmitProofScreen(
                  goalId: state.pathParameters['goalId']!,
                ),
              ),
              // Template routes
              GoRoute(
                path: 'templates',
                name: 'goal_templates',
                builder: (context, state) => const GoalTemplatesPage(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'goal_templates_create',
                    builder: (context, state) => const CreateGoalTemplateScreen(),
                  ),
                  GoRoute(
                    path: ':templateId',
                    name: 'goal_template_detail',
                    builder: (context, state) => GoalTemplateDetailScreen(
                      templateId: state.pathParameters['templateId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':templateId/edit',
                    name: 'goal_template_edit',
                    builder: (context, state) => EditGoalTemplateScreen(
                      templateId: state.pathParameters['templateId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Party
          GoRoute(
            path: AppRoutes.party,
            name: AppRoutes.partyName,
            builder: (context, state) => const PartyScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: AppRoutes.partyCreateName,
                builder: (context, state) => const CreatePartyPage(),
              ),
              GoRoute(
                path: 'join',
                name: AppRoutes.partyJoinName,
                builder: (context, state) => const JoinPartyPage(),
              ),
              GoRoute(
                path: 'invite/:partyId',
                name: AppRoutes.partyInviteName,
                builder: (context, state) => InviteToPartyPage(
                  partyId: state.pathParameters['partyId']!,
                ),
              ),
              GoRoute(
                path: 'members',
                name: AppRoutes.partyMembersName,
                builder: (context, state) => const PartyMembersScreen(),
              ),
              GoRoute(
                path: 'approvals',
                name: AppRoutes.partyApprovalsName,
                builder: (context, state) => const ProofApprovalsScreen(),
              ),
              GoRoute(
                path: ':partyId',
                name: AppRoutes.partyDetailName,
                builder: (context, state) => PartyDetailPage(
                  partyId: state.pathParameters['partyId']!,
                ),
              ),
            ],
          ),
          
          // Profile
          GoRoute(
            path: AppRoutes.profile,
            name: AppRoutes.profileName,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: AppRoutes.profileEditName,
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      
      // Settings (outside of main navigation)
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            name: AppRoutes.settingsNotificationsName,
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            name: AppRoutes.settingsPrivacyName,
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'about',
            name: AppRoutes.settingsAboutName,
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

