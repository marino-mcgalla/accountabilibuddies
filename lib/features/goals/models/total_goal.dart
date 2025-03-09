import 'goal_model.dart';
import 'proof_model.dart';

class TotalGoal extends Goal {
  int totalCompletions; // Running total of all completions
  List<Proof> proofs; // List of pending proof submissions

  TotalGoal({
    required String id,
    required String ownerId,
    required String goalName,
    required String goalCriteria,
    required bool active,
    required int goalFrequency,
    required Map<String, int> currentWeekCompletions,
    this.totalCompletions = 0,
    this.proofs = const [],
  }) : super(
          id: id,
          ownerId: ownerId,
          goalName: goalName,
          goalType: 'total',
          goalCriteria: goalCriteria,
          active: active,
          goalFrequency: goalFrequency,
          currentWeekCompletions: currentWeekCompletions,
        );

  // Type-safe getter for currentWeekCompletions
  Map<String, int> get totalCompletionsMap =>
      Map<String, int>.from(currentWeekCompletions);

  void addTotalProof(String proofText, String? imageUrl, DateTime date) {
    Map<String, dynamic> proofData = {
      'proofText': proofText,
      'imageUrl': imageUrl,
      'status': 'pending',
      'submissionDate': date.toIso8601String(),
    };

    // Add to challenge proofs array
    (challenge!['proofs'] as List).add(proofData);

    // Add to class-specific proofs list
    proofs.add(Proof(
      proofText: proofText,
      submissionDate: date,
      imageUrl: imageUrl,
    ));
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['totalCompletions'] = totalCompletions;
    map['proofs'] = proofs.map((proof) => proof.toMap()).toList();
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
      currentWeekCompletions:
          Map<String, int>.from(data['currentWeekCompletions'] ?? {}),
      totalCompletions: data['totalCompletions'] ?? 0,
      proofs: (data['proofs'] as List<dynamic>?)
              ?.map((proofData) => Proof.fromMap(proofData))
              .toList() ??
          [],
    );
  }
}
