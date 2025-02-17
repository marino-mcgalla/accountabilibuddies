// services/goals_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import 'package:intl/intl.dart';

class GoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGoal(
      String goalName, int goalFrequency, String goalCriteria) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (goalName.isNotEmpty && goalFrequency > 0) {
      DocumentReference goalRef = await _firestore.collection('goals').add({
        'ownerId': currentUserId,
        'goalName': goalName,
        'goalFrequency': goalFrequency,
        'goalCriteria': goalCriteria,
      });

      await _createWeek(goalRef.id, currentUserId);
    }
  }

  Future<void> _createWeek(String goalId, String userId) async {
    print('creating week');
    List<Map<String, dynamic>> initialWeekStatus = List.generate(7, (index) {
      DateTime date = DateTime.now()
          .subtract(Duration(days: DateTime.now().weekday - 1))
          .add(Duration(days: index));
      return {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'status': 'blank',
        'updatedBy': userId,
        'updatedAt': Timestamp.now(),
      };
    });
    print(initialWeekStatus);
    await _firestore.collection('weeks').add({
      'goalId': goalId,
      'weekStatus': initialWeekStatus,
      'isActive': true,
    });
  }

  Future<void> updateWeek(
      String goalId, List<Map<String, dynamic>> updatedWeekStatus) async {
    QuerySnapshot snapshot = await _firestore
        .collection('weeks')
        .where('goalId', isEqualTo: goalId)
        .where('isActive', isEqualTo: true)
        .get();
    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = snapshot.docs.first;
      await doc.reference.update({'weekStatus': updatedWeekStatus});
    }
  }

  Future<List<Goal>> getGoals() async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    QuerySnapshot snapshot = await _firestore
        .collection('goals')
        .where('ownerId', isEqualTo: currentUserId)
        .get();
    return snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList();
  }

  Future<void> editGoal(Goal goal) async {
    await _firestore.collection('goals').doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteGoal(BuildContext context, String goalId) async {
    bool shouldDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("Do you really want to delete this goal?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (shouldDelete) {
      await _firestore.collection('goals').doc(goalId).delete();
      QuerySnapshot weeks = await _firestore
          .collection('weeks')
          .where('goalId', isEqualTo: goalId)
          .get();
      for (var doc in weeks.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal deleted'),
        ),
      );
    }
  }

  // Future<void> scheduleOrSkip(
  //     String goalId, String date, String currentStatus) async {
  //   print('TOGGLED from service');
  // }
}
