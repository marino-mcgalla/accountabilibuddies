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
    Map<String, dynamic>? challenge,
  }) : super(
          id: id,
          ownerId: ownerId,
          goalName: goalName,
          goalType: 'weekly',
          goalCriteria: goalCriteria,
          active: active,
          goalFrequency: goalFrequency,
          currentWeekCompletions: currentWeekCompletions,
          challenge: challenge,
        );

  // Type-safe getter for currentWeekCompletions
  Map<String, String> get weeklyCompletions =>
      Map<String, String>.from(currentWeekCompletions);

  void addWeeklyProof(String proofText, String? imageUrl, DateTime date) {
    // First initialize the challenge object if it doesn't exist
    challenge ??= {
      'challengeFrequency': goalFrequency,
      'challengeCriteria': goalCriteria,
      'completions': {},
      'proofs': {}, // Initialize as empty MAP for weekly goals
    };

    // Ensure the proofs map exists
    if (challenge!['proofs'] == null) {
      challenge!['proofs'] = {};
    }

    // Ensure the completions map exists
    if (challenge!['completions'] == null) {
      challenge!['completions'] = {};
    }

    String day = date.toIso8601String().split('T').first;

    // Map<String, dynamic> proofData = {
    //   'proofText': proofText,
    //   'imageUrl': imageUrl,
    //   'status': 'pending',
    //   'submissionDate': date.toIso8601String(),
    // };

    // // Now safely access challenge fields
    // challenge!['proofs'][day] = proofData;
    // challenge!['completions'][day] = 'submitted';

    // // Update legacy data
    // currentWeekCompletions[day] = 'submitted';

    // // Add to class-specific proofs map
    // proofs[day] = Proof(
    //   proofText: proofText,
    //   submissionDate: date,
    //   imageUrl: imageUrl,
    // );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['proofs'] = proofs.map((date, proof) => MapEntry(date, proof.toMap()));
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
      active: data['active'],
      goalFrequency: data['goalFrequency'],
      currentWeekCompletions:
          Map<String, String>.from(data['currentWeekCompletions'] ?? {}),
      proofs: proofMap,
      challenge: data['challenge'],
    );
  }
}
