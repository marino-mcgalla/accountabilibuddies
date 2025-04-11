import 'package:flutter/material.dart';

class TotalProgressTracker extends StatelessWidget {
  final Map<String, dynamic> currentWeekCompletions;
  final int totalCompletions;

  const TotalProgressTracker({
    required this.currentWeekCompletions,
    required this.totalCompletions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int completions = currentWeekCompletions.values
        .fold(0, (sum, value) => sum + (value as int));
    double progress = totalCompletions > 0 ? completions / totalCompletions : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress: $completions / $totalCompletions'),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
