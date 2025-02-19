import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressTrackerModel {
  final String goalId;
  final DateTime weekStartDate;
  final List<DayProgress>? days; // For daily completions
  final int? totalCompletions; // For total completions
  final int? targetCompletions; // For total completions

  ProgressTrackerModel({
    required this.goalId,
    required this.weekStartDate,
    this.days,
    this.totalCompletions,
    this.targetCompletions,
  });

  // Factory constructor to create a ProgressTrackerModel from a Firestore document
  factory ProgressTrackerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProgressTrackerModel(
      goalId: data['goalId'],
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

  // Method to convert a ProgressTrackerModel to a map for Firestore
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

  // Factory constructor to create a DayProgress from a map
  factory DayProgress.fromMap(Map<String, dynamic> map) {
    return DayProgress(
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'],
    );
  }

  // Method to convert a DayProgress to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'status': status,
    };
  }
}
