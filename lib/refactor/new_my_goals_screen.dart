import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'new_goal_card.dart';
import 'goals_provider.dart';
import 'goal_model.dart';
import 'add_goal_dialog.dart';
import 'edit_goal_dialog.dart';
import 'total_progress_tracker.dart';
import 'weekly_progress_tracker.dart';
import 'weekly_goal.dart';
import 'total_goal.dart';

class MyGoalsScreen extends StatefulWidget {
  const MyGoalsScreen({super.key});

  @override
  MyGoalsScreenState createState() => MyGoalsScreenState();
}

class MyGoalsScreenState extends State<MyGoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // No need to fetch goals manually, Firestore listener will handle it
    });
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddGoalDialog();
      },
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) {
        return EditGoalDialog(goal: goal);
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
      body: Consumer<GoalsProvider>(
        builder: (context, goalsProvider, child) {
          if (goalsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: goalsProvider.goals.length,
            itemBuilder: (context, index) {
              final goal = goalsProvider.goals[index];
              return Column(
                children: [
                  GoalCard(
                    goalId: goal.id,
                    goalName: goal.goalName,
                    goalFrequency: goal.goalFrequency,
                    goalCriteria: goal.goalCriteria,
                    goalType: goal.goalType,
                    onDelete: () async {
                      await goalsProvider.removeGoal(context, goal.id);
                    },
                    onEdit: () => _showEditGoalDialog(context, goal),
                  ),
                  if (goal is TotalGoal)
                    Column(
                      children: [
                        TotalProgressTracker(
                          completions: goal.completions,
                          totalCompletions: goal.goalFrequency,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await goalsProvider.incrementCompletions(goal.id);
                          },
                          child: Text('Increment Completion'),
                        ),
                      ],
                    ),
                  if (goal is WeeklyGoal)
                    WeeklyProgressTracker(
                      goalId: goal.id,
                      completions: goal.completions,
                    ),
                ],
              );
            },
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
