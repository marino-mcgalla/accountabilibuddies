import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../goals/models/goal_model.dart';
// import '../../goals/models/total_goal.dart';
// import '../../goals/models/weekly_goal.dart';
// import '../../goals/models/proof_model.dart';
// import '../../time_machine/providers/time_machine_provider.dart';
import '../providers/party_provider.dart';

/// Service for handling goal-related operations in parties
class PartyGoalsService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PartyProvider? _partyProvider;

  PartyGoalsService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    PartyProvider? partyProvider,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _partyProvider = partyProvider;

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

  Future<List<Map<String, dynamic>>> fetchSubmittedProofs(
      String partyId) async {
    if (_partyProvider != null) {
      print("Party Member Goals from Provider:");
      _partyProvider.partyMemberGoals.forEach((userId, goals) {
        print("User $userId has ${goals.length} goals");
        for (var goal in goals) {
          print("  - ${goal.title}: ${goal.id}");
        }
      });
    } else {
      print("PartyProvider not available");
    }
    try {
      //should already be subscribed, just use a getter
      final partyDoc =
          await _firestore.collection('parties').doc(partyId).get();
      if (!partyDoc.exists) throw Exception("Party not found");

      List<String> memberIds = List<String>.from(partyDoc['members'] ?? []);
      List<Map<String, dynamic>> results = [];

      // same with this? Shouldn't this data already be available from a provider somewhere since it's coming from a subscription?
      for (String userId in memberIds) {
        final doc = await _firestore.collection('userGoals').doc(userId).get();
        if (!doc.exists) continue;

        final goalsData = List<dynamic>.from(doc.data()?['goals'] ?? []);

        // 3. Filter for goals with pending proofs
        // can we avoid all this looping if we add IDs to proofs? This seems ridiculously unnecessary
        for (var goalData in goalsData) {
          // print(goalData);
          if (goalData['challenge'] == null ||
              goalData['challenge']['proofs'] == null) {
            continue;
          }

          final goal = Goal.fromMap(goalData);

          // 4. Extract pending proofs based on goal type
          if (goalData['challenge']['proofs'] is Map) {
            // Weekly goals have map-based proofs
            _extractWeeklyProofs(
                goal,
                userId,
                goalData['challenge']['proofs'] as Map<String, dynamic>,
                results);
          } else if (goalData['challenge']['proofs'] is List) {
            // Total goals have list-based proofs
            _extractTotalProofs(
                goal, userId, goalData['challenge']['proofs'] as List, results);
          } else {
            print(
                'Warning: Unknown proof structure type: ${goalData['challenge']['proofs'].runtimeType}');
          }
        }
      }

      return results;
    } catch (e) {
      print('Error fetching submitted goals: $e');
      rethrow;
    }
  }

// Helper method for weekly goals
  void _extractWeeklyProofs(Goal goal, String userId,
      Map<String, dynamic> proofs, List<Map<String, dynamic>> results) {
    proofs.forEach((date, proof) {
      if (proof is Map && proof['status'] == 'pending') {
        results.add({
          'goal': goal,
          'userId': userId,
          'date': date,
          'proof': proof,
        });
      }
    });
  }

// Helper method for total goals
  void _extractTotalProofs(Goal goal, String userId, List proofsList,
      List<Map<String, dynamic>> results) {
    for (var proof in proofsList) {
      if (proof is Map && proof['status'] == 'pending') {
        results.add({
          'goal': goal,
          'userId': userId,
          'date': null,
          'proof': proof,
        });
      }
    }
  }

  Future<void> approveProof(
      String userId, String goalId, String? proofDate) async {
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (!userGoalsDoc.exists)
      throw Exception("User goals document does not exist");

    List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
    var goalData =
        goalsData.firstWhere((g) => g['id'] == goalId, orElse: () => null);
    if (goalData == null) return;

    if (goalData['challenge'] != null) {
      _updateChallengeForApproval(goalData, proofDate);
    }

    await _firestore
        .collection('userGoals')
        .doc(userId)
        .update({'goals': goalsData});
  }

// Helper method for challenge update
  void _updateChallengeForApproval(
      Map<String, dynamic> goalData, String? proofDate) {
    goalData['challenge']['completions'] ??= {};

    if (goalData['goalType'] == 'weekly' && proofDate != null) {
      goalData['challenge']['completions'][proofDate] = 'completed';
      _removeProofFromMap(goalData['challenge']['proofs'], proofDate);
    } else if (goalData['goalType'] == 'total') {
      String today = DateTime.now().toIso8601String().split('T').first;
      int current = goalData['challenge']['completions'][today] ?? 0;
      goalData['challenge']['completions'][today] = current + 1;
      _removeProofFromList(goalData['challenge']['proofs']);
    }
  }

// Utility functions
  void _removeProofFromMap(Map<String, dynamic>? proofs, String key) {
    if (proofs != null && proofs[key] != null) {
      proofs.remove(key);
    }
  }

  void _removeProofFromList(List? proofs) {
    if (proofs == null || proofs.isEmpty) return;

    // Look for a proof with status 'pending'
    for (int i = 0; i < proofs.length; i++) {
      if (proofs[i] is Map && proofs[i]['status'] == 'pending') {
        proofs.removeAt(i);
        print('✓ Removed pending proof');
        return; // Exit after removing one proof
      }
    }

    // If no pending proof found, remove the first one as fallback
    if (proofs.isNotEmpty) {
      proofs.removeAt(0);
      print('! No pending proof found, removed first proof');
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

            // Clear proofs for total goals
            if (goalData['goalType'] == 'total' &&
                goalData.containsKey('proofs')) {
              goalData['proofs'] = [];
            }
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
