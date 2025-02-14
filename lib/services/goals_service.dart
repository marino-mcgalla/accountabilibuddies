// services/goals_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> deleteGoal(String goalId) async {
    await _firestore.collection('goals').doc(goalId).delete();
  }

  //TODO: Implement archiveGoal
  Future<void> archiveGoal() async {
    print('archive goal');
  }

  Future<void> toggleStatus(
      String goalId, String date, String currentStatus) async {
    DocumentReference docRef = _firestore.collection('goals').doc(goalId);
    DocumentSnapshot docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      List<dynamic> weekStatus = docSnapshot['weekStatus'] ?? [];
      int index = weekStatus.indexWhere((day) => day['date'] == date);
      if (index != -1) {
        String newStatus = currentStatus == 'skipped' ? 'blank' : 'skipped';
        weekStatus[index]['status'] = newStatus;
        await docRef.update({'weekStatus': weekStatus});
      }
    }
  }
}
