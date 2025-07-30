import 'package:equatable/equatable.dart';
import 'challenge_goal.dart';

/// Represents a user's participation status in a challenge
enum ParticipationStatus {
  /// Member has not yet locked in their goals
  notLockedIn,
  /// Member has locked in goals and wager
  lockedIn,
  /// Member has opted out of this challenge
  optedOut,
  /// Member was removed from challenge by party leader
  removed,
}

/// Represents an individual member's participation in a challenge
class UserChallengeParticipation extends Equatable {
  const UserChallengeParticipation({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.goals = const {},
    this.wagerAmount,
    this.wagerCurrency = 'USD',
    this.lockedInDate,
    this.metadata = const {},
  });

  /// Unique identifier for the participation
  final String id;
  
  /// ID of the challenge this participation belongs to
  final String challengeId;
  
  /// User ID of the participating member
  final String userId;
  
  /// Display name of the participating member
  final String userName;
  
  /// Current status of the participation
  final ParticipationStatus status;
  
  /// When the participation was created
  final DateTime createdAt;
  
  /// When the participation was last updated
  final DateTime updatedAt;
  
  /// Map of goals that the user has committed to (goalId -> ChallengeGoal)
  final Map<String, ChallengeGoal> goals;
  
  /// Amount the user is wagering (optional - can be 0)
  final double? wagerAmount;
  
  /// Currency for the wager
  final String wagerCurrency;
  
  /// When the user locked in their goals (if status is lockedIn)
  final DateTime? lockedInDate;
  
  /// Additional metadata for the participation
  final Map<String, dynamic> metadata;

  /// Display name for participation status
  String get statusDisplay {
    switch (status) {
      case ParticipationStatus.notLockedIn:
        return 'Not Locked In';
      case ParticipationStatus.lockedIn:
        return 'Locked In';
      case ParticipationStatus.optedOut:
        return 'Opted Out';
      case ParticipationStatus.removed:
        return 'Removed';
    }
  }

  /// Check if the user has locked in their goals
  bool get isLockedIn => status == ParticipationStatus.lockedIn;

  /// Check if the user has opted out
  bool get hasOptedOut => status == ParticipationStatus.optedOut;

  /// Check if the user has not yet locked in
  bool get isNotLockedIn => status == ParticipationStatus.notLockedIn;

  /// Check if the user was removed by party leader
  bool get wasRemoved => status == ParticipationStatus.removed;

  /// Get the formatted wager amount
  String get formattedWager {
    if (wagerAmount == null || wagerAmount! <= 0) {
      return 'No wager';
    }
    return '\$${wagerAmount!.toStringAsFixed(2)}';
  }

  /// Get total number of goals locked in
  int get totalGoals => goals.length;

  /// Get overall completion rate across all goals
  double get overallCompletionRate {
    if (goals.isEmpty) return 0.0;
    final totalRate = goals.values.fold<double>(0.0, (sum, goal) => sum + goal.completionRate);
    return totalRate / goals.length;
  }

  /// Get total completions across all goals
  int get totalCompletions {
    return goals.values.fold<int>(0, (sum, goal) => sum + goal.completedDates.length);
  }

  /// Get total target completions across all goals
  int get totalTargetCompletions {
    return goals.values.fold<int>(0, (sum, goal) => sum + goal.targetFrequency);
  }

  /// Check if all goals are fully completed
  bool get areAllGoalsCompleted {
    return goals.isNotEmpty && goals.values.every((goal) => goal.isCompleted);
  }

  /// Add or update a goal in this participation
  UserChallengeParticipation addGoal(String goalId, ChallengeGoal goal) {
    final updatedGoals = Map<String, ChallengeGoal>.from(goals);
    updatedGoals[goalId] = goal;
    return copyWith(goals: updatedGoals, updatedAt: DateTime.now());
  }

  /// Remove a goal from this participation
  UserChallengeParticipation removeGoal(String goalId) {
    final updatedGoals = Map<String, ChallengeGoal>.from(goals);
    updatedGoals.remove(goalId);
    return copyWith(goals: updatedGoals, updatedAt: DateTime.now());
  }

  /// Add a completion to a specific goal
  UserChallengeParticipation addGoalCompletion(String goalId, String date) {
    final goal = goals[goalId];
    if (goal == null) return this;
    
    final updatedGoal = goal.addCompletion(date);
    return addGoal(goalId, updatedGoal);
  }

  /// Remove a completion from a specific goal
  UserChallengeParticipation removeGoalCompletion(String goalId, String date) {
    final goal = goals[goalId];
    if (goal == null) return this;
    
    final updatedGoal = goal.removeCompletion(date);
    return addGoal(goalId, updatedGoal);
  }

  UserChallengeParticipation copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? userName,
    ParticipationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, ChallengeGoal>? goals,
    double? wagerAmount,
    String? wagerCurrency,
    DateTime? lockedInDate,
    Map<String, dynamic>? metadata,
  }) {
    return UserChallengeParticipation(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      goals: goals ?? this.goals,
      wagerAmount: wagerAmount ?? this.wagerAmount,
      wagerCurrency: wagerCurrency ?? this.wagerCurrency,
      lockedInDate: lockedInDate ?? this.lockedInDate,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        challengeId,
        userId,
        userName,
        status,
        createdAt,
        updatedAt,
        goals,
        wagerAmount,
        wagerCurrency,
        lockedInDate,
        metadata,
      ];

  @override
  String toString() => 'UserChallengeParticipation(id: $id, userId: $userId, status: $status)';
}

