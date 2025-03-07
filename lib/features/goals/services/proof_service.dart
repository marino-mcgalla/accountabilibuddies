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

  // Submit proof for a goal with optional image URL
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
      // Update status to 'submitted'
      goal.currentWeekCompletions[currentDay] = 'submitted';

      // Create a proof object with the text and image URL
      Proof proof = Proof(
        proofText: proofText,
        submissionDate: submissionDate,
        imageUrl: imageUrl,
      );

      // Store the proof in the weekly goal's proofs map
      goal.proofs[currentDay] = proof;

      debugPrint('Added proof to weekly goal for day: $currentDay');
    } else if (goal is TotalGoal) {
      // Create a proof object with the text and image URL
      Proof proof = Proof(
        proofText: proofText,
        submissionDate: submissionDate,
        imageUrl: imageUrl,
      );

      // Add the proof to the total goal's proofs list
      goal.proofs.add(proof);

      debugPrint('Added proof to total goal');
    }

    await _repository.saveChallengeGoals(userId, updatedGoals);
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

      // Remove the proof from the proofs map since it's been approved
      if (goal.proofs.containsKey(proofDate)) {
        goal.proofs.remove(proofDate);
      }
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
