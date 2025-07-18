// lib/features/goals/services/goal_management_service.dart
import '../models/goal_model.dart';
import '../repositories/goals_repository.dart';

class GoalManagementService {
  final GoalsRepository _repository;

  GoalManagementService(this._repository);

  // Add a new goal
  Future<void> createGoal(List<Goal> currentGoals, Goal newGoal) async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    final updatedGoals = List<Goal>.from(currentGoals)..add(newGoal);
    await _repository.saveGoals(userId, updatedGoals);
  }

  Future<void> createWeek(List<Goal> currentGoals, Goal newGoal) async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    final updatedGoals = List<Goal>.from(currentGoals)..add(newGoal);
    await _repository.saveGoals(userId, updatedGoals);
  }

  // Edit an existing goal
  Future<void> editGoal(List<Goal> currentGoals, Goal updatedGoal) async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    final updatedGoals = List<Goal>.from(currentGoals);
    int index = updatedGoals.indexWhere((goal) => goal.id == updatedGoal.id);

    if (index != -1) {
      updatedGoals[index] = updatedGoal;
      await _repository.saveGoals(userId, updatedGoals);
    }
  }

// More efficient method that only updates the one field
  Future<void> updateGoalActiveStatus(String goalId, bool active) async {
    final userId = _repository.getCurrentUserId();
    if (userId == null) return;

    // Update just the active field in Firestore
    await _repository.updateGoalField(userId, goalId, 'active', active);
  }

  // Remove a goal
  Future<void> removeGoal(List<Goal> currentGoals, String goalId) async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    final updatedGoals =
        currentGoals.where((goal) => goal.id != goalId).toList();
    await _repository.saveGoals(userId, updatedGoals);
  }
}
