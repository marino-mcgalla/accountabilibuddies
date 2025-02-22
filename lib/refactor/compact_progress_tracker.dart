import 'package:flutter/material.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';

class CompactProgressTracker extends StatelessWidget {
  final Goal goal;

  const CompactProgressTracker({
    required this.goal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (goal is TotalGoal) {
      final totalGoal = goal as TotalGoal;
      int completions = totalGoal.currentWeekCompletions.values
          .fold(0, (sum, value) => sum + (value as int));
      double progress = totalGoal.goalFrequency > 0
          ? completions / totalGoal.goalFrequency
          : 0;
      return LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
        color: Colors.blue,
      );
    } else if (goal is WeeklyGoal) {
      final weeklyGoal = goal as WeeklyGoal;
      final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
