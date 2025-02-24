import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import DateFormat
import 'goals_provider.dart';
import 'time_machine_provider.dart';

class WeeklyProgressTracker extends StatelessWidget {
  final String goalId;
  final Map<String, String> completions;

  const WeeklyProgressTracker({
    required this.goalId,
    required this.completions,
    Key? key,
  }) : super(key: key);

  void _toggleCompletion(BuildContext context, String day) {
    final currentStatus = completions[day] ?? 'default';
    String newStatus;
    switch (currentStatus) {
      case 'default':
        newStatus = 'submitted';
        break;
      case 'submitted':
        newStatus = 'completed';
        break;
      case 'completed':
        newStatus = 'skipped';
        break;
      case 'skipped':
        newStatus = 'planned';
        break;
      case 'planned':
      default:
        newStatus = 'default';
        break;
    }
    Provider.of<GoalsProvider>(context, listen: false)
        .toggleCompletion(goalId, day, newStatus);
  }

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: daysOfWeek.map((day) {
        final status = completions[day] ?? 'default';
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
          case 'blank':
          default:
            color = Colors.grey;
            break;
        }
        final dayOfWeek = DateFormat('EEE').format(
            DateTime.parse(day)); // Format as day of the week abbreviation
        return GestureDetector(
          onTap: () => _toggleCompletion(context, day),
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              dayOfWeek,
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }).toList(),
    );
  }
}
