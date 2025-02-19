import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressTrackerModel {
  final String goalId;
  final DateTime weekStartDate;
  final List<DayProgress>? days;
  final int? totalCompletions;
  final int? targetCompletions;

  ProgressTrackerModel({
    required this.goalId,
    required this.weekStartDate,
    this.days,
    this.totalCompletions,
    this.targetCompletions,
  });

  factory ProgressTrackerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Missing data for ProgressTrackerModel');
    }
    return ProgressTrackerModel(
      goalId: data['goalId'] ?? '',
      weekStartDate: (data['weekStartDate'] as Timestamp).toDate(),
      days: data['days'] != null
          ? (data['days'] as List)
              .map((day) => DayProgress.fromMap(day))
              .toList()
          : null,
      totalCompletions: data['totalCompletions'],
      targetCompletions: data['targetCompletions'],
    );
  }

  factory ProgressTrackerModel.fromMap(Map<String, dynamic> map) {
    return ProgressTrackerModel(
      goalId: map['goalId'],
      weekStartDate: (map['weekStartDate'] as Timestamp).toDate(),
      days: map['days'] != null
          ? (map['days'] as List)
              .map((day) => DayProgress.fromMap(day))
              .toList()
          : null,
      totalCompletions: map['totalCompletions'],
      targetCompletions: map['targetCompletions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goalId': goalId,
      'weekStartDate': weekStartDate,
      'days': days?.map((day) => day.toMap()).toList(),
      'totalCompletions': totalCompletions,
      'targetCompletions': targetCompletions,
    };
  }
}

class DayProgress {
  final DateTime date;
  final String status;

  DayProgress({
    required this.date,
    required this.status,
  });

  factory DayProgress.fromMap(Map<String, dynamic> map) {
    return DayProgress(
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'status': status,
    };
  }
}
