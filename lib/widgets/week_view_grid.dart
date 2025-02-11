import 'package:flutter/material.dart';
import 'day_checkbox.dart';
import 'package:intl/intl.dart';

class WeekViewGrid extends StatelessWidget {
  final String goalId;
  final List<dynamic> weekStatus;
  final Function(BuildContext, String, String, String) toggleStatus;

  const WeekViewGrid(
      {required this.goalId,
      required this.weekStatus,
      required this.toggleStatus,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: weekStatus.length,
      itemBuilder: (context, index) {
        var dayStatus = weekStatus[index];
        String date = dayStatus['date'];
        String status = dayStatus['status'];

        return DayCheckbox(
            goalId: goalId,
            date: date,
            status: status,
            toggleStatus: toggleStatus);
      },
    );
  }
}
