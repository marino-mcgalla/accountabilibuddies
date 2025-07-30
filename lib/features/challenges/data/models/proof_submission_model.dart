import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/proof_submission.dart';

class ProofApprovalModel {
  const ProofApprovalModel({
    required this.userId,
    required this.userName,
    required this.approved,
    required this.timestamp,
    this.comment,
  });

  final String userId;
  final String userName;
  final bool approved;
  final DateTime timestamp;
  final String? comment;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'approved': approved,
      'timestamp': Timestamp.fromDate(timestamp),
      'comment': comment,
    };
  }

  factory ProofApprovalModel.fromFirestore(Map<String, dynamic> data) {
    return ProofApprovalModel(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      approved: data['approved'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      comment: data['comment'],
    );
  }

  factory ProofApprovalModel.fromEntity(ProofApproval approval) {
    return ProofApprovalModel(
      userId: approval.userId,
      userName: approval.userName,
      approved: approval.approved,
      timestamp: approval.timestamp,
      comment: approval.comment,
    );
  }

  ProofApproval toEntity() {
    return ProofApproval(
      userId: userId,
      userName: userName,
      approved: approved,
      timestamp: timestamp,
      comment: comment,
    );
  }
}

class ChallengeGoalProofStateModel {
  const ChallengeGoalProofStateModel({
    required this.challengeId,
    required this.participationId,
    required this.goalTemplateId,
    required this.status,
    this.approvals = const [],
    this.viewedBy = const [],
  });

  final String challengeId;
  final String participationId;
  final String goalTemplateId;
  final String status;
  final List<ProofApprovalModel> approvals;
  final List<String> viewedBy;

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'participationId': participationId,
      'goalTemplateId': goalTemplateId,
      'status': status,
      'approvals': approvals.map((a) => a.toFirestore()).toList(),
      'viewedBy': viewedBy,
    };
  }

  factory ChallengeGoalProofStateModel.fromFirestore(Map<String, dynamic> data) {
    final approvalsList = (data['approvals'] as List<dynamic>? ?? [])
        .map((a) => ProofApprovalModel.fromFirestore(a as Map<String, dynamic>))
        .toList();

    return ChallengeGoalProofStateModel(
      challengeId: data['challengeId'] ?? '',
      participationId: data['participationId'] ?? '',
      goalTemplateId: data['goalTemplateId'] ?? '',
      status: data['status'] ?? 'pending',
      approvals: approvalsList,
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }

  factory ChallengeGoalProofStateModel.fromEntity(ChallengeGoalProofState state) {
    return ChallengeGoalProofStateModel(
      challengeId: state.challengeId,
      participationId: state.participationId,
      goalTemplateId: state.goalTemplateId,
      status: state.status.name,
      approvals: state.approvals.map(ProofApprovalModel.fromEntity).toList(),
      viewedBy: state.viewedBy,
    );
  }

  ChallengeGoalProofState toEntity() {
    return ChallengeGoalProofState(
      challengeId: challengeId,
      participationId: participationId,
      goalTemplateId: goalTemplateId,
      status: ProofStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => ProofStatus.pending,
      ),
      approvals: approvals.map((a) => a.toEntity()).toList(),
      viewedBy: viewedBy,
    );
  }
}

class ProofSubmissionModel {
  const ProofSubmissionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.submissionDate,
    required this.createdAt,
    required this.updatedAt,
    required this.challengeGoalStates,
    this.contentType = 'text',
    this.imageUrls = const [],
    this.description,
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String userName;
  final DateTime submissionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String contentType;
  final List<String> imageUrls;
  final String? description;
  final Map<String, ChallengeGoalProofStateModel> challengeGoalStates;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'submissionDate': Timestamp.fromDate(submissionDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'contentType': contentType,
      'imageUrls': imageUrls,
      'description': description,
      'challengeGoalStates': challengeGoalStates.map(
        (key, state) => MapEntry(key, state.toFirestore()),
      ),
      'metadata': metadata,
    };
  }

  factory ProofSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final challengeGoalStatesData = data['challengeGoalStates'] as Map<String, dynamic>? ?? {};
    final challengeGoalStates = challengeGoalStatesData.map(
      (key, value) => MapEntry(
        key,
        ChallengeGoalProofStateModel.fromFirestore(value as Map<String, dynamic>),
      ),
    );

    return ProofSubmissionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      submissionDate: (data['submissionDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      contentType: data['contentType'] ?? 'text',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      description: data['description'],
      challengeGoalStates: challengeGoalStates,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory ProofSubmissionModel.fromEntity(ProofSubmission proof) {
    final challengeGoalStates = proof.challengeGoalStates.map(
      (key, state) => MapEntry(key, ChallengeGoalProofStateModel.fromEntity(state)),
    );

    return ProofSubmissionModel(
      id: proof.id,
      userId: proof.userId,
      userName: proof.userName,
      submissionDate: proof.submissionDate,
      createdAt: proof.createdAt,
      updatedAt: proof.updatedAt,
      contentType: proof.contentType.name,
      imageUrls: proof.imageUrls,
      description: proof.description,
      challengeGoalStates: challengeGoalStates,
      metadata: proof.metadata,
    );
  }

  ProofSubmission toEntity() {
    final challengeGoalStatesEntities = challengeGoalStates.map(
      (key, state) => MapEntry(key, state.toEntity()),
    );

    return ProofSubmission(
      id: id,
      userId: userId,
      userName: userName,
      submissionDate: submissionDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      contentType: ProofContentType.values.firstWhere(
        (t) => t.name == contentType,
        orElse: () => ProofContentType.text,
      ),
      imageUrls: imageUrls,
      description: description,
      challengeGoalStates: challengeGoalStatesEntities,
      metadata: metadata,
    );
  }
}