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
            Consumer<GoalsProvider>(
              builder: (context, goalsProvider, child) {
                final goal = goalsProvider.goals
                    .firstWhere((g) => g.id == goalId) as TotalGoal;
                int totalCompletions = goal.currentWeekCompletions.values
                    .fold(0, (sum, value) => sum + value as int);
                return Column(
                  children: [
                    TotalProgressTracker(
                      currentWeekCompletions: goal.currentWeekCompletions,
                      totalCompletions: goal.goalFrequency,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await goalsProvider.incrementCompletions(goal.id);
                      },
                      child: Text('Increment Completion'),
                    ),
                  ],
                );
              },
            ),
          if (goalType == 'weekly')
            Consumer<GoalsProvider>(
              builder: (context, goalsProvider, child) {
                final goal = goalsProvider.goals
                    .firstWhere((g) => g.id == goalId) as WeeklyGoal;
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
