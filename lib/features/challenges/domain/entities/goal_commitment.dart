import 'package:equatable/equatable.dart';
import '../../../goals/domain/entities/goal_template.dart';

/// Represents a user's commitment to work on a specific goal during a challenge
/// This is used during the goal selection/commitment phase before goals are locked in
class GoalCommitment extends Equatable {
  const GoalCommitment({
    required this.goalId,
    required this.goalName,
    required this.weeklyFrequency,
    required this.goalType,
    required this.parameters,
    this.description,
  });

  /// ID of the goal template this commitment is based on
  final String goalId;
  
  /// Name/title of the goal
  final String goalName;
  
  /// How many times per week the user commits to completing this goal
  final int weeklyFrequency;
  
  /// Type of goal (daily or total) from the template
  final GoalType goalType;
  
  /// Additional parameters for the goal (e.g., duration, intensity)
  final Map<String, dynamic> parameters;
  
  /// Optional description or notes about the commitment
  final String? description;

  GoalCommitment copyWith({
    String? goalId,
    String? goalName,
    int? weeklyFrequency,
    GoalType? goalType,
    Map<String, dynamic>? parameters,
    String? description,
  }) {
    return GoalCommitment(
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
      goalType: goalType ?? this.goalType,
      parameters: parameters ?? this.parameters,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        goalId,
        goalName,
        weeklyFrequency,
        goalType,
        parameters,
        description,
      ];

  @override
  String toString() => 'GoalCommitment(goalId: $goalId, goalName: $goalName, weeklyFrequency: $weeklyFrequency)';
}