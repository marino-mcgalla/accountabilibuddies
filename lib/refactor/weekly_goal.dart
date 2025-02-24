import 'goal_model.dart';

class WeeklyGoal extends Goal {
  WeeklyGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required bool active,
    required int goalFrequency,
    required DateTime weekStartDate,
    required Map<String, String> currentWeekCompletions,
    String? proofText,
    String? proofStatus,
    DateTime? proofSubmissionDate,
  }) : super(
          id: id,
          ownerId: ownerId,
          goalName: goalName,
          goalType: 'weekly',
          goalCriteria: goalCriteria,
          active: active,
          goalFrequency: goalFrequency,
          weekStartDate: weekStartDate,
          currentWeekCompletions: currentWeekCompletions,
          proofText: proofText,
          proofStatus: proofStatus,
          proofSubmissionDate: proofSubmissionDate,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalType': goalType,
      'goalCriteria': goalCriteria,
      'active': active,
      'goalFrequency': goalFrequency,
      'weekStartDate': weekStartDate.toIso8601String(),
      'currentWeekCompletions': currentWeekCompletions,
      'proofText': proofText,
      'proofStatus': proofStatus,
      'proofSubmissionDate': proofSubmissionDate?.toIso8601String(),
    };
  }

  factory WeeklyGoal.fromMap(Map<String, dynamic> data) {
    return WeeklyGoal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalCriteria: data['goalCriteria'],
      active: data['active'],
      goalFrequency: data['goalFrequency'],
      weekStartDate: DateTime.parse(data['weekStartDate']),
      currentWeekCompletions:
          Map<String, String>.from(data['currentWeekCompletions']),
      proofText: data['proofText'],
      proofStatus: data['proofStatus'],
      proofSubmissionDate: data['proofSubmissionDate'] != null
          ? DateTime.parse(data['proofSubmissionDate'])
          : null,
    );
  }
}
