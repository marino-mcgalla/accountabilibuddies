import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String ownerId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;
  final String goalType;

  Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    required this.goalType,
  });

  factory Goal.fromMap(Map<String, dynamic> data) {
    return Goal(
      id: data['id'],
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalFrequency: data['goalFrequency'],
      goalCriteria: data['goalCriteria'],
      goalType: data['goalType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'goalName': goalName,
      'goalFrequency': goalFrequency,
      'goalCriteria': goalCriteria,
      'goalType': goalType,
    };
  }

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      ownerId: data['ownerId'],
      goalName: data['goalName'],
      goalFrequency: data['goalFrequency'],
      goalCriteria: data['goalCriteria'],
      goalType: data['goalType'],
    );
  }
}
