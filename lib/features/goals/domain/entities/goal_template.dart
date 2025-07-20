import 'package:equatable/equatable.dart';

enum GoalTemplateStatus {
  active,    // Available for use in challenges
  archived,  // Hidden but stats preserved
}

enum GoalCategory {
  health,
  fitness,
  learning,
  habits,
  career,
  personal,
  other,
}

enum GoalType {
  daily,    // Max 1 completion per day (max 7 per week)
  total,    // Multiple completions per day allowed
}

class GoalTemplate extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final GoalCategory category;
  final GoalType goalType;
  final int? plannedFrequency;  // Suggested frequency for planning (not enforced)
  final List<String> tags;
  final GoalTemplateStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Historical aggregated stats from all instances
  final int totalInstances;        // How many times this template was used
  final int totalCompletions;      // Total completions across all instances
  final int totalTargeted;         // Total targeted across all instances
  final double averageCompletionRate; // Overall completion rate
  final DateTime? lastUsedAt;      // When last instance was created
  final Map<String, dynamic> metadata;

  const GoalTemplate({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.goalType,
    this.plannedFrequency,
    required this.tags,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.totalInstances = 0,
    this.totalCompletions = 0,
    this.totalTargeted = 0,
    this.averageCompletionRate = 0.0,
    this.lastUsedAt,
    required this.metadata,
  });

  GoalTemplate copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    GoalCategory? category,
    GoalType? goalType,
    int? plannedFrequency,
    List<String>? tags,
    GoalTemplateStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalInstances,
    int? totalCompletions,
    int? totalTargeted,
    double? averageCompletionRate,
    DateTime? lastUsedAt,
    Map<String, dynamic>? metadata,
  }) {
    return GoalTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      goalType: goalType ?? this.goalType,
      plannedFrequency: plannedFrequency ?? this.plannedFrequency,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalInstances: totalInstances ?? this.totalInstances,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      totalTargeted: totalTargeted ?? this.totalTargeted,
      averageCompletionRate: averageCompletionRate ?? this.averageCompletionRate,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Calculate completion rate from current stats
  double get completionRate {
    if (totalTargeted == 0) return 0.0;
    return (totalCompletions / totalTargeted).clamp(0.0, 1.0);
  }

  /// Check if template is available for use
  bool get isActive => status == GoalTemplateStatus.active;

  /// Check if template is archived
  bool get isArchived => status == GoalTemplateStatus.archived;

  /// Display name for goal type
  String get goalTypeDisplay {
    switch (goalType) {
      case GoalType.daily:
        return 'Daily';
      case GoalType.total:
        return 'Total';
    }
  }

  /// Display name for category
  String get categoryDisplay {
    switch (category) {
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.learning:
        return 'Learning';
      case GoalCategory.habits:
        return 'Habits';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.other:
        return 'Other';
    }
  }

  /// Display name for status
  String get statusDisplay {
    switch (status) {
      case GoalTemplateStatus.active:
        return 'Active';
      case GoalTemplateStatus.archived:
        return 'Archived';
    }
  }

  /// Update stats when an instance is completed
  GoalTemplate updateStatsFromInstance({
    required int targetFrequency,
    required int completionsAchieved,
    required DateTime instanceCreatedAt,
  }) {
    final newTotalInstances = totalInstances + 1;
    final newTotalCompletions = totalCompletions + completionsAchieved;
    final newTotalTargeted = totalTargeted + targetFrequency;
    final newAverageCompletionRate = newTotalTargeted > 0 
        ? (newTotalCompletions / newTotalTargeted).clamp(0.0, 1.0)
        : 0.0;

    return copyWith(
      totalInstances: newTotalInstances,
      totalCompletions: newTotalCompletions,
      totalTargeted: newTotalTargeted,
      averageCompletionRate: newAverageCompletionRate,
      lastUsedAt: instanceCreatedAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        category,
        goalType,
        plannedFrequency,
        tags,
        status,
        createdAt,
        updatedAt,
        totalInstances,
        totalCompletions,
        totalTargeted,
        averageCompletionRate,
        lastUsedAt,
        metadata,
      ];
}