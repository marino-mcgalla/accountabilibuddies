import 'package:equatable/equatable.dart';

/// Represents the status of a challenge
enum ChallengeStatus {
  /// Challenge created, waiting for member commitments
  pending,
  /// All members committed, challenge is active
  active,
  /// Challenge week completed, calculating results
  settling,
  /// Challenge completed and settled
  completed,
  /// Challenge was cancelled
  cancelled,
}

/// Represents a wagering period/challenge within a party
class Challenge extends Equatable {
  const Challenge({
    required this.id,
    required this.partyId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.commitmentDeadline,
    this.metadata = const {},
  });

  /// Unique identifier for the challenge
  final String id;
  
  /// ID of the party this challenge belongs to
  final String partyId;
  
  /// Challenge name (e.g., "Week of Jan 15-21, 2024")
  final String name;
  
  /// Optional description or theme for the challenge
  final String description;
  
  /// When the challenge period starts (typically Monday)
  final DateTime startDate;
  
  /// When the challenge period ends (typically Sunday)
  final DateTime endDate;
  
  /// Current status of the challenge
  final ChallengeStatus status;
  
  /// User ID of who created/started this challenge
  final String createdBy;
  
  /// When the challenge was created
  final DateTime createdAt;
  
  /// When the challenge was last updated
  final DateTime updatedAt;
  
  /// Deadline for members to commit to the challenge
  final DateTime? commitmentDeadline;
  
  /// Additional metadata for the challenge
  final Map<String, dynamic> metadata;

  /// Display name for challenge status
  String get statusDisplay {
    switch (status) {
      case ChallengeStatus.pending:
        return 'Waiting for Commitments';
      case ChallengeStatus.active:
        return 'Active';
      case ChallengeStatus.settling:
        return 'Calculating Results';
      case ChallengeStatus.completed:
        return 'Completed';
      case ChallengeStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if the challenge is currently accepting commitments
  bool get isAcceptingCommitments => 
      status == ChallengeStatus.pending && 
      (commitmentDeadline == null || DateTime.now().isBefore(commitmentDeadline!));

  /// Check if the challenge is currently active
  bool get isActive => status == ChallengeStatus.active;

  /// Check if the challenge has ended
  bool get hasEnded => 
      status == ChallengeStatus.completed || 
      status == ChallengeStatus.cancelled ||
      DateTime.now().isAfter(endDate);

  /// Duration of the challenge in days
  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Days remaining in the challenge (if active)
  int get daysRemaining {
    if (!isActive) return 0;
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining + 1;
  }

  /// Progress percentage (0.0 to 1.0) based on time elapsed
  double get timeProgress {
    if (!isActive) return status == ChallengeStatus.completed ? 1.0 : 0.0;
    
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    
    final totalDuration = endDate.difference(startDate).inMilliseconds;
    final elapsed = now.difference(startDate).inMilliseconds;
    
    return elapsed / totalDuration;
  }

  Challenge copyWith({
    String? id,
    String? partyId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? commitmentDeadline,
    Map<String, dynamic>? metadata,
  }) {
    return Challenge(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commitmentDeadline: commitmentDeadline ?? this.commitmentDeadline,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partyId,
        name,
        description,
        startDate,
        endDate,
        status,
        createdBy,
        createdAt,
        updatedAt,
        commitmentDeadline,
        metadata,
      ];

  @override
  String toString() => 'Challenge(id: $id, name: $name, status: $status)';
}