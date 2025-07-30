import '../../../goals/domain/entities/goal_template.dart';
import '../../domain/entities/challenge_goal.dart';

class ChallengeGoalModel {
  const ChallengeGoalModel({
    required this.name,
    required this.templateId,
    required this.targetFrequency,
    required this.description,
    required this.goalType,
    this.completedDates = const [],
    this.parameters = const {},
  });

  final String name;
  final String templateId;
  final int targetFrequency;
  final String description;
  final GoalType goalType;
  final List<String> completedDates;
  final Map<String, dynamic> parameters;

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'templateId': templateId,
      'targetFrequency': targetFrequency,
      'description': description,
      'goalType': goalType.name,
      'completedDates': completedDates,
      'parameters': parameters,
    };
  }

  factory ChallengeGoalModel.fromFirestore(Map<String, dynamic> data) {
    return ChallengeGoalModel(
      name: data['name'] ?? '',
      templateId: data['templateId'] ?? '',
      targetFrequency: data['targetFrequency'] ?? 0,
      description: data['description'] ?? '',
      goalType: GoalType.values.firstWhere(
        (type) => type.name == (data['goalType'] ?? data['type']), // Check both new and legacy field names
        orElse: () => GoalType.daily, // Default fallback - most goals are daily
      ),
      completedDates: List<String>.from(data['completedDates'] ?? []),
      parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
    );
  }

  factory ChallengeGoalModel.fromEntity(ChallengeGoal goal) {
    return ChallengeGoalModel(
      name: goal.name,
      templateId: goal.templateId,
      targetFrequency: goal.targetFrequency,
      description: goal.description,
      goalType: goal.goalType,
      completedDates: goal.completedDates,
      parameters: goal.parameters,
    );
  }

  ChallengeGoal toEntity() {
    return ChallengeGoal(
      name: name,
      templateId: templateId,
      targetFrequency: targetFrequency,
      description: description,
      goalType: goalType,
      completedDates: completedDates,
      parameters: parameters,
    );
  }
}