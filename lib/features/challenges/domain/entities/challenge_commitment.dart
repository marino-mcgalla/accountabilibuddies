import 'package:equatable/equatable.dart';

/// Represents a commitment status for a challenge
enum CommitmentStatus {
  /// Member has not yet committed to the challenge
  pending,
  /// Member has committed with goals and wager
  committed,
  /// Member has opted out of this challenge
  optedOut,
}

/// Represents an individual member's commitment to a challenge
class ChallengeCommitment extends Equatable {
  const ChallengeCommitment({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.goalConfigs = const [],
    this.wagerAmount,
    this.wagerCurrency = 'USD',
    this.commitmentDate,
    this.metadata = const {},
  });

  /// Unique identifier for the commitment
  final String id;
  
  /// ID of the challenge this commitment belongs to
  final String challengeId;
  
  /// User ID of the committing member
  final String userId;
  
  /// Display name of the committing member
  final String userName;
  
  /// Current status of the commitment
  final CommitmentStatus status;
  
  /// When the commitment was created
  final DateTime createdAt;
  
  /// When the commitment was last updated
  final DateTime updatedAt;
  
  /// List of goal configurations for this commitment
  final List<GoalCommitment> goalConfigs;
  
  /// Amount the user is wagering (optional - can be 0)
  final double? wagerAmount;
  
  /// Currency for the wager
  final String wagerCurrency;
  
  /// When the user committed (if status is committed)
  final DateTime? commitmentDate;
  
  /// Additional metadata for the commitment
  final Map<String, dynamic> metadata;

  /// Display name for commitment status
  String get statusDisplay {
    switch (status) {
      case CommitmentStatus.pending:
        return 'Pending';
      case CommitmentStatus.committed:
        return 'Committed';
      case CommitmentStatus.optedOut:
        return 'Opted Out';
    }
  }

  /// Check if the commitment is finalized
  bool get isCommitted => status == CommitmentStatus.committed;

  /// Check if the user has opted out
  bool get hasOptedOut => status == CommitmentStatus.optedOut;

  /// Check if the commitment is still pending
  bool get isPending => status == CommitmentStatus.pending;

  /// Get the formatted wager amount
  String get formattedWager {
    if (wagerAmount == null || wagerAmount! <= 0) {
      return 'No wager';
    }
    return '\$${wagerAmount!.toStringAsFixed(2)}';
  }

  /// Get total number of goals committed to
  int get totalGoals => goalConfigs.length;

  /// Get total weekly frequency across all goals
  int get totalWeeklyFrequency => goalConfigs.fold(0, (sum, goal) => sum + goal.weeklyFrequency);

  ChallengeCommitment copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? userName,
    CommitmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GoalCommitment>? goalConfigs,
    double? wagerAmount,
    String? wagerCurrency,
    DateTime? commitmentDate,
    Map<String, dynamic>? metadata,
  }) {
    return ChallengeCommitment(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      goalConfigs: goalConfigs ?? this.goalConfigs,
      wagerAmount: wagerAmount ?? this.wagerAmount,
      wagerCurrency: wagerCurrency ?? this.wagerCurrency,
      commitmentDate: commitmentDate ?? this.commitmentDate,
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
        goalConfigs,
        wagerAmount,
        wagerCurrency,
        commitmentDate,
        metadata,
      ];

  @override
  String toString() => 'ChallengeCommitment(id: $id, userId: $userId, status: $status)';
}

/// Represents a specific goal commitment within a challenge
class GoalCommitment extends Equatable {
  const GoalCommitment({
    required this.goalId,
    required this.goalName,
    required this.weeklyFrequency,
    required this.parameters,
    this.description,
  });

  /// ID of the goal template
  final String goalId;
  
  /// Name of the goal
  final String goalName;
  
  /// How many times per week this goal should be completed
  final int weeklyFrequency;
  
  /// Goal-specific parameters (duration, count, etc.)
  final Map<String, dynamic> parameters;
  
  /// Optional description or notes
  final String? description;

  /// Display the frequency in a user-friendly way
  String get frequencyDisplay {
    if (weeklyFrequency == 1) {
      return 'Once per week';
    } else if (weeklyFrequency == 7) {
      return 'Daily';
    } else {
      return '$weeklyFrequency times per week';
    }
  }

  /// Format parameters for display
  String formatParameters() {
    if (parameters.isEmpty) return '';
    
    final entries = parameters.entries.map((e) {
      final key = e.key.replaceAll('_', ' ').toLowerCase();
      final value = e.value.toString();
      return '$key: $value';
    }).join(', ');
    
    return '($entries)';
  }

  GoalCommitment copyWith({
    String? goalId,
    String? goalName,
    int? weeklyFrequency,
    Map<String, dynamic>? parameters,
    String? description,
  }) {
    return GoalCommitment(
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
      parameters: parameters ?? this.parameters,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        goalId,
        goalName,
        weeklyFrequency,
        parameters,
        description,
      ];

  @override
  String toString() => 'GoalCommitment(goalId: $goalId, frequency: $weeklyFrequency)';
}