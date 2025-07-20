import '../../../../core/core.dart';
import '../entities/goal.dart';

abstract class GoalRepository {
  /// Get all goals for a user
  Future<Result<List<Goal>>> getGoals(String userId);
  
  /// Get goals by status
  Future<Result<List<Goal>>> getGoalsByStatus(String userId, GoalStatus status);
  
  /// Get goals by category
  Future<Result<List<Goal>>> getGoalsByCategory(String userId, GoalCategory category);
  
  /// Get a specific goal by ID
  Future<Result<Goal>> getGoal(String goalId);
  
  /// Create a new goal
  Future<Result<Goal>> createGoal(Goal goal);
  
  /// Update an existing goal
  Future<Result<Goal>> updateGoal(Goal goal);
  
  /// Delete a goal
  Future<Result<void>> deleteGoal(String goalId);
  
  /// Update goal progress
  Future<Result<Goal>> updateProgress(String goalId, int currentCount);
  
  /// Mark goal as completed
  Future<Result<Goal>> completeGoal(String goalId);
  
  /// Stream of user's goals
  Stream<Result<List<Goal>>> watchGoals(String userId);
  
  /// Stream of a specific goal
  Stream<Result<Goal>> watchGoal(String goalId);
}