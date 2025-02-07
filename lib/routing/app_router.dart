import 'package:go_router/go_router.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/home/home_screen.dart';
import '../screens/party/party_screen.dart';
import '../screens/user/user_info_screen.dart';
import '../screens/goals/my_goals_screen.dart';
import '../widgets/app_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
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
      path: '/user-info',
      builder: (context, state) => const AppScaffold(child: UserInfoScreen()),
    ),
    GoRoute(
      path: '/goals',
      builder: (context, state) => const AppScaffold(child: MyGoalsScreen()),
    ),
  ],
);
