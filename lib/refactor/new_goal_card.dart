import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'total_progress_tracker.dart';
import 'weekly_progress_tracker.dart';
import 'goals_provider.dart';

class GoalCard extends StatelessWidget {
  final String goalId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;
  final String goalType;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const GoalCard({
    required this.goalId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    required this.goalType,
    required this.onDelete,
    required this.onEdit,
    Key? key,
  }) : super(key: key);

  Future<void> _submitProof(BuildContext context, String goalId) async {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
    String proofText = "I did it"; // For now, use a static text
    await goalsProvider.submitProof(goalId, proofText);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goal: $goalName'),
          Text('Type: $goalType'),
          Text('Frequency: $goalFrequency'),
          Text('Criteria: $goalCriteria'),
          if (goalType == 'total')
            Selector<GoalsProvider, TotalGoal>(
              selector: (context, goalsProvider) => goalsProvider.goals
                  .firstWhere((g) => g.id == goalId) as TotalGoal,
              builder: (context, goal, child) {
                return Column(
                  children: [
                    TotalProgressTracker(
                      currentWeekCompletions:
                          goal.currentWeekCompletions.cast<String, int>(),
                      totalCompletions: goal.goalFrequency,
                      proofs: goal.proofs, // Pass the proofs list
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await Provider.of<GoalsProvider>(context, listen: false)
                            .incrementCompletions(goal.id);
                      },
                      child: Text('Increment Completion'),
                    ),
                  ],
                );
              },
            ),
          if (goalType == 'weekly')
            Selector<GoalsProvider, WeeklyGoal>(
              selector: (context, goalsProvider) => goalsProvider.goals
                  .firstWhere((g) => g.id == goalId) as WeeklyGoal,
              builder: (context, goal, child) {
                return WeeklyProgressTracker(
                  goalId: goal.id,
                  completions:
                      goal.currentWeekCompletions.cast<String, String>(),
                );
              },
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  _submitProof(context, goalId);
                },
                child: Text('Submit Proof'),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
