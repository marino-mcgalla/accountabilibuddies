import 'package:auth_test/features/goals/models/total_goal.dart';
import 'package:auth_test/features/goals/models/weekly_goal.dart';

class Goal {
  final String id;
  final String ownerId;
  final String goalName;
  final String goalType; // 'weekly' or 'total'
  final String goalCriteria;
  final int goalFrequency;
  final bool active; // Whether the goal is active for the current week
  DateTime weekStartDate; // When current week tracking started
  Map<String, dynamic> currentWeekCompletions; // Adding this back

  Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.goalType,
    required this.goalCriteria,
    required this.goalFrequency,
    required this.active,
    required this.weekStartDate,
    required this.currentWeekCompletions,
  });

  factory Goal.fromMap(Map<String, dynamic> data) {
    if (data['goalType'] == 'weekly') {
      return WeeklyGoal.fromMap(data);
    } else if (data['goalType'] == 'total') {
      return TotalGoal.fromMap(data);
    } else {
      throw Exception('Unknown goal type');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalType': goalType,
      'goalCriteria': goalCriteria,
      'goalFrequency': goalFrequency,
      'active': active,
      'weekStartDate': weekStartDate.toIso8601String(),
      'currentWeekCompletions': currentWeekCompletions,
    };
  }
}
