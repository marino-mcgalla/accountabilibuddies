import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/goal_card.dart';
import '../providers/goals_provider.dart';
import '../models/goal_model.dart';
import 'add_goal_dialog.dart';
import 'edit_goal_dialog.dart';
import '../../common/utils/utils.dart';

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

  //TODO: THIS IS UI CODE WHY IS IT HERE UGHHHHHHHHHHH
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsList(context, totalGoals, goalsProvider),
                _buildGoalsList(context, weeklyGoals, goalsProvider),
              ],
            ),
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showAddGoalDialog(context),
      //   child: const Icon(Icons.add),
      // ),
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
                // Store a local copy of the context
                final BuildContext currentContext = context;

                // First show feedback that deletion is starting
                Utils.showFeedback(currentContext, 'Deleting goal...');

                // Then delete the goal
                await goalsProvider.removeGoal(context, goal.id);

                // Only show success feedback if still mounted
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

              // This will toggle the active state
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
}
