// lib/features/goals/services/proof_service.dart
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import '../repositories/goals_repository.dart';
import '../../time_machine/providers/time_machine_provider.dart';

class ProofService {
  final GoalsRepository _repository;
  final TimeMachineProvider _timeMachineProvider;

  ProofService(this._repository, this._timeMachineProvider);

  Future<void> submitProof(List<Goal> currentGoals, String goalId,
      String proofText, String? imageUrl, bool yesterday) async {
    String? userId =
        _repository.getCurrentUserId(); //TODO: replace this with _auth.userId
    if (userId == null) return;

    int index = currentGoals.indexWhere((goal) => goal.id == goalId);
    if (index == -1) return;

    // Create working copy
    final updatedGoals = List<Goal>.from(currentGoals);
    Goal goal = updatedGoals[index];

    // Calculate date
    DateTime submissionDate = yesterday
        ? _timeMachineProvider.now.subtract(Duration(days: 1))
        : _timeMachineProvider.now;

    // Let the goal handle its own proof logic
    goal.addProof(proofText, imageUrl, submissionDate);

    // Save to Firebase
    await _repository.saveGoals(userId, updatedGoals);
  }

// In ProofService
  Future<void> denyProof(Goal goal, String? proofDate) async {
    // Just update the model - business logic only
    if (goal.goalType == 'weekly' && proofDate != null) {
      goal.challenge ??= {'completions': {}, 'proofs': {}};

      // Update completions to denied
      Map<String, dynamic> completions =
          goal.challenge!['completions'] as Map<String, dynamic>? ?? {};
      completions[proofDate] = 'denied';
      goal.challenge!['completions'] = completions;

      // Remove the proof
      if (goal.challenge!['proofs'] is Map) {
        (goal.challenge!['proofs'] as Map).remove(proofDate);
      }
    } else if (goal.goalType == 'total') {
      goal.challenge ??= {'completions': {}, 'proofs': []};

      // Remove first pending proof
      if (goal.challenge!['proofs'] is List) {
        List proofs = goal.challenge!['proofs'] as List;
        int pendingIndex = proofs.indexWhere((p) => p['status'] == 'pending');
        if (pendingIndex != -1) {
          proofs.removeAt(pendingIndex);
        }
      }
    }
  }
}
