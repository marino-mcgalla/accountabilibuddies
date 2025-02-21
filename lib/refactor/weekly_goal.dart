import 'goal_model.dart';

class WeeklyGoal extends Goal {
  final Map<String, bool> completions;

  WeeklyGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required this.completions,
  }) : super(
            id: id,
            ownerId: ownerId,
            goalName: goalName,
            goalType: 'weekly',
            goalCriteria: goalCriteria,
            goalFrequency: 7); // Set to 7 for weekly goals

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalType': goalType,
      'goalCriteria': goalCriteria,
      'goalFrequency': goalFrequency,
      'completions': completions,
    };
  }

  factory WeeklyGoal.fromMap(Map<String, dynamic> data) {
    return WeeklyGoal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalCriteria: data['goalCriteria'],
      completions: Map<String, bool>.from(data['completions']),
    );
  }
}
