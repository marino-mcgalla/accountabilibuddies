import 'package:flutter/material.dart';

class TotalProgressTracker extends StatelessWidget {
  final int completions;
  final int totalCompletions;

  const TotalProgressTracker({
    required this.completions,
    required this.totalCompletions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
