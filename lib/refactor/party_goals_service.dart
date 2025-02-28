import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'time_machine_provider.dart';

/// Service for handling goal-related operations in parties
class PartyGoalsService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PartyGoalsService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Fetch goals for a specific party member
  Future<List<Goal>> fetchGoalsForUser(String userId) async {
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      final data = userGoalsDoc.data();
      if (data != null && data is Map<String, dynamic>) {
        List<dynamic> goalsData = data['goals'] ?? [];
        return goalsData.map((goalData) => Goal.fromMap(goalData)).toList();
      }
    }
    return [];
  }

  /// Fetch all pending proofs that need approval across all party members
  Future<List<Map<String, dynamic>>> fetchSubmittedGoalsForParty(
      List<String> members) async {
    List<Map<String, dynamic>> submittedGoals = [];

    for (String memberId in members) {
      DocumentSnapshot userGoalsDoc =
          await _firestore.collection('userGoals').doc(memberId).get();

      if (userGoalsDoc.exists && userGoalsDoc.data() != null) {
        Map<String, dynamic> userData =
            userGoalsDoc.data() as Map<String, dynamic>;
        List<dynamic> goalsData = userData['goals'] ?? [];

        for (var goalData in goalsData) {
          Goal goal = Goal.fromMap(goalData);

          if (goal is WeeklyGoal) {
            Map<String, String> completions =
                goal.currentWeekCompletions.cast<String, String>();
            completions.forEach((day, status) {
              if (status == 'submitted') {
                submittedGoals.add({
                  'goal': goal,
                  'userId': memberId,
                  'date': day,
                });
              }
            });
          } else if (goal is TotalGoal) {
            for (var proof in goal.proofs) {
              if (proof['status'] == 'pending') {
                submittedGoals.add({
                  'goal': goal,
                  'userId': memberId,
                  'proof': proof,
                });
              }
            }
          }
        }
      }
    }

    return submittedGoals;
  }

  /// Approve a proof for a goal
  Future<void> approveProof(
      String goalId, String userId, String? proofDate) async {
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
      for (var goalData in goalsData) {
        if (goalData['id'] == goalId) {
          if (goalData['goalType'] == 'weekly' && proofDate != null) {
            goalData['currentWeekCompletions'][proofDate] = 'completed';
          } else if (goalData['goalType'] == 'total') {
            if (goalData['proofs'] != null && goalData['proofs'].isNotEmpty) {
              // Remove the first proof
              goalData['proofs'].removeAt(0);

              // Increment the total completions
              goalData['totalCompletions'] =
                  (goalData['totalCompletions'] ?? 0) + 1;

              // Add to current week completions
              String day = DateTime.now().toIso8601String().split('T').first;
              goalData['currentWeekCompletions'][day] =
                  (goalData['currentWeekCompletions'][day] ?? 0) + 1;
            }
          }
          break;
        }
      }

      // Update Firestore
      await _firestore.collection('userGoals').doc(userId).update({
        'goals': goalsData,
      });
    } else {
      throw Exception("User goals document does not exist");
    }
  }

  /// Deny a proof for a goal
  Future<void> denyProof(
      String goalId, String userId, String? proofDate) async {
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
      for (var goalData in goalsData) {
        if (goalData['id'] == goalId) {
          if (goalData['goalType'] == 'weekly' && proofDate != null) {
            goalData['currentWeekCompletions'][proofDate] = 'denied';
          } else if (goalData['goalType'] == 'total') {
            if (goalData['proofs'] != null && goalData['proofs'].isNotEmpty) {
              // Remove the first proof
              goalData['proofs'].removeAt(0);
            }
          }
          break;
        }
      }

      // Update Firestore
      await _firestore.collection('userGoals').doc(userId).update({
        'goals': goalsData,
      });
    } else {
      throw Exception("User goals document does not exist");
    }
  }

  /// End the week for all party members
  Future<void> endWeekForParty(
      List<String> members, DateTime newWeekStartDate) async {
    // Use batching for Firestore operations
    WriteBatch batch = _firestore.batch();

    for (String memberId in members) {
      DocumentSnapshot userGoalsDoc =
          await _firestore.collection('userGoals').doc(memberId).get();

      if (userGoalsDoc.exists) {
        Map<String, dynamic> userData =
            userGoalsDoc.data() as Map<String, dynamic>;
        List<dynamic> goalsData = userData['goals'] ?? [];

        if (goalsData.isNotEmpty) {
          // Store current week's progress in history
          DocumentReference historyRef = _firestore
              .collection('userGoalsHistory')
              .doc(memberId)
              .collection('weeks')
              .doc(DateTime.now().toIso8601String());

          batch.set(historyRef, {'goals': goalsData});

          // Reset completions for the new week
          for (var goalData in goalsData) {
            goalData['weekStartDate'] = newWeekStartDate.toIso8601String();
            goalData['currentWeekCompletions'] = {};
          }

          // Update goals in Firestore
          DocumentReference goalsRef =
              _firestore.collection('userGoals').doc(memberId);
          batch.set(goalsRef, {'goals': goalsData});
        }
      }
    }

    // Commit all operations at once
    await batch.commit();
  }
}
