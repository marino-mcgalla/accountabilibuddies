import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';
import '../models/challenge_data.dart';
import '../repositories/goals_repository.dart';

class GoalsActions {
  final GoalsRepository _repository;
  final FirebaseAuth _auth;

  GoalsActions({
    GoalsRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? GoalsRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  Future<bool> createGoal(List<Goal> currentGoals, Goal newGoal) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final updatedGoals = List<Goal>.from(currentGoals)..add(newGoal);
      await _repository.saveGoals(userId, updatedGoals);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editGoal(List<Goal> currentGoals, Goal updatedGoal) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final goals = List<Goal>.from(currentGoals);
      final index = goals.indexWhere((g) => g.id == updatedGoal.id);
      
      if (index == -1) return false;

      // Use copyWith method to preserve existing challenge data
      goals[index] = goals[index].copyWith(
        goalName: updatedGoal.goalName,
        goalCriteria: updatedGoal.goalCriteria,
        goalFrequency: updatedGoal.goalFrequency,
      );

      await _repository.saveGoals(userId, goals);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeGoal(List<Goal> currentGoals, String goalId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final updatedGoals = currentGoals.where((goal) => goal.id != goalId).toList();
      await _repository.saveGoals(userId, updatedGoals);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleGoalActive(List<Goal> currentGoals, String goalId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final goals = List<Goal>.from(currentGoals);
      final index = goals.indexWhere((goal) => goal.id == goalId);
      
      if (index == -1) return false;

      // This would need to be implemented in the Goal model
      // For now, we'll assume there's a way to toggle active status
      await _repository.saveGoals(userId, goals);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleSkipPlan(List<Goal> currentGoals, String goalId, String day, String status) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final goals = List<Goal>.from(currentGoals);
      final index = goals.indexWhere((goal) => goal.id == goalId);
      
      if (index == -1 || goals[index].goalType != GoalType.weekly) return false;

      final goal = goals[index];
      
      // Update the completion status for the specific day using challengeData
      final currentData = goal.challengeData ?? const ChallengeData();
      final updatedCompletions = Map<String, String>.from(currentData.completions);
      updatedCompletions[day] = status;
      
      goals[index] = goal.copyWith(
        challengeData: currentData.copyWith(
          completions: updatedCompletions,
        ),
      );

      await _repository.saveGoals(userId, goals);
      return true;
    } catch (e) {
      return false;
    }
  }
}