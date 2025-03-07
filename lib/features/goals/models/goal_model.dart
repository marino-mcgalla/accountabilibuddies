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
  Map<String, dynamic> currentWeekCompletions; // Adding this back

  Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.goalType,
    required this.goalCriteria,
    required this.goalFrequency,
    required this.active,
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
      'currentWeekCompletions': currentWeekCompletions,
    };
  }

  // Compatibility getters for MemberItem widget
  bool get isCompleted {
    // Get the number of completions recorded for this week
    int completionsCount = 0;

    // Sum up the values in the completions map
    if (currentWeekCompletions.isNotEmpty) {
      currentWeekCompletions.forEach((date, value) {
        if (value is int) {
          completionsCount += value;
        } else if (value is bool && value) {
          completionsCount += 1;
        }
      });
    }

    // Goal is completed if the number of completions meets or exceeds the goal frequency
    return completionsCount >= goalFrequency;
  }

  // Map goalName to title for compatibility
  String get title => goalName;
}
