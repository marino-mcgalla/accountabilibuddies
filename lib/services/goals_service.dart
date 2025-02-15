// services/goals_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import 'package:intl/intl.dart';

class GoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Future<void> createGoal(Goal goal) async {
  //   String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  //   await _firestore.collection('goals').add({
  //     'ownerId': currentUserId,
  //     ...goal.toMap(),
  //   });
  // }

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
    List<Map<String, dynamic>> initialWeekStatus = List.generate(7, (index) {
      DateTime date = DateTime.now()
          .subtract(Duration(days: DateTime.now().weekday - 1))
          .add(Duration(days: index));
      return {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'status': 'blank',
        'updatedBy': userId, //TODO: why do we need this??
        'updatedAt': Timestamp.now(),
      };
    });

    await _firestore.collection('weeks').add({
      'goalId': goalId,
      'weekStatus': initialWeekStatus,
      'isActive': true,
    });
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
    // Show confirmation dialog before deleting
    //TODO: move confirmation dialog UI somewhere else
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
      // Delete goal and related data from Firestore
      //TODO: also delete weeks associated with a goal?? or no?
      await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal deleted'),
        ),
      );
    }
  }

  //TODO: Implement archiveGoal
  Future<void> archiveGoal() async {
    print('archive goal');
  }

  Future<void> toggleStatus(
      String goalId, String date, String currentStatus) async {
    print('TOGGLED');
    // QuerySnapshot weekSnapshot = await _firestore
    //     .collection('weeks')
    //     .where('goalId', isEqualTo: goalId)
    //     .where('isActive', isEqualTo: true)
    //     .get();

    // if (weekSnapshot.docs.isNotEmpty) {
    //   DocumentReference weekRef = weekSnapshot.docs.first.reference;
    //   //TODO: weekStatus should probably be dayStatus instead
    //   List<dynamic> weekStatus = weekSnapshot.docs.first['weekStatus'] ?? [];
    //   int index = weekStatus.indexWhere((day) => day['date'] == date);
    //   if (index != -1) {
    //     String newStatus = currentStatus == 'skipped' ? 'blank' : 'skipped';
    //     weekStatus[index]['status'] = newStatus;
    //     await weekRef.update({'weekStatus': weekStatus});
    //   }
    // }
  }
}
