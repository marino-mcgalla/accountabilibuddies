// services/goals_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';

class GoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGoal(String goalName, int goalFrequency,
      String goalCriteria, String goalType) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (goalName.isNotEmpty && goalFrequency > 0) {
      await _firestore.collection('goals').add({
        'ownerId': currentUserId,
        'goalName': goalName,
        'goalFrequency': goalFrequency,
        'goalCriteria': goalCriteria,
        'goalType': goalType,
      });
      //if type = week, create 7 days of week
      //if type = additive, create progress bar
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

  //DONE ---------------------------------------------------------------------------------------------------------------

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
}
