import 'package:flutter/material.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'package:provider/provider.dart';
import 'time_machine_provider.dart';

class CompactProgressTracker extends StatelessWidget {
  final Goal goal;

  const CompactProgressTracker({
    required this.goal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeMachineProvider =
        Provider.of<TimeMachineProvider>(context, listen: false);
    final now = timeMachineProvider.now;
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Start from Monday
    final daysOfWeek = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return date.toIso8601String().split('T').first;
    });

    // Create a unique key based on the goal ID and current completions state
    // This ensures the widget rebuilds when completions change
    final keyString = '${goal.id}-${goal.currentWeekCompletions.hashCode}';
    final valueKey = ValueKey(keyString);

    if (goal is TotalGoal) {
      final totalGoal = goal as TotalGoal;
      int approvedCompletions = totalGoal.currentWeekCompletions.values
          .fold(0, (sum, value) => sum + value as int);
      int pendingCompletions = totalGoal.proofs.length;
      double approvedProgress = totalGoal.goalFrequency > 0
          ? approvedCompletions / totalGoal.goalFrequency
          : 0;
      double pendingProgress = totalGoal.goalFrequency > 0
          ? (approvedCompletions + pendingCompletions) / totalGoal.goalFrequency
          : 0;

      return Container(
        key: valueKey,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.goalName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Stack(
              children: [
                LinearProgressIndicator(
                  value: pendingProgress > 1.0 ? 1.0 : pendingProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
                LinearProgressIndicator(
                  value: approvedProgress > 1.0 ? 1.0 : approvedProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
            Text(
              'Progress: $approvedCompletions / ${totalGoal.goalFrequency}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    } else if (goal is WeeklyGoal) {
      final weeklyGoal = goal as WeeklyGoal;

      return Container(
        key: valueKey,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.goalName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: daysOfWeek.map((day) {
                final status =
                    weeklyGoal.currentWeekCompletions[day] ?? 'default';
                Color color;
                switch (status) {
                  case 'submitted':
                    color = Colors.yellow;
                    break;
                  case 'completed':
                    color = Colors.green;
                    break;
                  case 'skipped':
                    color = Colors.red;
                    break;
                  case 'planned':
                    color = Colors.blue;
                    break;
                  case 'default':
                  default:
                    color = Colors.grey[300]!;
                    break;
                }

                // Get day abbreviation
                final dayOfWeek = DateTime.parse(day).weekday;
                final dayAbbr =
                    ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][dayOfWeek];

                return Expanded(
                  child: Container(
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 1.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayAbbr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Text(
              'Target: ${weeklyGoal.goalFrequency} days/week',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    } else {
      return Container(key: valueKey);
    }
  }
}
