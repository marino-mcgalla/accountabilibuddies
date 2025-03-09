// lib/features/goals/repositories/goals_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';

class GoalsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Get a stream of goals for the current user
  Stream<List<Goal>> getGoalsStream(String userId) {
    return _firestore
        .collection('userGoals')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      List<dynamic> goalsData = doc.data()?['goals'] ?? [];
      return goalsData.map((data) => Goal.fromMap(data)).toList();
    });
  }

// Add to GoalsRepository.dart
  // Stream<List<Goal>> getChallengeGoalsStream(String userId) {
  //   return _firestore
  //       .collection('userGoals')
  //       .doc(userId)
  //       .snapshots()
  //       .map((doc) {
  //     if (!doc.exists) {
  //       return [];
  //     }

  //     Map<String, dynamic>? data = doc.data();

  //     List<dynamic> goalsData = data?['challengeGoals'] ?? [];
  //     if (goalsData.isNotEmpty) {}

  //     return goalsData.map((data) => Goal.fromMap(data)).toList();
  //   });
  // }

  // Maybe not using anymore???
  Future<void> saveGoals(String userId, List<Goal> goals) async {
    List<Map<String, dynamic>> goalsData =
        goals.map((goal) => goal.toMap()).toList();
    await _firestore
        .collection('userGoals')
        .doc(userId)
        .set({'goals': goalsData}, SetOptions(merge: true)); // Use merge: true
  }

  // Save goals history to Firestore
  Future<void> saveGoalsHistory(
      String userId, List<Goal> goals, DateTime date) async {
    List<Map<String, dynamic>> goalsData =
        goals.map((goal) => goal.toMap()).toList();
    await _firestore
        .collection('userGoalsHistory')
        .doc(userId)
        .collection('weeks')
        .doc(date.toIso8601String())
        .set({'goals': goalsData});
  }

  // Get a user's goals from Firestore by ID
  Future<List<Goal>> getGoalsForUser(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (!doc.exists) return [];
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    List<dynamic> goalsData = data?['goals'] ?? [];
    return goalsData.map((data) => Goal.fromMap(data)).toList();
  }

  // Update another user's goals in Firestore
  Future<void> updateUserGoals(String userId, List<Goal> goals) async {
    List<Map<String, dynamic>> goalsData =
        goals.map((goal) => goal.toMap()).toList();
    await _firestore
        .collection('userGoals')
        .doc(userId)
        .update({'goals': goalsData});
  }

// Update a specific field of a goal
  Future<void> updateGoalField(
      String userId, String goalId, String field, dynamic value) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('userGoals').doc(userId).get();

      if (!doc.exists) return;

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      List<dynamic> goalsData = List.from(userData['goals'] ?? []);

      for (int i = 0; i < goalsData.length; i++) {
        if (goalsData[i]['id'] == goalId) {
          goalsData[i][field] = value;
          break;
        }
      }

      await _firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': goalsData});
    } catch (e) {
      print('Error updating goal field: $e');
      throw e;
    }
  }
}
