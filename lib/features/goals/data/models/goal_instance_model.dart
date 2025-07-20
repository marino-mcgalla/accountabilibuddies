import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/goal_instance.dart';

class GoalInstanceModel extends GoalInstance {
  const GoalInstanceModel({
    required super.id,
    required super.templateId,
    required super.userId,
    required super.challengeId,
    required super.targetFrequency,
    super.currentCount = 0,
    super.status = GoalInstanceStatus.active,
    required super.createdAt,
    super.completedAt,
    super.partyIds = const [],
    super.completionDates = const [],
    super.weeklyMetadata = const {},
  });

  factory GoalInstanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GoalInstanceModel(
      id: doc.id,
      templateId: data['templateId'] as String,
      userId: data['userId'] as String,
      challengeId: data['challengeId'] as String,
      targetFrequency: data['targetFrequency'] as int,
      currentCount: data['currentCount'] ?? 0,
      status: GoalInstanceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GoalInstanceStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      partyIds: List<String>.from(data['partyIds'] ?? []),
      completionDates: (data['completionDates'] as List<dynamic>? ?? [])
          .map((timestamp) => (timestamp as Timestamp).toDate())
          .toList(),
      weeklyMetadata: Map<String, dynamic>.from(data['weeklyMetadata'] ?? {}),
    );
  }

  factory GoalInstanceModel.fromJson(Map<String, dynamic> json) {
    return GoalInstanceModel(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      userId: json['userId'] as String,
      challengeId: json['challengeId'] as String,
      targetFrequency: json['targetFrequency'] as int,
      currentCount: json['currentCount'] ?? 0,
      status: GoalInstanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalInstanceStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      partyIds: List<String>.from(json['partyIds'] ?? []),
      completionDates: (json['completionDates'] as List<dynamic>? ?? [])
          .map((dateString) => DateTime.parse(dateString as String))
          .toList(),
      weeklyMetadata: Map<String, dynamic>.from(json['weeklyMetadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'templateId': templateId,
      'userId': userId,
      'challengeId': challengeId,
      'targetFrequency': targetFrequency,
      'currentCount': currentCount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'partyIds': partyIds,
      'completionDates': completionDates.map((date) => Timestamp.fromDate(date)).toList(),
      'weeklyMetadata': weeklyMetadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'userId': userId,
      'challengeId': challengeId,
      'targetFrequency': targetFrequency,
      'currentCount': currentCount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'partyIds': partyIds,
      'completionDates': completionDates.map((date) => date.toIso8601String()).toList(),
      'weeklyMetadata': weeklyMetadata,
    };
  }

  factory GoalInstanceModel.fromEntity(GoalInstance instance) {
    return GoalInstanceModel(
      id: instance.id,
      templateId: instance.templateId,
      userId: instance.userId,
      challengeId: instance.challengeId,
      targetFrequency: instance.targetFrequency,
      currentCount: instance.currentCount,
      status: instance.status,
      createdAt: instance.createdAt,
      completedAt: instance.completedAt,
      partyIds: instance.partyIds,
      completionDates: instance.completionDates,
      weeklyMetadata: instance.weeklyMetadata,
    );
  }

  GoalInstance toEntity() {
    return GoalInstance(
      id: id,
      templateId: templateId,
      userId: userId,
      challengeId: challengeId,
      targetFrequency: targetFrequency,
      currentCount: currentCount,
      status: status,
      createdAt: createdAt,
      completedAt: completedAt,
      partyIds: partyIds,
      completionDates: completionDates,
      weeklyMetadata: weeklyMetadata,
    );
  }
}