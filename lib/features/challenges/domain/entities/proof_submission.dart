import 'package:equatable/equatable.dart';

/// Represents the status of a proof submission
enum ProofStatus {
  /// Proof submitted, waiting for approval
  pending,
  /// Proof approved by another member
  approved,
  /// Proof disputed and flagged for group discussion
  disputed,
  /// Proof rejected by group vote
  rejected,
}

/// Represents the type of proof content
enum ProofContentType {
  /// Text-based proof description
  text,
  /// Image-based proof with photos
  image,
}

/// Represents a single approval/vote on a proof submission for a specific challenge
class ProofApproval extends Equatable {
  const ProofApproval({
    required this.userId,
    required this.userName,
    required this.approved,
    required this.timestamp,
    this.comment,
  });

  /// User ID who made the approval/rejection
  final String userId;
  
  /// Display name of the user
  final String userName;
  
  /// Whether they approved (true) or rejected (false)
  final bool approved;
  
  /// When the approval was made
  final DateTime timestamp;
  
  /// Optional comment with the approval
  final String? comment;

  ProofApproval copyWith({
    String? userId,
    String? userName,
    bool? approved,
    DateTime? timestamp,
    String? comment,
  }) {
    return ProofApproval(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      approved: approved ?? this.approved,
      timestamp: timestamp ?? this.timestamp,
      comment: comment ?? this.comment,
    );
  }

  @override
  List<Object?> get props => [userId, userName, approved, timestamp, comment];
}

/// Represents the state of a proof for a specific goal within a specific challenge
class ChallengeGoalProofState extends Equatable {
  const ChallengeGoalProofState({
    required this.challengeId,
    required this.participationId,
    required this.goalTemplateId,
    required this.status,
    this.approvals = const [],
    this.viewedBy = const [],
  });

  /// ID of the challenge this proof state belongs to
  final String challengeId;
  
  /// ID of the user's participation document for this challenge
  final String participationId;
  
  /// ID of the goal template this proof state is for
  final String goalTemplateId;
  
  /// Current approval status for this specific challenge/goal combination
  final ProofStatus status;
  
  /// List of approvals/rejections from other members in this challenge
  final List<ProofApproval> approvals;
  
  /// List of user IDs who have viewed this proof in this challenge context
  final List<String> viewedBy;

  /// Check if proof is approved for this challenge/goal
  bool get isApproved => status == ProofStatus.approved;

  /// Check if proof is pending for this challenge/goal
  bool get isPending => status == ProofStatus.pending;

  /// Get the user who approved this proof (if any)
  ProofApproval? get approver {
    return approvals.where((a) => a.approved).firstOrNull;
  }

  /// Get count of positive votes
  int get approvalCount => approvals.where((a) => a.approved).length;

  /// Get count of negative votes
  int get rejectionCount => approvals.where((a) => !a.approved).length;

  /// Check if proof can be approved by given user
  bool canApproveBy(String userId) {
    // Can't approve if already voted
    if (approvals.any((a) => a.userId == userId)) return false;
    
    // Can only approve pending or disputed proofs
    return status == ProofStatus.pending || status == ProofStatus.disputed;
  }

  ChallengeGoalProofState copyWith({
    String? challengeId,
    String? participationId,
    String? goalTemplateId,
    ProofStatus? status,
    List<ProofApproval>? approvals,
    List<String>? viewedBy,
  }) {
    return ChallengeGoalProofState(
      challengeId: challengeId ?? this.challengeId,
      participationId: participationId ?? this.participationId,
      goalTemplateId: goalTemplateId ?? this.goalTemplateId,
      status: status ?? this.status,
      approvals: approvals ?? this.approvals,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }

  @override
  List<Object?> get props => [challengeId, participationId, goalTemplateId, status, approvals, viewedBy];
}

/// Represents a proof submission that can apply to multiple goals across multiple challenges
class ProofSubmission extends Equatable {
  const ProofSubmission({
    required this.id,
    required this.userId,
    required this.userName,
    required this.submissionDate,
    required this.createdAt,
    required this.updatedAt,
    required this.challengeGoalStates,
    this.contentType = ProofContentType.text,
    this.imageUrls = const [],
    this.description,
    this.metadata = const {},
  });

  /// Unique identifier for the proof submission
  final String id;
  
  /// User ID who submitted the proof
  final String userId;
  
  /// Display name of the user who submitted
  final String userName;
  
  /// Date this proof submission is for (when the goal was completed)
  final DateTime submissionDate;
  
  /// When the proof was submitted
  final DateTime createdAt;
  
  /// When the proof was last updated
  final DateTime updatedAt;
  
  /// Type of proof content (text or image)
  final ProofContentType contentType;
  
  /// List of image URLs for the proof photos
  final List<String> imageUrls;
  
  /// Text description (used for text proofs or photo captions)
  final String? description;
  
  /// Map of challenge/goal states this proof applies to
  /// Key format: "challengeId:goalTemplateId"
  final Map<String, ChallengeGoalProofState> challengeGoalStates;
  
  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// Get all unique challenge IDs this proof applies to
  Set<String> get challengeIds {
    return challengeGoalStates.values.map((state) => state.challengeId).toSet();
  }

  /// Get all unique goal template IDs this proof applies to
  Set<String> get goalTemplateIds {
    return challengeGoalStates.values.map((state) => state.goalTemplateId).toSet();
  }

  /// Get the proof state for a specific challenge and goal
  ChallengeGoalProofState? getStateFor(String challengeId, String goalTemplateId) {
    final key = '$challengeId:$goalTemplateId';
    return challengeGoalStates[key];
  }

  /// Check if proof is approved for a specific challenge/goal combination
  bool isApprovedFor(String challengeId, String goalTemplateId) {
    final state = getStateFor(challengeId, goalTemplateId);
    return state?.isApproved ?? false;
  }

  /// Check if proof is pending for a specific challenge/goal combination
  bool isPendingFor(String challengeId, String goalTemplateId) {
    final state = getStateFor(challengeId, goalTemplateId);
    return state?.isPending ?? false;
  }

  /// Check if proof can be approved by given user for specific challenge/goal
  bool canApproveBy(String userId, String challengeId, String goalTemplateId) {
    // Can't approve own proof
    if (this.userId == userId) return false;
    
    final state = getStateFor(challengeId, goalTemplateId);
    return state?.canApproveBy(userId) ?? false;
  }

  /// Get overall status display (shows summary across all challenges)
  String get statusDisplay {
    if (challengeGoalStates.isEmpty) return 'No Goals';
    
    final approvedCount = challengeGoalStates.values.where((s) => s.isApproved).length;
    final totalCount = challengeGoalStates.length;
    
    if (approvedCount == totalCount) {
      return 'Approved ($approvedCount/$totalCount)';
    } else if (approvedCount == 0) {
      return 'Pending ($approvedCount/$totalCount)';
    } else {
      return 'Partial ($approvedCount/$totalCount)';
    }
  }

  /// Check if all challenge/goal combinations are approved
  bool get isFullyApproved {
    return challengeGoalStates.values.every((state) => state.isApproved);
  }

  /// Check if any challenge/goal combination is approved
  bool get hasAnyApproval {
    return challengeGoalStates.values.any((state) => state.isApproved);
  }

  // Backward compatibility methods for existing codebase
  
  /// Get the first challenge ID (for backward compatibility)
  String get challengeId {
    if (challengeGoalStates.isEmpty) return '';
    return challengeGoalStates.values.first.challengeId;
  }

  /// Get the first participation ID (for backward compatibility)
  String get participationId {
    if (challengeGoalStates.isEmpty) return '';
    return challengeGoalStates.values.first.participationId;
  }

  /// Get the first goal template ID (for backward compatibility)
  String get goalTemplateId {
    if (challengeGoalStates.isEmpty) return '';
    return challengeGoalStates.values.first.goalTemplateId;
  }

  /// Get the status of the first challenge/goal (for backward compatibility)
  ProofStatus get status {
    if (challengeGoalStates.isEmpty) return ProofStatus.pending;
    return challengeGoalStates.values.first.status;
  }

  /// Check if the first challenge/goal is approved (for backward compatibility)
  bool get isApproved {
    if (challengeGoalStates.isEmpty) return false;
    return challengeGoalStates.values.first.isApproved;
  }

  /// Check if the first challenge/goal is pending (for backward compatibility)
  bool get isPending {
    if (challengeGoalStates.isEmpty) return true;
    return challengeGoalStates.values.first.isPending;
  }

  /// Check if the first challenge/goal is disputed (for backward compatibility)
  bool get isDisputed {
    if (challengeGoalStates.isEmpty) return false;
    return challengeGoalStates.values.first.status == ProofStatus.disputed;
  }

  /// Check if the first challenge/goal is rejected (for backward compatibility)
  bool get isRejected {
    if (challengeGoalStates.isEmpty) return false;
    return challengeGoalStates.values.first.status == ProofStatus.rejected;
  }

  /// Get approvals for the first challenge/goal (for backward compatibility)
  List<ProofApproval> get approvals {
    if (challengeGoalStates.isEmpty) return [];
    return challengeGoalStates.values.first.approvals;
  }

  /// Get viewed by list for the first challenge/goal (for backward compatibility)
  List<String> get viewedBy {
    if (challengeGoalStates.isEmpty) return [];
    return challengeGoalStates.values.first.viewedBy;
  }

  /// Check if viewed by user for the first challenge/goal (for backward compatibility)
  bool hasBeenViewedBy(String userId) {
    // Use first challenge/goal for backward compatibility
    if (challengeGoalStates.isEmpty) return false;
    return challengeGoalStates.values.first.viewedBy.contains(userId);
  }

  /// Get the user who approved the first challenge/goal (for backward compatibility)
  ProofApproval? get approver {
    if (challengeGoalStates.isEmpty) return null;
    return challengeGoalStates.values.first.approver;
  }

  /// Get count of positive votes for the first challenge/goal (for backward compatibility)
  int get approvalCount {
    if (challengeGoalStates.isEmpty) return 0;
    return challengeGoalStates.values.first.approvalCount;
  }

  /// Get count of negative votes for the first challenge/goal (for backward compatibility)
  int get rejectionCount {
    if (challengeGoalStates.isEmpty) return 0;
    return challengeGoalStates.values.first.rejectionCount;
  }

  /// Check if proof can be approved by given user for the first challenge/goal (for backward compatibility)
  bool canApproveByUser(String userId) {
    // Can't approve own proof
    if (this.userId == userId) return false;
    
    // Use first challenge/goal for backward compatibility
    if (challengeGoalStates.isEmpty) return false;
    return challengeGoalStates.values.first.canApproveBy(userId);
  }

  /// Check if user has already voted on the first challenge/goal (for backward compatibility)
  bool hasUserVoted(String userId) {
    if (challengeGoalStates.isEmpty) return false;
    return challengeGoalStates.values.first.approvals.any((a) => a.userId == userId);
  }

  /// Get user's vote for the first challenge/goal (for backward compatibility)
  ProofApproval? getUserVote(String userId) {
    if (challengeGoalStates.isEmpty) return null;
    return challengeGoalStates.values.first.approvals.where((a) => a.userId == userId).firstOrNull;
  }

  /// Add approval to the first challenge/goal (for backward compatibility)
  ProofSubmission addApproval(ProofApproval approval) {
    if (challengeGoalStates.isEmpty) return this;
    
    final firstKey = challengeGoalStates.keys.first;
    final parts = firstKey.split(':');
    
    return addApprovalFor(parts[0], parts[1], approval);
  }

  /// Mark as viewed by user for the first challenge/goal (for backward compatibility)
  ProofSubmission markAsViewedBy(String userId) {
    // Use first challenge/goal for backward compatibility
    if (challengeGoalStates.isEmpty) return this;
    
    final firstKey = challengeGoalStates.keys.first;
    final parts = firstKey.split(':');
    
    return markAsViewedByFor(userId, parts[0], parts[1]);
  }

  /// Helper method to avoid naming conflicts
  ProofSubmission markAsViewedByFor(String userId, String challengeId, String goalTemplateId) {
    final key = '$challengeId:$goalTemplateId';
    final currentState = challengeGoalStates[key];
    
    if (currentState == null || currentState.viewedBy.contains(userId)) return this;
    
    final updatedState = currentState.copyWith(
      viewedBy: [...currentState.viewedBy, userId],
    );
    
    final updatedStates = Map<String, ChallengeGoalProofState>.from(challengeGoalStates);
    updatedStates[key] = updatedState;
    
    return copyWith(challengeGoalStates: updatedStates);
  }

  /// Add an approval/rejection for a specific challenge/goal combination
  ProofSubmission addApprovalFor(String challengeId, String goalTemplateId, ProofApproval approval) {
    final key = '$challengeId:$goalTemplateId';
    final currentState = challengeGoalStates[key];
    
    if (currentState == null) return this;
    
    final newApprovals = [...currentState.approvals, approval];
    
    // For now, first approval approves the proof for this challenge/goal
    ProofStatus newStatus = currentState.status;
    if (currentState.status == ProofStatus.pending && approval.approved) {
      newStatus = ProofStatus.approved;
    }
    
    final updatedState = currentState.copyWith(
      approvals: newApprovals,
      status: newStatus,
    );
    
    final updatedStates = Map<String, ChallengeGoalProofState>.from(challengeGoalStates);
    updatedStates[key] = updatedState;
    
    return copyWith(
      challengeGoalStates: updatedStates,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark proof as disputed for a specific challenge/goal
  ProofSubmission markAsDisputedFor(String challengeId, String goalTemplateId) {
    final key = '$challengeId:$goalTemplateId';
    final currentState = challengeGoalStates[key];
    
    if (currentState == null) return this;
    
    final updatedState = currentState.copyWith(status: ProofStatus.disputed);
    
    final updatedStates = Map<String, ChallengeGoalProofState>.from(challengeGoalStates);
    updatedStates[key] = updatedState;
    
    return copyWith(
      challengeGoalStates: updatedStates,
      updatedAt: DateTime.now(),
    );
  }

  /// Add a new challenge/goal combination to this proof
  ProofSubmission addChallengeGoalState(ChallengeGoalProofState state) {
    final key = '${state.challengeId}:${state.goalTemplateId}';
    final updatedStates = Map<String, ChallengeGoalProofState>.from(challengeGoalStates);
    updatedStates[key] = state;
    
    return copyWith(
      challengeGoalStates: updatedStates,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if this submission is for today
  bool get isForToday {
    final today = DateTime.now();
    final submissionDay = DateTime(submissionDate.year, submissionDate.month, submissionDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return submissionDay.isAtSameMomentAs(todayDay);
  }

  /// Check if submission date is within the challenge week
  bool isWithinChallengeWeek(DateTime challengeStart, DateTime challengeEnd) {
    return submissionDate.isAfter(challengeStart.subtract(const Duration(days: 1))) &&
           submissionDate.isBefore(challengeEnd.add(const Duration(days: 1)));
  }

  /// Check if this proof has been viewed by the given user for a specific challenge/goal
  bool hasBeenViewedByFor(String userId, String challengeId, String goalTemplateId) {
    final state = getStateFor(challengeId, goalTemplateId);
    return state?.viewedBy.contains(userId) ?? false;
  }
  
  /// Get the primary content for display (description for text, first image for photos)
  String get primaryContent {
    switch (contentType) {
      case ProofContentType.text:
        return description ?? 'Text proof submitted';
      case ProofContentType.image:
        return imageUrls.isNotEmpty ? imageUrls.first : 'Image proof submitted';
    }
  }
  
  /// Check if this is a text proof
  bool get isTextProof => contentType == ProofContentType.text;
  
  /// Check if this is an image proof
  bool get isImageProof => contentType == ProofContentType.image;

  ProofSubmission copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? submissionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProofContentType? contentType,
    List<String>? imageUrls,
    String? description,
    Map<String, ChallengeGoalProofState>? challengeGoalStates,
    Map<String, dynamic>? metadata,
  }) {
    return ProofSubmission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      submissionDate: submissionDate ?? this.submissionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentType: contentType ?? this.contentType,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      challengeGoalStates: challengeGoalStates ?? this.challengeGoalStates,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        submissionDate,
        createdAt,
        updatedAt,
        contentType,
        imageUrls,
        description,
        challengeGoalStates,
        metadata,
      ];

  @override
  String toString() => 'ProofSubmission(id: $id, userId: $userId, goals: ${challengeGoalStates.length})';
}

// Extension to add firstOrNull to Iterable
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}