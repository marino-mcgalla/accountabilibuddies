import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/goal_template.dart';

class GoalTemplateModel extends GoalTemplate {
  const GoalTemplateModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.category,
    required super.goalType,
    super.plannedFrequency,
    required super.tags,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.totalInstances = 0,
    super.totalCompletions = 0,
    super.totalTargeted = 0,
    super.averageCompletionRate = 0.0,
    super.lastUsedAt,
    required super.metadata,
  });

  factory GoalTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GoalTemplateModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => GoalCategory.other,
      ),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == data['goalType'],
        orElse: () => GoalType.daily,
      ),
      plannedFrequency: data['plannedFrequency'] as int?,
      tags: List<String>.from(data['tags'] ?? []),
      status: GoalTemplateStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GoalTemplateStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      totalInstances: data['totalInstances'] ?? 0,
      totalCompletions: data['totalCompletions'] ?? 0,
      totalTargeted: data['totalTargeted'] ?? 0,
      averageCompletionRate: (data['averageCompletionRate'] ?? 0.0).toDouble(),
      lastUsedAt: data['lastUsedAt'] != null 
          ? (data['lastUsedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory GoalTemplateModel.fromJson(Map<String, dynamic> json) {
    return GoalTemplateModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GoalCategory.other,
      ),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == json['goalType'],
        orElse: () => GoalType.daily,
      ),
      plannedFrequency: json['plannedFrequency'] as int?,
      tags: List<String>.from(json['tags'] ?? []),
      status: GoalTemplateStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalTemplateStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      totalInstances: json['totalInstances'] ?? 0,
      totalCompletions: json['totalCompletions'] ?? 0,
      totalTargeted: json['totalTargeted'] ?? 0,
      averageCompletionRate: (json['averageCompletionRate'] ?? 0.0).toDouble(),
      lastUsedAt: json['lastUsedAt'] != null 
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
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
      'plannedFrequency': plannedFrequency,
      'tags': tags,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'totalInstances': totalInstances,
      'totalCompletions': totalCompletions,
      'totalTargeted': totalTargeted,
      'averageCompletionRate': averageCompletionRate,
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
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
      'plannedFrequency': plannedFrequency,
      'tags': tags,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalInstances': totalInstances,
      'totalCompletions': totalCompletions,
      'totalTargeted': totalTargeted,
      'averageCompletionRate': averageCompletionRate,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory GoalTemplateModel.fromEntity(GoalTemplate template) {
    return GoalTemplateModel(
      id: template.id,
      userId: template.userId,
      title: template.title,
      description: template.description,
      category: template.category,
      goalType: template.goalType,
      plannedFrequency: template.plannedFrequency,
      tags: template.tags,
      status: template.status,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      totalInstances: template.totalInstances,
      totalCompletions: template.totalCompletions,
      totalTargeted: template.totalTargeted,
      averageCompletionRate: template.averageCompletionRate,
      lastUsedAt: template.lastUsedAt,
      metadata: template.metadata,
    );
  }

  GoalTemplate toEntity() {
    return GoalTemplate(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      goalType: goalType,
      plannedFrequency: plannedFrequency,
      tags: tags,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      totalInstances: totalInstances,
      totalCompletions: totalCompletions,
      totalTargeted: totalTargeted,
      averageCompletionRate: averageCompletionRate,
      lastUsedAt: lastUsedAt,
      metadata: metadata,
    );
  }
}