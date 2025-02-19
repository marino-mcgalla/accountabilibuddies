import 'package:cloud_firestore/cloud_firestore.dart';
import 'progress_tracker_model.dart';

class Goal {
  final String id;
  final String ownerId;
  final String goalName;
  final int frequency;
  final String criteria;
  final String goalType;
  final List<ProgressTrackerModel> history; // Add history field

  Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.frequency,
    required this.criteria,
    required this.goalType,
    required this.history,
  });

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      goalName: data['goalName'] ?? '',
      frequency: data['goalFrequency'] ?? 0,
      criteria: data['goalCriteria'] ?? '',
      goalType: data['goalType'] ?? '',
      history: data['history'] != null
          ? (data['history'] as List)
              .map((item) => ProgressTrackerModel.fromMap(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'goalName': goalName,
      'goalFrequency': frequency,
      'goalCriteria': criteria,
      'goalType': goalType,
      'history': history.map((item) => item.toMap()).toList(),
    };
  }
}
