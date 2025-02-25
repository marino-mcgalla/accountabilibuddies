import 'package:auth_test/refactor/total_goal.dart';
import 'package:auth_test/refactor/weekly_goal.dart';

class Goal {
  final String id;
  final String ownerId;
  final String goalName;
  final String goalType;
  final String goalCriteria;
  final int goalFrequency;
  final bool active;
  DateTime weekStartDate; // Make this non-final
  Map<String, dynamic> currentWeekCompletions;
  String? proofText;
  String? proofStatus;
  DateTime? proofSubmissionDate;

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
    this.proofText,
    this.proofStatus,
    this.proofSubmissionDate,
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
      'proofText': proofText,
      'proofStatus': proofStatus,
      'proofSubmissionDate': proofSubmissionDate?.toIso8601String(),
    };
  }
}
