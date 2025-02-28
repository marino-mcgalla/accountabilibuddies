// lib/features/goals/services/proof_service.dart
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import '../models/proof_model.dart';
import '../repositories/goals_repository.dart';
import '../../time_machine/providers/time_machine_provider.dart';

class ProofService {
  final GoalsRepository _repository;
  final TimeMachineProvider _timeMachineProvider;

  ProofService(this._repository, this._timeMachineProvider);

  // Submit proof for a goal
  Future<void> submitProof(
      List<Goal> currentGoals, String goalId, String proofText) async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    final updatedGoals = List<Goal>.from(currentGoals);
    int index = updatedGoals.indexWhere((goal) => goal.id == goalId);

    if (index == -1) return;

    Goal goal = updatedGoals[index];
    DateTime submissionDate = _timeMachineProvider.now;

    if (goal is WeeklyGoal) {
      String currentDay = submissionDate.toIso8601String().split('T').first;
      goal.currentWeekCompletions[currentDay] = 'submitted';
    } else if (goal is TotalGoal) {
      Proof proof = Proof(
        proofText: proofText,
        submissionDate: submissionDate,
      );
      goal.proofs.add(proof);
    }

    await _repository.saveGoals(userId, updatedGoals);
  }

  // Approve proof for another user's goal
  Future<void> approveProof(
      String goalId, String userId, String? proofDate) async {
    List<Goal> userGoals = await _repository.getGoalsForUser(userId);

    int goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) return;

    Goal goal = userGoals[goalIndex];

    if (goal is WeeklyGoal && proofDate != null) {
      goal.currentWeekCompletions[proofDate] = 'completed';
    } else if (goal is TotalGoal) {
      final day = _timeMachineProvider.now.toIso8601String().split('T').first;
      goal.currentWeekCompletions[day] =
          (goal.currentWeekCompletions[day] ?? 0) + 1;
      goal.totalCompletions += 1;
      if (goal.proofs.isNotEmpty) {
        goal.proofs.removeAt(0); // Remove the first proof
      }
    }

    await _repository.updateUserGoals(userId, userGoals);
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
    } else if (goal is TotalGoal) {
      if (goal.proofs.isNotEmpty) {
        goal.proofs.removeAt(0); // Remove the first proof
      }
    }

    await _repository.updateUserGoals(userId, userGoals);
  }
}
