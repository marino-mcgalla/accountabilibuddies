import 'package:cloud_firestore/cloud_firestore.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';

abstract class Goal {
  final String id;
  final String ownerId;
  final String goalName;
  final String goalType;
  final String goalCriteria;
  final int goalFrequency; // Common property

  Goal({
    required this.id,
    required this.ownerId,
    required this.goalName,
    required this.goalType,
    required this.goalCriteria,
    required this.goalFrequency,
  });

  Map<String, dynamic> toMap();

  factory Goal.fromMap(Map<String, dynamic> data) {
    switch (data['goalType']) {
      case 'total':
        return TotalGoal.fromMap(data);
      case 'weekly':
        return WeeklyGoal.fromMap(data);
      default:
        throw Exception('Unknown goal type');
    }
  }

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Goal.fromMap(data);
  }
}
