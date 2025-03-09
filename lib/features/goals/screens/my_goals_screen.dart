import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/goal_card.dart';
import '../providers/goals_provider.dart';
import '../models/goal_model.dart';
import 'add_goal_dialog.dart';
import 'edit_goal_dialog.dart';
import '../../common/utils/utils.dart';
import '../../party/providers/party_provider.dart';

class MyGoalsScreen extends StatefulWidget {
  const MyGoalsScreen({Key? key}) : super(key: key);

  @override
  _MyGoalsScreenState createState() => _MyGoalsScreenState();
}

class _MyGoalsScreenState extends State<MyGoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Force refresh goals when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGoals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshGoals() async {
    if (!mounted) return;

    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    // Don't await this since it returns void
    goalsProvider.initializeGoalsListener();

    // Force UI update
    setState(() {
      // This will trigger a rebuild with the latest data
    });
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddGoalDialog(),
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) => EditGoalDialog(goal: goal),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String goalName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text('Are you sure you want to delete "$goalName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmArchive(BuildContext context, Goal goal) async {
    final bool isActive = goal.active;
    final String action = isActive ? 'archive' : 'restore';
    final String effect = isActive
        ? 'will not be included in the next weekly challenge'
        : 'will be included in future challenges';

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${isActive ? 'Archive' : 'Restore'} Goal'),
            content: Text(
                'Are you sure you want to $action "${goal.goalName}"? This means it $effect.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isActive ? Colors.orange : Colors.green,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(isActive ? 'Archive' : 'Restore'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Goals"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Total Goals"),
            Tab(text: "Weekly Goals"),
          ],
        ),
        actions: [
          // Existing buttons
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Force Refresh',
            onPressed: () {
              // Force a manual refresh
              final goalsProvider =
                  Provider.of<GoalsProvider>(context, listen: false);
              goalsProvider.initializeGoalsListener();

              // Force UI update
              setState(() {});

              // Show feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing goals...')),
              );
            },
          ),
          // Other existing buttons
        ],
      ),
      body: FutureBuilder(
        // This future ensures we wait for data to be fully loaded
        future: _ensureDataLoaded(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Consumer<GoalsProvider>(
            builder: (context, goalsProvider, child) {
              if (goalsProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Separate goals by type
              final totalGoals = goalsProvider.displayGoals
                  .where((goal) => goal.goalType == 'total')
                  .toList();

              final weeklyGoals = goalsProvider.displayGoals
                  .where((goal) => goal.goalType == 'weekly')
                  .toList();

              return RefreshIndicator(
                key: _refreshKey,
                onRefresh: _refreshGoals,
                child: Column(
                  children: [
                    // Party challenge banner (if applicable)
                    if (_shouldShowChallengeBanner()) _buildChallengeBanner(),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGoalsList(context, totalGoals, goalsProvider),
                          _buildGoalsList(context, weeklyGoals, goalsProvider),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

// Add this method to ensure data is loaded before displaying
  Future<bool> _ensureDataLoaded() async {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    // Force goals to be loaded completely
    goalsProvider.initializeGoalsListener();

    // Add a small delay to ensure Firestore has time to respond
    await Future.delayed(Duration(milliseconds: 500));

    return true;
  }

// Helper method to check if challenge banner should be shown
  bool _shouldShowChallengeBanner() {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);
    return partyProvider.hasPendingChallenge &&
        !partyProvider.isCurrentUserLockedIn;
  }

// Banner for challenges
  Widget _buildChallengeBanner() {
    return Container(
      color: Colors.amber.shade100,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Challenge preparation in progress. Review your goals and lock them in when ready.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(
      BuildContext context, List<Goal> goals, GoalsProvider goalsProvider) {
    if (goals.isEmpty) {
      return Center(/* ... */);
    }

    // Get party provider to check challenge status
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);
    final bool hasActiveChallenge = partyProvider.hasActiveChallenge;

    print(
        'Building goals list with hasActiveChallenge: $hasActiveChallenge'); // Debug log

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return GoalCard(
          goal: goal,
          onEdit: () => _showEditGoalDialog(context, goal),
          onDelete: () async {/* ... */},
          onArchive: () async {/* ... */},
          showProgressTracker:
              hasActiveChallenge, // Explicitly pass challenge status
        );
      },
    );
  }

// In lib/features/goals/screens/my_goals_screen.dart
// Replace the entire _lockInGoals method with this corrected version:

  void _lockInGoals(BuildContext context, GoalsProvider goalsProvider,
      PartyProvider partyProvider) async {
    // Check for active template goals
    final activeGoals =
        goalsProvider.goalTemplates.where((goal) => goal.active).toList();

    if (activeGoals.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Goals to Lock In'),
          content: const Text("You don't have any active goals to lock in."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation dialog for challenge
    final bool shouldLockIn = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lock In Goals'),
            content: partyProvider.hasPendingChallenge
                ? const Text(
                    'This will lock in your goals for the upcoming challenge. Continue?')
                : const Text('Are you sure you want to lock in these goals?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lock In'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLockIn) return;

    // Show loading indicator
    Utils.showFeedback(context, 'Locking in goals...');

    try {
      // If there's a pending challenge, use the challenge-specific method
      if (partyProvider.hasPendingChallenge && partyProvider.partyId != null) {
        await goalsProvider.lockInGoalsForChallenge(partyProvider.partyId!);
      } else {
        await goalsProvider.lockInActiveGoals();
      }

      // Display success dialog
      if (mounted) {
        Utils.showFeedback(context, 'Goals locked in successfully');
        final goalNames = activeGoals.map((goal) => goal.goalName).join('\n• ');

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Goals Locked In'),
            content: Text("These goals are now locked in:\n\n• $goalNames"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Utils.showFeedback(context, 'Error locking in goals: $e',
            isError: true);
      }
    }
  }
}
