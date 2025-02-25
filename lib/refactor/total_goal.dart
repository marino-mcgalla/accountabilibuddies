import 'goal_model.dart';

class TotalGoal extends Goal {
  int totalCompletions;

  TotalGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required bool active,
    required int goalFrequency,
    required DateTime weekStartDate,
    Map<String, int>? currentWeekCompletions,
    this.totalCompletions = 0,
    String? proofText,
    String? proofStatus,
    DateTime? proofSubmissionDate,
  }) : super(
          id: id,
          ownerId: ownerId,
          goalName: goalName,
          goalType: 'total',
          goalCriteria: goalCriteria,
          goalFrequency: goalFrequency,
          active: active,
          weekStartDate: weekStartDate,
          currentWeekCompletions: currentWeekCompletions ?? {},
          proofText: proofText,
          proofStatus: proofStatus,
          proofSubmissionDate: proofSubmissionDate,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['totalCompletions'] = totalCompletions;
    return map;
  }

  factory TotalGoal.fromMap(Map<String, dynamic> data) {
    return TotalGoal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalCriteria: data['goalCriteria'],
      active: data['active'],
      goalFrequency: data['goalFrequency'],
      weekStartDate: DateTime.parse(data['weekStartDate']),
      currentWeekCompletions:
          Map<String, int>.from(data['currentWeekCompletions'] ?? {}),
      totalCompletions: data['totalCompletions'] ?? 0,
      proofText: data['proofText'],
      proofStatus: data['proofStatus'],
      proofSubmissionDate: data['proofSubmissionDate'] != null
          ? DateTime.parse(data['proofSubmissionDate'])
          : null,
    );
  }
}
