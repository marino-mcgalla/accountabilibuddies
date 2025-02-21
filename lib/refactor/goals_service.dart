import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'goal_model.dart';

class GoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGoal(String goalName, int goalFrequency,
      String goalCriteria, String goalType) async {
    // This method is no longer needed as goals are managed in a single document
  }

  // Future<void> deleteGoal(BuildContext context, String goalId) async {
  //   // This method is no longer needed as goals are managed in a single document
  // }
}
