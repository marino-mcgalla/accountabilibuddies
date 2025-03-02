// lib/features/goals/services/week_service.dart
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import '../repositories/goals_repository.dart';
import '../../time_machine/providers/time_machine_provider.dart';

class WeekService {
  final GoalsRepository _repository;
  final TimeMachineProvider _timeMachineProvider;

  WeekService(this._repository, this._timeMachineProvider);

  // End the current week and start a new one
  Future<void> endWeek(List<Goal> currentGoals) async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    // Save current week's progress to history
    await _repository.saveGoalsHistory(
        userId, currentGoals, _timeMachineProvider.now);

    // Reset goals for the new week
    DateTime newWeekStartDate = _timeMachineProvider.now;
    final updatedGoals = List<Goal>.from(currentGoals);

    for (Goal goal in updatedGoals) {
      goal.weekStartDate = newWeekStartDate;

      if (goal is WeeklyGoal) {
        goal.currentWeekCompletions = {}; // Reset weekly completions
      } else if (goal is TotalGoal) {
        goal.currentWeekCompletions = {}; // Reset weekly counts
      }
    }

    await _repository.saveGoals(userId, updatedGoals);
  }
}
