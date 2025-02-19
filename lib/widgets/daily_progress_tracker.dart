import 'package:flutter/material.dart';
import '../models/progress_tracker_model.dart';

class DailyProgressGrid extends StatelessWidget {
  final ProgressTrackerModel progressTracker;

  const DailyProgressGrid({required this.progressTracker, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7 days in a week
      ),
      itemCount: progressTracker.days?.length ?? 0,
      itemBuilder: (context, index) {
        DayProgress dayProgress = progressTracker.days![index];
        return GestureDetector(
          onTap: () {
            // Handle day status change (e.g., mark as completed)
          },
          child: Container(
            margin: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: dayProgress.status == 'completed'
                  ? Colors.green
                  : Colors.grey,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                dayProgress.date.day.toString(),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
