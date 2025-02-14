// models/goal.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String name;
  final int frequency;
  final String criteria;
  final List<dynamic> weekStatus;

  Goal({
    required this.id,
    required this.name,
    required this.frequency,
    required this.criteria,
    required this.weekStatus,
  });

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      name: data['goalName'] ?? '',
      frequency: data['goalFrequency'] ?? 0,
      criteria: data['goalCriteria'] ?? '',
      weekStatus: data['weekStatus'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goalName': name,
      'goalFrequency': frequency,
      'goalCriteria': criteria,
      'weekStatus': weekStatus,
    };
  }
}
