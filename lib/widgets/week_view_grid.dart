import 'package:flutter/material.dart';
import 'day_checkbox.dart';

class WeekViewGrid extends StatelessWidget {
  final String goalId;
  final List<dynamic> weekStatus;
  final Function(BuildContext, String, String, String) toggleStatus;

  const WeekViewGrid({
    required this.goalId,
    required this.weekStatus,
    required this.toggleStatus,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Day abbreviations (Mon, Tue, Wed, etc.)
    final List<String> dayAbbreviations = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: weekStatus.length,
      itemBuilder: (context, index) {
        var dayStatus = weekStatus[index];
        String date = dayStatus['date'];
        String status = dayStatus['status'];

        // Get the day of the week (Mon, Tue, etc.)
        int dayIndex = DateTime.parse(date).weekday - 1;
        String dayAbbreviation = dayAbbreviations[dayIndex];

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayAbbreviation, // Show the day abbreviation
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            // Adjust the size of the circle here
            Flexible(
              child: AspectRatio(
                aspectRatio: 1,
                child: DayCheckbox(
                  goalId: goalId,
                  date: date,
                  status: status,
                  toggleStatus: toggleStatus,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
