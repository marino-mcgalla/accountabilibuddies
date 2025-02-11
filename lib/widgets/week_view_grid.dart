import 'package:flutter/material.dart';
import 'day_checkbox.dart';
import 'package:intl/intl.dart';

class WeekViewGrid extends StatelessWidget {
  final String goalId;

  const WeekViewGrid({required this.goalId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    List<String> weekDates = List.generate(7, (index) {
      DateTime date = monday.add(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    });

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        String date = weekDates[index];
        return DayCheckbox(goalId: goalId, date: date);
      },
    );
  }
}
