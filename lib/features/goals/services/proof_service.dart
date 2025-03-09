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

  // Deny proof for another user's goal
  Future<void> denyProof(
      String goalId, String userId, String? proofDate) async {
    List<Goal> userGoals = await _repository.getGoalsForUser(userId);

    int goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) return;

    Goal goal = userGoals[goalIndex];

    if (goal is WeeklyGoal && proofDate != null) {
      goal.currentWeekCompletions[proofDate] = 'denied';

      // Remove the proof from the proofs map since it's been denied
      if (goal.proofs.containsKey(proofDate)) {
        goal.proofs.remove(proofDate);
      }
    } else if (goal is TotalGoal) {
      if (goal.proofs.isNotEmpty) {
        goal.proofs.removeAt(0); // Remove the first proof
      }
    }

    await _repository.updateUserGoals(userId, userGoals);
  }
}
