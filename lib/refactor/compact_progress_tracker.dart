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
    final timeMachineProvider = Provider.of<TimeMachineProvider>(context);
    final now = timeMachineProvider.now;
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Start from Monday
    final daysOfWeek = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return date.toIso8601String().split('T').first;
    });

    if (goal is TotalGoal) {
      final totalGoal = goal as TotalGoal;
      int approvedCompletions = totalGoal.currentWeekCompletions.values
          .where((value) => value == 'completed')
          .length;
      int pendingCompletions = totalGoal.proofs.length;
      double approvedProgress = totalGoal.goalFrequency > 0
          ? approvedCompletions / totalGoal.goalFrequency
          : 0;
      double pendingProgress = totalGoal.goalFrequency > 0
          ? (approvedCompletions + pendingCompletions) / totalGoal.goalFrequency
          : 0;

      return Stack(
        children: [
          LinearProgressIndicator(
            value: pendingProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
          LinearProgressIndicator(
            value: approvedProgress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      );
    } else if (goal is WeeklyGoal) {
      final weeklyGoal = goal as WeeklyGoal;

      return Row(
        children: daysOfWeek.map((day) {
          final status = weeklyGoal.currentWeekCompletions[day] ?? 'default';
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
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              height: 10,
              color: color,
            ),
          );
        }).toList(),
      );
    } else {
      return Container();
    }
  }
}
