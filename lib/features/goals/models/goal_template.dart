import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalType {
  daily('daily'),
  total('total');

  const GoalType(this.value);
  final String value;

  static GoalType fromString(String value) {
    // Handle legacy values
    final normalizedValue = value.toLowerCase();
    switch (normalizedValue) {
      case 'daily':
      case 'weekly':
      case 'frequency':
        return GoalType.daily;
      case 'total':
      case 'count':
        return GoalType.total;
      default:
        return GoalType.values.firstWhere(
          (type) => type.value == normalizedValue,
          orElse: () => GoalType.daily,
        );
    }
  }
}

enum GoalStatus {
  active('active'),
  archived('archived');

  const GoalStatus(this.value);
  final String value;

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GoalStatus.active,
    );
  }
}

class GoalTemplate {
  final String id;
  final String name;
  final String description;
  final GoalType type;
  final int defaultFrequency;
  final String category;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final int totalChallengesUsed;
  final DateTime? lastUsedAt;

  const GoalTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.defaultFrequency,
    required this.category,
    required this.status,
    required this.createdAt,
    this.archivedAt,
    required this.totalChallengesUsed,
    this.lastUsedAt,
  });

  factory GoalTemplate.create({
    required String name,
    required String description,
    required GoalType type,
    required int defaultFrequency,
    required String category,
  }) {
    return GoalTemplate(
      id: '', // Will be set by Firestore
      name: name,
      description: description,
      type: type,
      defaultFrequency: defaultFrequency,
      category: category,
      status: GoalStatus.active,
      createdAt: DateTime.now(),
      archivedAt: null,
      totalChallengesUsed: 0,
      lastUsedAt: null,
    );
  }

  factory GoalTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final typeValue = data['type'] as String?;
    return GoalTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: GoalType.fromString(typeValue ?? 'daily'),
      defaultFrequency: data['defaultFrequency'] ?? 1,
      category: data['category'] ?? 'general',
      status: GoalStatus.fromString(data['status'] ?? 'active'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
      totalChallengesUsed: data['totalChallengesUsed'] ?? 0,
      lastUsedAt: (data['lastUsedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.value,
      'defaultFrequency': defaultFrequency,
      'category': category,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'totalChallengesUsed': totalChallengesUsed,
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
    };
  }

  GoalTemplate copyWith({
    String? id,
    String? name,
    String? description,
    GoalType? type,
    int? defaultFrequency,
    String? category,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? archivedAt,
    int? totalChallengesUsed,
    DateTime? lastUsedAt,
  }) {
    return GoalTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      totalChallengesUsed: totalChallengesUsed ?? this.totalChallengesUsed,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  bool get isActive => status == GoalStatus.active;
  bool get isArchived => status == GoalStatus.archived;

  String get displayType {
    switch (type) {
      case GoalType.daily:
        return 'Daily Goal';
      case GoalType.total:
        return 'Total Goal';
    }
  }

  String get frequencyText {
    switch (type) {
      case GoalType.daily:
        return '$defaultFrequency days per week';
      case GoalType.total:
        return '$defaultFrequency total completions';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalTemplate &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.defaultFrequency == defaultFrequency &&
        other.category == category &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.archivedAt == archivedAt &&
        other.totalChallengesUsed == totalChallengesUsed &&
        other.lastUsedAt == lastUsedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      type,
      defaultFrequency,
      category,
      status,
      createdAt,
      archivedAt,
      totalChallengesUsed,
      lastUsedAt,
    );
  }

  @override
  String toString() {
    return 'GoalTemplate(id: $id, name: $name, type: ${type.value}, status: ${status.value})';
  }
}