import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/goal.dart';

class GoalModel extends Goal {
  const GoalModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.category,
    required super.goalType,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
    super.dueDate,
    required super.targetFrequency,
    required super.currentCount,
    required super.tags,
    super.partyIds = const [],
    required super.metadata,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GoalModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => GoalCategory.other,
      ),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == (data['goalType'] ?? data['frequency']),
        orElse: () => GoalType.daily,
      ),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      targetFrequency: (data['targetFrequency'] ?? data['targetCount']) as int,
      currentCount: data['currentCount'] as int,
      tags: List<String>.from(data['tags'] ?? []),
      partyIds: List<String>.from(data['partyIds'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GoalCategory.other,
      ),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == (json['goalType'] ?? json['frequency']),
        orElse: () => GoalType.daily,
      ),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      targetFrequency: (json['targetFrequency'] ?? json['targetCount']) as int,
      currentCount: json['currentCount'] as int,
      tags: List<String>.from(json['tags'] ?? []),
      partyIds: List<String>.from(json['partyIds'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'goalType': goalType.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'targetFrequency': targetFrequency,
      'currentCount': currentCount,
      'tags': tags,
      'partyIds': partyIds,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'goalType': goalType.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'targetFrequency': targetFrequency,
      'currentCount': currentCount,
      'tags': tags,
      'partyIds': partyIds,
      'metadata': metadata,
    };
  }

  factory GoalModel.fromEntity(Goal goal) {
    return GoalModel(
      id: goal.id,
      userId: goal.userId,
      title: goal.title,
      description: goal.description,
      category: goal.category,
      goalType: goal.goalType,
      status: goal.status,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
      completedAt: goal.completedAt,
      dueDate: goal.dueDate,
      targetFrequency: goal.targetFrequency,
      currentCount: goal.currentCount,
      tags: goal.tags,
      partyIds: goal.partyIds,
      metadata: goal.metadata,
    );
  }

  Goal toEntity() {
    return Goal(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      goalType: goalType,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      dueDate: dueDate,
      targetFrequency: targetFrequency,
      currentCount: currentCount,
      tags: tags,
      partyIds: partyIds,
      metadata: metadata,
    );
  }
}