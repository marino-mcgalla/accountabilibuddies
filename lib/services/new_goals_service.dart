import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../models/progress_tracker_model.dart'; // Import the ProgressTrackerModel

class GoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGoal(String goalName, int goalFrequency,
      String goalCriteria, String goalType) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (goalName.isNotEmpty && goalFrequency > 0) {
      DocumentReference goalRef = await _firestore.collection('goals').add({
        'ownerId': currentUserId,
        'goalName': goalName,
        'goalFrequency': goalFrequency,
        'goalCriteria': goalCriteria,
        'goalType': goalType,
      });
      // Call createProgressTracker to initialize the progress tracker
      await createProgressTracker(goalRef.id, goalType, goalFrequency);
    }
  }

  Future<void> createProgressTracker(
      String goalId, String goalType, int goalFrequency) async {
    DateTime weekStartDate =
        DateTime.now(); // Adjust to the start of the week if needed

    ProgressTrackerModel progressTracker = ProgressTrackerModel(
      goalId: goalId,
      weekStartDate: weekStartDate,
      days: goalType == 'daily'
          ? List.generate(
              7,
              (index) => DayProgress(
                  date: weekStartDate.add(Duration(days: index)),
                  status: 'blank'))
          : null,
      totalCompletions: goalType == 'total' ? 0 : null,
      targetCompletions: goalType == 'total' ? goalFrequency : null,
    );

    await _firestore
        .collection('weekly_progress')
        .doc(goalId)
        .set(progressTracker.toMap());
  }

  Future<void> archiveCurrentWeek(String goalId) async {
    DocumentSnapshot currentWeekDoc =
        await _firestore.collection('weekly_progress').doc(goalId).get();
    if (currentWeekDoc.exists) {
      ProgressTrackerModel currentWeekProgress =
          ProgressTrackerModel.fromFirestore(currentWeekDoc);

      // Fetch the goal document
      DocumentSnapshot goalDoc =
          await _firestore.collection('goals').doc(goalId).get();
      Goal goal = Goal.fromFirestore(goalDoc);

      // Add the current week's progress to the history
      goal.history.add(currentWeekProgress);

      // Update the goal document with the new history
      await _firestore.collection('goals').doc(goalId).update(goal.toMap());

      // Delete the current week's progress document
      await _firestore.collection('weekly_progress').doc(goalId).delete();
    }
  }

  Future<void> createFreshWeek(
      String goalId, String goalType, int goalFrequency) async {
    DateTime weekStartDate =
        DateTime.now(); // Adjust to the start of the new week

    ProgressTrackerModel progressTracker = ProgressTrackerModel(
      goalId: goalId,
      weekStartDate: weekStartDate,
      days: goalType == 'daily'
          ? List.generate(
              7,
              (index) => DayProgress(
                  date: weekStartDate.add(Duration(days: index)),
                  status: 'blank'))
          : null,
      totalCompletions: goalType == 'total' ? 0 : null, //COME BACK TO THIS
      targetCompletions: goalFrequency,
    );

    await _firestore
        .collection('weekly_progress')
        .doc(goalId)
        .set(progressTracker.toMap());
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
          title: Text('Delete Goal'),
          content: Text('Are you sure you want to delete this goal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete) {
      await _firestore.collection('goals').doc(goalId).delete();
      await _firestore.collection('weekly_progress').doc(goalId).delete();
    }
  }
}
