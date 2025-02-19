import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/new_goal_card.dart';
import '../../services/new_goals_service.dart';
import '../../models/goal_model.dart';
import '../../widgets/add_goal_dialog.dart';

class MyGoalsScreen extends StatefulWidget {
  const MyGoalsScreen({super.key});

  @override
  MyGoalsScreenState createState() => MyGoalsScreenState();
}

class MyGoalsScreenState extends State<MyGoalsScreen> {
  final GoalsService _goalsService = GoalsService();
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    List<Goal> goals = await _goalsService.getGoals();

    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddGoalDialog(
          goalsService: _goalsService,
          onGoalAdded: _loadGoals,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Goals 2.0")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return GoalCard(
                  goalId: goal.id,
                  goalName: goal.goalName,
                  goalFrequency: goal.frequency,
                  goalCriteria: goal.criteria,
                  goalType: goal.goalType,
                  onDelete: () async {
                    await _goalsService.deleteGoal(context, goal.id);
                    _loadGoals(); // Refresh the goals after deleting a goal
                  },
                  // onEdit: () => _showEditGoalDialog(context, goal),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
