import 'package:flutter/material.dart';

class TotalProgressTracker extends StatelessWidget {
  final Map<String, dynamic> currentWeekCompletions;
  final int totalCompletions;
  final List<Map<String, dynamic>> proofs;

  const TotalProgressTracker({
    required this.currentWeekCompletions,
    required this.totalCompletions,
    required this.proofs,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('progress tracker boop');
    int approvedCompletions = currentWeekCompletions.values
        .where((value) => value == 'completed')
        .length;
    int pendingCompletions = proofs.length;
    // print('proofs length: ${proofs.length}');
    double approvedProgress =
        totalCompletions > 0 ? approvedCompletions / totalCompletions : 0;
    double pendingProgress = totalCompletions > 0
        ? (approvedCompletions + pendingCompletions) / totalCompletions
        : 0;
    // print('approvedProgress: $approvedProgress');
    // print('pendingProgress: $pendingProgress');
    // print('approvedCompletions: $approvedCompletions');
    // print('pendingCompletions: $pendingCompletions');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress: $approvedCompletions / $totalCompletions'),
        Stack(
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
        ),
      ],
    );
  }
}
