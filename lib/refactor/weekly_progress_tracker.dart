import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goals_provider.dart';

class WeeklyProgressTracker extends StatelessWidget {
  final String goalId;
  final Map<String, bool> completions;

  const WeeklyProgressTracker({
    required this.goalId,
    required this.completions,
    Key? key,
  }) : super(key: key);

  void _toggleCompletion(BuildContext context, String day) {
    final currentStatus = completions[day] ?? false;
    bool newStatus = !currentStatus;
    Provider.of<GoalsProvider>(context, listen: false)
        .toggleCompletion(goalId, day, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: daysOfWeek.map((day) {
        final status = completions[day] ?? false;
        Color color = status ? Colors.green : Colors.grey;
        return GestureDetector(
          onTap: () => _toggleCompletion(context, day),
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              day,
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }).toList(),
    );
  }
}
