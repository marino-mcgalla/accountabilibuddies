import 'package:flutter/material.dart';
import '../models/progress_tracker_model.dart';

class TotalProgressBar extends StatelessWidget {
  final ProgressTrackerModel progressTracker;

  const TotalProgressBar({required this.progressTracker, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = (progressTracker.totalCompletions ?? 0) /
        (progressTracker.targetCompletions ?? 1);
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey,
          color: Colors.blue,
        ),
        SizedBox(height: 8.0),
        Text('${(progress * 100).toStringAsFixed(1)}% completed'),
      ],
    );
  }
}
