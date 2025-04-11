import 'package:auth_test/refactor/total_goal.dart';
import 'package:auth_test/refactor/weekly_goal.dart';

abstract class Goal {
  final String id;
  final String ownerId;
  final String goalName;
  final String goalType;
  final String goalCriteria;
  final bool active;
  final int goalFrequency;
  DateTime weekStartDate;
  Map<String, dynamic> currentWeekCompletions;

  Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.goalType,
    required this.goalCriteria,
    required this.active,
    required this.goalFrequency,
    required this.weekStartDate,
    required this.currentWeekCompletions,
  });

  Map<String, dynamic> toMap();

  factory Goal.fromMap(Map<String, dynamic> data) {
    switch (data['goalType']) {
      case 'total':
        return TotalGoal.fromMap(data);
      case 'weekly':
        return WeeklyGoal.fromMap(data);
      default:
        throw Exception('Unknown goal type');
    }
  }
}
