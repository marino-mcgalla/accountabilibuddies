// lib/features/goals/services/proof_service.dart
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import '../models/proof_model.dart';
import '../repositories/goals_repository.dart';
import '../../time_machine/providers/time_machine_provider.dart';
import 'package:flutter/material.dart';

class ProofService {
  final GoalsRepository _repository;
  final TimeMachineProvider _timeMachineProvider;

  ProofService(this._repository, this._timeMachineProvider);

// Let's review the original submitProof method in lib/features/goals/services/proof_service.dart:

  Future<void> submitProof(List<Goal> currentGoals, String goalId,
      String proofText, String? imageUrl, bool yesterday) async {
    debugPrint(
        'SubmitProof called with text: $proofText, imageUrl: $imageUrl, yesterday: $yesterday');
    DateTime submissionDate;
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    final updatedGoals = List<Goal>.from(currentGoals);
    int index = updatedGoals.indexWhere((goal) => goal.id == goalId);

    if (index == -1) return;

    Goal goal = updatedGoals[index];
    if (!yesterday) {
      submissionDate = _timeMachineProvider.now;
    } else {
      submissionDate = _timeMachineProvider.now.subtract(Duration(days: 1));
    }
    String currentDay = submissionDate.toIso8601String().split('T').first;

    if (goal is WeeklyGoal) {
      goal.currentWeekCompletions[currentDay] = 'submitted';

      Proof proof = Proof(
        proofText: proofText,
        submissionDate: submissionDate,
        imageUrl: imageUrl,
      );

      goal.proofs[currentDay] = proof;

      debugPrint('Added proof to weekly goal for day: $currentDay');
    } else if (goal is TotalGoal) {
      Proof proof = Proof(
        proofText: proofText,
        submissionDate: submissionDate,
        imageUrl: imageUrl,
      );

      goal.proofs.add(proof);

      debugPrint('Added proof to total goal');
    }

    await _repository.saveChallengeGoals(userId, updatedGoals);
  }

  // Approve proof for another user's goal
  //TODO: check that this is actually doing something
  Future<void> approveProof(
      String goalId, String userId, String? proofDate) async {
    print(
        'Approving proof for goalId: $goalId, userId: $userId, date: $proofDate');
    List<Goal> userGoals = await _repository.getGoalsForUser(userId);

    int goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) return;

    Goal goal = userGoals[goalIndex];

    if (goal is WeeklyGoal && proofDate != null) {
      // Change status from 'submitted' to 'completed'
      goal.currentWeekCompletions[proofDate] = 'completed';

      // Optional: Remove proof now that it's been approved
      if (goal.proofs.containsKey(proofDate)) {
        goal.proofs.remove(proofDate);
      }

      print('Weekly goal proof approved for date: $proofDate');
    } else if (goal is TotalGoal) {
      // For total goals, increment the counter and remove the proof
      final day = _timeMachineProvider.now.toIso8601String().split('T').first;

      // Update current week completions counter
      int currentCount = goal.currentWeekCompletions[day] as int? ?? 0;
      goal.currentWeekCompletions[day] = currentCount + 1;

      // Update total completions counter
      goal.totalCompletions += 1;

      // Remove the proof (assuming first proof in the list)
      if (goal.proofs.isNotEmpty) {
        goal.proofs.removeAt(0);
      }

      print(
          'Total goal proof approved, completions now: ${goal.totalCompletions}');
    }

    // Save the updated goals
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
