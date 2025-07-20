import 'package:equatable/equatable.dart';

enum GoalInstanceStatus {
  active,     // Currently in progress
  completed,  // Successfully completed
  failed,     // Challenge ended without completion
}

class GoalInstance extends Equatable {
  final String id;
  final String templateId;      // References GoalTemplate
  final String userId;
  final String challengeId;     // Which challenge/week this belongs to
  final int targetFrequency;    // This week's target (set when instance is created)
  final int currentCount;       // Current progress
  final GoalInstanceStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;  // When target was reached
  final List<String> partyIds;  // If part of multi-party challenge
  
  // Week-specific tracking
  final List<DateTime> completionDates; // When each completion happened
  final Map<String, dynamic> weeklyMetadata;

  const GoalInstance({
    required this.id,
    required this.templateId,
    required this.userId,
    required this.challengeId,
    required this.targetFrequency,
    this.currentCount = 0,
    this.status = GoalInstanceStatus.active,
    required this.createdAt,
    this.completedAt,
    this.partyIds = const [],
    this.completionDates = const [],
    this.weeklyMetadata = const {},
  });

  GoalInstance copyWith({
    String? id,
    String? templateId,
    String? userId,
    String? challengeId,
    int? targetFrequency,
    int? currentCount,
    GoalInstanceStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? partyIds,
    List<DateTime>? completionDates,
    Map<String, dynamic>? weeklyMetadata,
  }) {
    return GoalInstance(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      partyIds: partyIds ?? this.partyIds,
      completionDates: completionDates ?? this.completionDates,
      weeklyMetadata: weeklyMetadata ?? this.weeklyMetadata,
    );
  }

  /// Calculate progress as a percentage
  double get progress {
    if (targetFrequency == 0) return 0.0;
    return (currentCount / targetFrequency).clamp(0.0, 1.0);
  }

  /// Check if target has been reached
  bool get isCompleted => currentCount >= targetFrequency;

  /// Check if instance is still active
  bool get isActive => status == GoalInstanceStatus.active;

  /// Check if instance failed to complete
  bool get isFailed => status == GoalInstanceStatus.failed;

  /// Display name for status
  String get statusDisplay {
    switch (status) {
      case GoalInstanceStatus.active:
        return 'Active';
      case GoalInstanceStatus.completed:
        return 'Completed';
      case GoalInstanceStatus.failed:
        return 'Failed';
    }
  }

  /// Add a completion to this instance
  GoalInstance addCompletion({DateTime? completionDate}) {
    final now = completionDate ?? DateTime.now();
    final newCompletionDates = [...completionDates, now];
    final newCurrentCount = currentCount + 1;
    final newStatus = newCurrentCount >= targetFrequency 
        ? GoalInstanceStatus.completed 
        : status;
    final newCompletedAt = newStatus == GoalInstanceStatus.completed 
        ? now 
        : completedAt;

    return copyWith(
      currentCount: newCurrentCount,
      completionDates: newCompletionDates,
      status: newStatus,
      completedAt: newCompletedAt,
    );
  }

  /// Remove the most recent completion
  GoalInstance removeLastCompletion() {
    if (completionDates.isEmpty) return this;

    final newCompletionDates = completionDates.sublist(0, completionDates.length - 1);
    final newCurrentCount = (currentCount - 1).clamp(0, targetFrequency);
    final newStatus = newCurrentCount >= targetFrequency 
        ? GoalInstanceStatus.completed 
        : GoalInstanceStatus.active;
    final newCompletedAt = newStatus == GoalInstanceStatus.completed 
        ? completedAt 
        : null;

    return copyWith(
      currentCount: newCurrentCount,
      completionDates: newCompletionDates,
      status: newStatus,
      completedAt: newCompletedAt,
    );
  }

  /// Mark instance as failed (when challenge ends without completion)
  GoalInstance markAsFailed() {
    return copyWith(
      status: GoalInstanceStatus.failed,
    );
  }

  /// Get completion rate as percentage string
  String get progressPercentage {
    return '${(progress * 100).toInt()}%';
  }

  /// Get completion count display
  String get progressDisplay {
    return '$currentCount / $targetFrequency';
  }

  /// Check if completion can be added today (for daily goals)
  bool canCompleteToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // Count completions today
    final todayCompletions = completionDates.where((date) {
      return date.isAfter(todayStart) && date.isBefore(todayEnd);
    }).length;
    
    // For daily goals, only 1 completion per day allowed
    // For total goals, unlimited completions per day
    return todayCompletions == 0; // This will be refined based on goal type
  }

  @override
  List<Object?> get props => [
        id,
        templateId,
        userId,
        challengeId,
        targetFrequency,
        currentCount,
        status,
        createdAt,
        completedAt,
        partyIds,
        completionDates,
        weeklyMetadata,
      ];
}