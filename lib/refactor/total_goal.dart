import 'goal_model.dart';

class TotalGoal extends Goal {
  TotalGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required int goalFrequency,
    required DateTime weekStartDate,
    required Map<String, int> currentWeekCompletions,
  }) : super(
          id: id,
          ownerId: ownerId,
          goalName: goalName,
          goalType: 'total',
          goalCriteria: goalCriteria,
          goalFrequency: goalFrequency,
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

  factory TotalGoal.fromMap(Map<String, dynamic> data) {
    return TotalGoal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalCriteria: data['goalCriteria'],
      goalFrequency: data['goalFrequency'],
      weekStartDate: DateTime.parse(data['weekStartDate']),
      currentWeekCompletions:
          Map<String, int>.from(data['currentWeekCompletions']),
    );
  }
}
