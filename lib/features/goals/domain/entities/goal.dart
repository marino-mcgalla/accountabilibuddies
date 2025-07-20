import 'package:equatable/equatable.dart';

enum GoalType {
  daily,    // Max 1 completion per day (max 7 per week)
  total,    // Multiple completions per day allowed
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

enum GoalStatus {
  active,
  completed,
  paused,
  cancelled,
}

class Goal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final GoalCategory category;
  final GoalType goalType;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final int targetFrequency;
  final int currentCount;
  final List<String> tags;
  final List<String> partyIds;
  final Map<String, dynamic> metadata;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.goalType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.dueDate,
    required this.targetFrequency,
    required this.currentCount,
    required this.tags,
    this.partyIds = const [],
    required this.metadata,
  });

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    GoalCategory? category,
    GoalType? goalType,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? dueDate,
    int? targetFrequency,
    int? currentCount,
    List<String>? tags,
    List<String>? partyIds,
    Map<String, dynamic>? metadata,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      goalType: goalType ?? this.goalType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      currentCount: currentCount ?? this.currentCount,
      tags: tags ?? this.tags,
      partyIds: partyIds ?? this.partyIds,
      metadata: metadata ?? this.metadata,
    );
  }

  double get progress {
    if (targetFrequency == 0) return 0.0;
    return (currentCount / targetFrequency).clamp(0.0, 1.0);
  }

  bool get isCompleted => status == GoalStatus.completed;
  
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  String get goalTypeDisplay {
    switch (goalType) {
      case GoalType.daily:
        return 'Daily';
      case GoalType.total:
        return 'Total';
    }
  }

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

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        category,
        goalType,
        status,
        createdAt,
        updatedAt,
        completedAt,
        dueDate,
        targetFrequency,
        currentCount,
        tags,
        partyIds,
        metadata,
      ];
}