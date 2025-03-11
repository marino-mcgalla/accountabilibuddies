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
    List<Map<String, dynamic>> results = [];

    if (_partyProvider == null) {
      print("Error: PartyProvider not available for proof extraction");
      return [];
    }

    _partyProvider.partyMemberGoals.forEach((userId, goals) {
      for (var goal in goals) {
        if (goal.challenge == null || goal.challenge!['proofs'] == null) {
          continue;
        }

        if (goal.goalType == 'weekly' && goal.challenge!['proofs'] is Map) {
          Map<String, dynamic> proofs =
              goal.challenge!['proofs'] as Map<String, dynamic>;

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
        } else if (goal.goalType == 'total' &&
            goal.challenge!['proofs'] is List) {
          List<dynamic> proofs = goal.challenge!['proofs'] as List<dynamic>;

          for (var proof in proofs) {
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
      }
    });

    return results;
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

    for (int i = 0; i < proofs.length; i++) {
      if (proofs[i] is Map && proofs[i]['status'] == 'pending') {
        proofs.removeAt(i);
        return;
      }
    }

    // If no pending proof found, return
    if (proofs.isNotEmpty) {
      print('something broke in removeProofFromList');
      return;
    }
  }
}
