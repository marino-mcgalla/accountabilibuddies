import 'package:equatable/equatable.dart';
import '../../../goals/domain/entities/goal_template.dart';

/// Represents a goal that a user has committed to for a challenge
/// This is embedded within the UserChallengeParticipation document
class ChallengeGoal extends Equatable {
  const ChallengeGoal({
    required this.name,
    required this.templateId,
    required this.targetFrequency,
    required this.description,
    required this.goalType,
    this.completedDates = const [],
    this.parameters = const {},
  });

  /// Name of the goal (snapshot from template at commitment time)
  final String name;
  
  /// ID of the original goal template
  final String templateId;
  
  /// How many times per week the user committed to do this goal
  final int targetFrequency;
  
  /// Description of the goal (snapshot from template)
  final String description;
  
  /// Type of goal (daily or total) - snapshot from template
  final GoalType goalType;
  
  /// Dates when this goal was completed (YYYY-MM-DD format)
  final List<String> completedDates;
  
  /// Goal-specific parameters (duration, count, etc.)
  final Map<String, dynamic> parameters;

  /// Calculate completion rate for the week
  double get completionRate {
    if (targetFrequency == 0) return 1.0;
    return (completedDates.length / targetFrequency).clamp(0.0, 1.0);
  }

  /// Check if this goal is fully completed
  bool get isCompleted => completedDates.length >= targetFrequency;

  /// Get remaining completions needed
  int get remainingCompletions => (targetFrequency - completedDates.length).clamp(0, targetFrequency);

  /// Display the frequency in a user-friendly way
  String get frequencyDisplay {
    if (targetFrequency == 1) {
      return 'Once per week';
    } else if (targetFrequency == 7) {
      return 'Daily';
    } else {
      return '$targetFrequency times per week';
    }
  }

  ChallengeGoal copyWith({
    String? name,
    String? templateId,
    int? targetFrequency,
    String? description,
    GoalType? goalType,
    List<String>? completedDates,
    Map<String, dynamic>? parameters,
  }) {
    return ChallengeGoal(
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      completedDates: completedDates ?? this.completedDates,
      parameters: parameters ?? this.parameters,
    );
  }

  /// Add a completion date
  ChallengeGoal addCompletion(String date) {
    if (completedDates.contains(date)) return this;
    return copyWith(completedDates: [...completedDates, date]..sort());
  }

  /// Remove a completion date
  ChallengeGoal removeCompletion(String date) {
    return copyWith(completedDates: completedDates.where((d) => d != date).toList());
  }

  @override
  List<Object?> get props => [
        name,
        templateId,
        targetFrequency,
        description,
        goalType,
        completedDates,
        parameters,
      ];

  @override
  String toString() => 'ChallengeGoal(name: $name, target: $targetFrequency, completed: ${completedDates.length})';
}