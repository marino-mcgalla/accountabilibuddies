import '../models/goal_model.dart';

class GoalsState {
  final List<Goal> goals;
  final bool isLoading;

  const GoalsState({
    this.goals = const [],
    this.isLoading = false,
  });

  GoalsState copyWith({
    List<Goal>? goals,
    bool? isLoading,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Goal> get activeGoals => goals.where((goal) => goal.active).toList();
  
  Goal? getGoalById(String id) {
    try {
      return goals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  bool get hasActiveGoals => activeGoals.isNotEmpty;
  
  int get totalActiveGoals => activeGoals.length;
  
  List<Goal> getGoalsByType(String type) {
    return goals.where((goal) => goal.goalType == type).toList();
  }
}