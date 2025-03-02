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

  // Save goals to Firestore
  Future<void> saveGoals(String userId, List<Goal> goals) async {
    List<Map<String, dynamic>> goalsData =
        goals.map((goal) => goal.toMap()).toList();
    await _firestore
        .collection('userGoals')
        .doc(userId)
        .set({'goals': goalsData});
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
}
