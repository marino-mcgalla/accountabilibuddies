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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshGoals() async {
    // This will trigger the firestore listener in GoalsProvider
    Provider.of<GoalsProvider>(context, listen: false)
        .initializeGoalsListener();
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

    // Get the party provider to check for pending challenge
    //TODO: does this have to be here??
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);
    final bool isPendingChallenge = partyProvider.hasPendingChallenge;
    final bool isUserLockedIn = partyProvider.isCurrentUserLockedIn;

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
          Consumer<GoalsProvider>(
            //TODO: don't really need this here, the one in the party screen is good enough
            builder: (context, goalsProvider, _) {
              // Check if there are any active goals
              final hasActiveGoals =
                  goalsProvider.goals.any((goal) => goal.active);

              // Show Lock In button (with pending challenge indicator if applicable)
              return TextButton.icon(
                icon: Icon(
                  isPendingChallenge
                      ? (isUserLockedIn ? Icons.lock : Icons.lock_outline)
                      : Icons.lock_outline,
                  // Fix deprecated withOpacity
                  color: hasActiveGoals
                      ? Colors.white
                      : Color.fromARGB(128, 255, 255, 255),
                ),
                label: Text(
                  isPendingChallenge
                      ? (isUserLockedIn ? 'Locked In' : 'Lock In')
                      : 'Lock In',
                  style: TextStyle(
                    color: hasActiveGoals
                        ? Colors.white
                        : Color.fromARGB(128, 255, 255, 255),
                  ),
                ),
                // Button is only enabled if there are active goals and not already locked in
                onPressed: hasActiveGoals && (!isUserLockedIn)
                    ? () => _lockInGoals(context, goalsProvider, partyProvider)
                    : null,
              );
            },
          ),
          // Existing Add button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context),
            tooltip: 'Add Goal',
          ),
        ],
      ),
      body: Consumer<GoalsProvider>(
        builder: (context, goalsProvider, child) {
          if (goalsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Separate goals by type
          final totalGoals = goalsProvider.goals
              .where((goal) => goal.goalType == 'total')
              .toList();

          final weeklyGoals = goalsProvider.goals
              .where((goal) => goal.goalType == 'weekly')
              .toList();

          return RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refreshGoals,
            child: Column(
              children: [
                // Show pending challenge banner if applicable
                if (isPendingChallenge && !isUserLockedIn)
                  Container(
                    color: Colors.amber.shade100,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active,
                            color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Challenge preparation in progress. Review your goals and lock them in when ready.',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildGoalsList(
      BuildContext context, List<Goal> goals, GoalsProvider goalsProvider) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied,
                size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No goals found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add a Goal'),
              onPressed: () => _showAddGoalDialog(context),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return GoalCard(
          goal: goal,
          onEdit: () => _showEditGoalDialog(context, goal),
          onDelete: () async {
            final confirm = await _confirmDelete(context, goal.goalName);
            if (confirm && mounted) {
              try {
                final BuildContext currentContext = context;
                Utils.showFeedback(currentContext, 'Deleting goal...');
                await goalsProvider.removeGoal(context, goal.id);
                if (mounted) {
                  Utils.showFeedback(currentContext, 'Goal deleted');
                }
              } catch (e) {
                if (mounted) {
                  Utils.showFeedback(context, 'Error deleting goal: $e',
                      isError: true);
                }
              }
            }
          },
          onArchive: () async {
            final confirm = await _confirmArchive(context, goal);
            if (confirm && mounted) {
              final currentContext = context;
              final String action = goal.active ? 'Archiving' : 'Restoring';
              Utils.showFeedback(currentContext, '$action goal...');
              await goalsProvider.toggleGoalActive(goal.id);
              if (mounted) {
                final String result = goal.active ? 'archived' : 'restored';
                Utils.showFeedback(currentContext, 'Goal $result');
              }
            }
          },
        );
      },
    );
  }

  // Updated lock in method that connects with party challenge system
  void _lockInGoals(BuildContext context, GoalsProvider goalsProvider,
      PartyProvider partyProvider) async {
    final activeGoals =
        goalsProvider.goals.where((goal) => goal.active).toList();

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
