import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final int activeGoals;
  final int completedGoals;
  final int totalGoals;
  final int overdueGoals;
  final double averageProgress;
  final DateTime lastUpdated;
  final List<ActivityItem> recentActivity;

  const UserStats({
    required this.activeGoals,
    required this.completedGoals,
    required this.totalGoals,
    required this.overdueGoals,
    required this.averageProgress,
    required this.lastUpdated,
    required this.recentActivity,
  });

  UserStats.initial()
      : activeGoals = 0,
        completedGoals = 0,
        totalGoals = 0,
        overdueGoals = 0,
        averageProgress = 0.0,
        lastUpdated = DateTime(2024, 1, 1),
        recentActivity = const [];

  UserStats copyWith({
    int? activeGoals,
    int? completedGoals,
    int? totalGoals,
    int? overdueGoals,
    double? averageProgress,
    DateTime? lastUpdated,
    List<ActivityItem>? recentActivity,
  }) {
    return UserStats(
      activeGoals: activeGoals ?? this.activeGoals,
      completedGoals: completedGoals ?? this.completedGoals,
      totalGoals: totalGoals ?? this.totalGoals,
      overdueGoals: overdueGoals ?? this.overdueGoals,
      averageProgress: averageProgress ?? this.averageProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'activeGoals': activeGoals,
      'completedGoals': completedGoals,
      'totalGoals': totalGoals,
      'overdueGoals': overdueGoals,
      'averageProgress': averageProgress,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'recentActivity': recentActivity.map((item) => item.toFirestore()).toList(),
    };
  }

  factory UserStats.fromFirestore(Map<String, dynamic> data) {
    return UserStats(
      activeGoals: data['activeGoals'] ?? 0,
      completedGoals: data['completedGoals'] ?? 0,
      totalGoals: data['totalGoals'] ?? 0,
      overdueGoals: data['overdueGoals'] ?? 0,
      averageProgress: (data['averageProgress'] ?? 0.0).toDouble(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      recentActivity: (data['recentActivity'] as List<dynamic>? ?? [])
          .map((item) => ActivityItem.fromFirestore(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        activeGoals,
        completedGoals,
        totalGoals,
        overdueGoals,
        averageProgress,
        lastUpdated,
        recentActivity,
      ];
}

class ActivityItem extends Equatable {
  final String id;
  final ActivityType type;
  final String title;
  final String? subtitle;
  final String? goalId;
  final String? partyId;
  final DateTime timestamp;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.goalId,
    this.partyId,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'goalId': goalId,
      'partyId': partyId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ActivityItem.fromFirestore(Map<String, dynamic> data) {
    return ActivityItem(
      id: data['id'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.other,
      ),
      title: data['title'] as String,
      subtitle: data['subtitle'] as String?,
      goalId: data['goalId'] as String?,
      partyId: data['partyId'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [id, type, title, subtitle, goalId, partyId, timestamp];
}

enum ActivityType {
  goalCreated,
  goalCompleted,
  proofSubmitted,
  proofApproved,
  partyJoined,
  partyCreated,
  other,
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.goalCreated:
        return 'Goal Created';
      case ActivityType.goalCompleted:
        return 'Goal Completed';
      case ActivityType.proofSubmitted:
        return 'Proof Submitted';
      case ActivityType.proofApproved:
        return 'Proof Approved';
      case ActivityType.partyJoined:
        return 'Joined Party';
      case ActivityType.partyCreated:
        return 'Created Party';
      case ActivityType.other:
        return 'Activity';
    }
  }
}