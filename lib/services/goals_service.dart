import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGoal(
      String goalName, int goalFrequency, String goalCriteria) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (goalName.isNotEmpty && goalFrequency > 0) {
      // This builds the week list... break this out into a separate part of firebase
      // should be a "week" collection rather than a nested object inside of the base goal
      // base goal: ownerId, goalName, goalFrequency, goalCriteria
      // week: M-Su w/ status for each day,
      // what else needs to be on the week itself???

      List<Map<String, dynamic>> initialWeekStatus = List.generate(7, (index) {
        DateTime date = DateTime.now()
            .subtract(Duration(days: DateTime.now().weekday - 1))
            .add(Duration(days: index));
        return {
          'date': DateFormat('yyyy-MM-dd').format(date),
          'status': 'blank',
          'updatedBy': currentUserId,
          'updatedAt': Timestamp.now(),
        };
      });

      await _firestore.collection('goals').add({
        'ownerId': currentUserId,
        'goalName': goalName,
        'goalFrequency': goalFrequency,
        'goalCriteria': goalCriteria,
        'weekStatus': initialWeekStatus,
      });
    }
  }

  Future<void> deleteGoal(BuildContext context, String goalId) async {
    // Show confirmation dialog before deleting
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal deleted'),
        ),
      );
    }
  }
}
