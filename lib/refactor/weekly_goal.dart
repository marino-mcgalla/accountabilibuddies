import 'goal_model.dart';

class WeeklyGoal extends Goal {
  WeeklyGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required DateTime weekStartDate,
    required Map<String, bool> currentWeekCompletions,
  }) : super(
          id: id,
          ownerId: ownerId,
          goalName: goalName,
          goalType: 'weekly',
          goalCriteria: goalCriteria,
          goalFrequency: 7, // Set to 7 for weekly goals
          weekStartDate: weekStartDate,
          currentWeekCompletions: currentWeekCompletions,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalType': goalType,
      'goalCriteria': goalCriteria,
      'goalFrequency': goalFrequency,
      'weekStartDate': weekStartDate.toIso8601String(),
      'currentWeekCompletions': currentWeekCompletions,
    };
  }

  factory WeeklyGoal.fromMap(Map<String, dynamic> data) {
    return WeeklyGoal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalCriteria: data['goalCriteria'],
      weekStartDate: DateTime.parse(data['weekStartDate']),
      currentWeekCompletions:
          Map<String, bool>.from(data['currentWeekCompletions']),
    );
  }
}
