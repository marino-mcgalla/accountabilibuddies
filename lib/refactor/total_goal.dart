import 'goal_model.dart';

class TotalGoal extends Goal {
  int completions;

  TotalGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required int goalFrequency,
    this.completions = 0,
  }) : super(
            id: id,
            ownerId: ownerId,
            goalName: goalName,
            goalType: 'total',
            goalCriteria: goalCriteria,
            goalFrequency: goalFrequency);

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

  factory TotalGoal.fromMap(Map<String, dynamic> data) {
    return TotalGoal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalCriteria: data['goalCriteria'],
      goalFrequency: data['goalFrequency'],
      completions: data['completions'] ?? 0,
    );
  }
}
