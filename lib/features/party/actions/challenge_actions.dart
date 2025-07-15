import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge_state.dart';

class ChallengeActions {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChallengeActions({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Party leader sets up a new challenge
  Future<bool> setupChallenge(String partyId, DateTime startDate, DateTime endDate) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Verify user is party leader
      final partyDoc = await _firestore.collection('parties').doc(partyId).get();
      if (!partyDoc.exists || partyDoc.data()?['leaderId'] != currentUserId) {
        return false;
      }

      final challengeId = _firestore.collection('challenges').doc().id;
      
      final challenge = ChallengeState(
        id: challengeId,
        status: ChallengeStatus.setup,
        startDate: startDate,
        endDate: endDate,
      );

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge': challenge.toMap(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// User locks in their goals for the challenge
  Future<bool> lockInForChallenge(String partyId, double wagerAmount) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.lockedInMembers': FieldValue.arrayUnion([currentUserId]),
        'activeChallenge.wagers.$currentUserId': wagerAmount,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// User opts out of the challenge
  Future<bool> optOutOfChallenge(String partyId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.optedOutMembers': FieldValue.arrayUnion([currentUserId]),
        'activeChallenge.lockedInMembers': FieldValue.arrayRemove([currentUserId]),
        'activeChallenge.wagers.$currentUserId': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// User locks in their goals for the challenge
  Future<bool> lockInGoalsForChallenge(String partyId, List challengeGoals) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Convert goals to map format for storage
      final goalsData = challengeGoals.map((goal) => goal.toMap()).toList();

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.memberGoals.$currentUserId': goalsData,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Party leader starts the challenge
  Future<bool> startChallenge(String partyId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Verify user is party leader
      final partyDoc = await _firestore.collection('parties').doc(partyId).get();
      if (!partyDoc.exists || partyDoc.data()?['leaderId'] != currentUserId) {
        return false;
      }

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.status': ChallengeStatus.active.name,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Complete the challenge and calculate results
  Future<bool> completeChallenge(String partyId, Map<String, bool> goalCompletions) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Verify user is party leader
      final partyDoc = await _firestore.collection('parties').doc(partyId).get();
      if (!partyDoc.exists || partyDoc.data()?['leaderId'] != currentUserId) {
        return false;
      }

      // Calculate payouts
      final challengeData = partyDoc.data()?['activeChallenge'];
      if (challengeData == null) return false;

      final wagers = Map<String, double>.from(challengeData['wagers'] ?? {});
      final payouts = _calculatePayouts(wagers, goalCompletions);

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.status': ChallengeStatus.completed.name,
        'activeChallenge.goalCompletions': goalCompletions,
        'activeChallenge.payouts': payouts,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Move to payout phase (members notified of results)
  Future<bool> moveToPayoutPhase(String partyId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.status': ChallengeStatus.payout.name,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear the completed challenge
  Future<bool> clearChallenge(String partyId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Verify user is party leader
      final partyDoc = await _firestore.collection('parties').doc(partyId).get();
      if (!partyDoc.exists || partyDoc.data()?['leaderId'] != currentUserId) {
        return false;
      }

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculate payouts based on who completed their goals
  Map<String, double> _calculatePayouts(Map<String, double> wagers, Map<String, bool> completions) {
    final Map<String, double> payouts = {};
    
    // Find winners (those who completed all goals)
    final winners = completions.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
    
    if (winners.isEmpty) {
      // No winners, everyone gets their wager back
      wagers.forEach((userId, wager) {
        payouts[userId] = 0.0; // No gain or loss
      });
      return payouts;
    }

    // Calculate total pot from failures
    double totalPot = 0.0;
    wagers.forEach((userId, wager) {
      if (completions[userId] != true) {
        totalPot += wager;
        payouts[userId] = -wager; // They lose their wager
      }
    });

    // Distribute winnings among winners
    final double winningsPerWinner = totalPot / winners.length;
    for (String winnerId in winners) {
      payouts[winnerId] = winningsPerWinner;
    }

    return payouts;
  }
}