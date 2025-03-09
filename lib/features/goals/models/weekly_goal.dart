import 'goal_model.dart';
import 'proof_model.dart';

class WeeklyGoal extends Goal {
  Map<String, Proof> proofs;

  WeeklyGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required bool active,
    required int goalFrequency,
    required Map<String, String> currentWeekCompletions,
    this.proofs = const {},
  }) : super(
          id: id,
          ownerId: ownerId,
          goalName: goalName,
          goalType: 'weekly',
          goalCriteria: goalCriteria,
          active: active,
          goalFrequency: goalFrequency,
          currentWeekCompletions: currentWeekCompletions,
        );

  Map<String, String> get weeklyCompletions =>
      Map<String, String>.from(currentWeekCompletions);

// In lib/features/goals/models/weekly_goal.dart
// Replace just the toMap method with this:

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();

    // Convert the proofs map to a format that Firestore can understand
    Map<String, dynamic> proofsMap = {};
    proofs.forEach((date, proof) {
      proofsMap[date] = proof.toMap();
    });

    map['proofs'] = proofsMap;
    return map;
  }

  factory WeeklyGoal.fromMap(Map<String, dynamic> data) {
    // Parse proofs
    Map<String, Proof> proofMap = {};
    if (data['proofs'] != null) {
      final Map<String, dynamic> proofsData =
          Map<String, dynamic>.from(data['proofs']);
      proofsData.forEach((date, proofData) {
        proofMap[date] = Proof.fromMap(proofData);
      });
    }

    return WeeklyGoal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalCriteria: data['goalCriteria'],
      active: data['active'] ?? true,
      goalFrequency: data['goalFrequency'],
      currentWeekCompletions:
          Map<String, String>.from(data['currentWeekCompletions'] ?? {}),
      proofs: proofMap,
    );
  }
}
