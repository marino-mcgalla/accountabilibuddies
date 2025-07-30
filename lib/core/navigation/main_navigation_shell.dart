import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../shared/widgets/global_notification_bar.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.goals);
        break;
      case 2:
        context.go(AppRoutes.party);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Goals';
      case 2:
        // For party pages, let the page handle its own title in the custom header
        return '';
      case 3:
        return 'Profile';
      default:
        return 'AccountabiliBuddies';
    }
  }

  List<Widget> _getAppBarActions(BuildContext context) {
    final actions = <Widget>[
      // Global notification icon for all screens
      const GlobalNotificationIcon(),
    ];

    // Add screen-specific actions
    switch (_currentIndex) {
      case 0: // Dashboard
        actions.add(
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        );
        break;
      case 1: // Goals
        // No specific actions for goals page
        break;
      case 2: // Party
        // Party notifications are already handled by GlobalNotificationIcon
        break;
      case 3: // Profile
        // No specific actions for profile page
        break;
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // For party pages (index 2), don't show AppBar as they handle their own headers
    final showAppBar = _currentIndex != 2;
    
    return Scaffold(
      appBar: showAppBar ? AppBar(
        title: Text(_getAppBarTitle()),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: _getAppBarActions(context),
      ) : null,
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Party',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Custom navigation bar for more advanced features
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
            ),
            _buildNavItem(
              context,
              icon: Icons.flag_outlined,
              activeIcon: Icons.flag,
              label: 'Goals',
              index: 1,
            ),
            _buildNavItem(
              context,
              icon: Icons.group_outlined,
              activeIcon: Icons.group,
              label: 'Party',
              index: 2,
            ),
            _buildNavItem(
              context,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Navigation state management
class NavigationState {
  final int currentIndex;
  final List<String> navigationStack;
  
  const NavigationState({
    required this.currentIndex,
    required this.navigationStack,
  });
  
  NavigationState copyWith({
    int? currentIndex,
    List<String>? navigationStack,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      navigationStack: navigationStack ?? this.navigationStack,
    );
  }
}

// Navigation controller for more complex navigation logic
class NavigationController extends ChangeNotifier {
  NavigationState _state = const NavigationState(
    currentIndex: 0,
    navigationStack: [AppRoutes.dashboard],
  );
  
  NavigationState get state => _state;
  
  void navigateToTab(int index) {
    if (index != _state.currentIndex) {
      _state = _state.copyWith(currentIndex: index);
      notifyListeners();
    }
  }
  
  void pushRoute(String route) {
    final newStack = [..._state.navigationStack, route];
    _state = _state.copyWith(navigationStack: newStack);
    notifyListeners();
  }
  
  void popRoute() {
    if (_state.navigationStack.length > 1) {
      final newStack = _state.navigationStack.sublist(0, _state.navigationStack.length - 1);
      _state = _state.copyWith(navigationStack: newStack);
      notifyListeners();
    }
  }
  
  void resetToTab(int index) {
    String initialRoute;
    switch (index) {
      case 0:
        initialRoute = AppRoutes.dashboard;
        break;
      case 1:
        initialRoute = AppRoutes.goals;
        break;
      case 2:
        initialRoute = AppRoutes.party;
        break;
      case 3:
        initialRoute = AppRoutes.profile;
        break;
      default:
        initialRoute = AppRoutes.dashboard;
    }
    
    _state = NavigationState(
      currentIndex: index,
      navigationStack: [initialRoute],
    );
    notifyListeners();
  }
}