import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/multi_party_challenge.dart';
import '../../party/models/challenge_state.dart';

/// Repository for managing multi-party challenges in Firestore
class MultiPartyChallengeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Collections
  CollectionReference get _challengesCollection => _firestore.collection('multiPartyChallenges');
  CollectionReference get _partiesCollection => _firestore.collection('parties');

  /// Create a new multi-party challenge
  Future<String?> createMultiPartyChallenge({
    required String creatorPartyId,
    required DateTime startDate,
    required DateTime endDate,
    List<String> invitedParties = const [],
    bool allowCrossPartyApproval = false,
  }) async {
    try {
      final challengeId = _challengesCollection.doc().id;
      final challenge = MultiPartyChallenge(
        id: challengeId,
        status: ChallengeStatus.setup,
        startDate: startDate,
        endDate: endDate,
        participatingParties: [creatorPartyId, ...invitedParties],
        partyInviteStatus: {
          creatorPartyId: PartyInviteStatus.accepted,
          ...Map.fromEntries(invitedParties.map((id) => 
            MapEntry(id, PartyInviteStatus.pending))),
        },
        creatorPartyId: creatorPartyId,
        challengeType: invitedParties.isEmpty ? 'single-party' : 'multi-party',
        allowCrossPartyProofApproval: allowCrossPartyApproval,
      );

      await _challengesCollection.doc(challengeId).set(challenge.toMap());
      
      // Link the challenge to the creator party
      await _linkChallengeToParty(creatorPartyId, challengeId);
      
      // Send invitations to other parties
      for (final partyId in invitedParties) {
        await _sendChallengeInvitation(partyId, challengeId);
      }

      return challengeId;
    } catch (e) {
      return null;
    }
  }

  /// Get a multi-party challenge by ID
  Future<MultiPartyChallenge?> getChallenge(String challengeId) async {
    try {
      final doc = await _challengesCollection.doc(challengeId).get();
      if (!doc.exists) return null;
      
      return MultiPartyChallenge.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Stream a multi-party challenge by ID
  Stream<MultiPartyChallenge?> streamChallenge(String challengeId) {
    return _challengesCollection.doc(challengeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MultiPartyChallenge.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  /// Get all challenges for a specific party
  Future<List<MultiPartyChallenge>> getPartyChallenges(String partyId) async {
    try {
      final querySnapshot = await _challengesCollection
          .where('participatingParties', arrayContains: partyId)
          .get();

      return querySnapshot.docs
          .map((doc) => MultiPartyChallenge.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream all challenges for a specific party
  Stream<List<MultiPartyChallenge>> streamPartyChallenges(String partyId) {
    return _challengesCollection
        .where('participatingParties', arrayContains: partyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MultiPartyChallenge.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Update a challenge
  Future<bool> updateChallenge(MultiPartyChallenge challenge) async {
    try {
      await _challengesCollection.doc(challenge.id).update(challenge.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Invite a party to join an existing challenge
  Future<bool> invitePartyToChallenge(String challengeId, String partyId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final challengeRef = _challengesCollection.doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);
        
        if (!challengeDoc.exists) return false;
        
        final challenge = MultiPartyChallenge.fromMap(
          challengeDoc.data() as Map<String, dynamic>);
        
        if (challenge.isPartyParticipating(partyId)) return false;
        
        final updatedChallenge = challenge.inviteParty(partyId);
        transaction.update(challengeRef, updatedChallenge.toMap());
        
        // Send invitation to the party
        await _sendChallengeInvitation(partyId, challengeId);
        
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Accept a challenge invitation for a party
  Future<bool> acceptChallengeInvitation(String challengeId, String partyId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final challengeRef = _challengesCollection.doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);
        
        if (!challengeDoc.exists) return false;
        
        final challenge = MultiPartyChallenge.fromMap(
          challengeDoc.data() as Map<String, dynamic>);
        
        if (!challenge.isPartyParticipating(partyId)) return false;
        
        final updatedChallenge = challenge.acceptPartyInvite(partyId);
        transaction.update(challengeRef, updatedChallenge.toMap());
        
        // Link the challenge to the accepting party
        await _linkChallengeToParty(partyId, challengeId);
        
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Decline a challenge invitation for a party
  Future<bool> declineChallengeInvitation(String challengeId, String partyId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final challengeRef = _challengesCollection.doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);
        
        if (!challengeDoc.exists) return false;
        
        final challenge = MultiPartyChallenge.fromMap(
          challengeDoc.data() as Map<String, dynamic>);
        
        if (!challenge.isPartyParticipating(partyId)) return false;
        
        final updatedChallenge = challenge.declinePartyInvite(partyId);
        transaction.update(challengeRef, updatedChallenge.toMap());
        
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Remove a party from a challenge
  Future<bool> removePartyFromChallenge(String challengeId, String partyId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final challengeRef = _challengesCollection.doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);
        
        if (!challengeDoc.exists) return false;
        
        final challenge = MultiPartyChallenge.fromMap(
          challengeDoc.data() as Map<String, dynamic>);
        
        if (!challenge.isPartyParticipating(partyId)) return false;
        
        final updatedChallenge = challenge.removeParty(partyId);
        transaction.update(challengeRef, updatedChallenge.toMap());
        
        // Unlink the challenge from the party
        await _unlinkChallengeFromParty(partyId, challengeId);
        
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Start a multi-party challenge
  Future<bool> startChallenge(String challengeId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final challengeRef = _challengesCollection.doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);
        
        if (!challengeDoc.exists) return false;
        
        final challenge = MultiPartyChallenge.fromMap(
          challengeDoc.data() as Map<String, dynamic>);
        
        if (!challenge.canStart) return false;
        
        final updatedChallenge = challenge.copyWith(status: ChallengeStatus.active);
        transaction.update(challengeRef, updatedChallenge.toMap());
        
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Complete a multi-party challenge
  Future<bool> completeChallenge(String challengeId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final challengeRef = _challengesCollection.doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);
        
        if (!challengeDoc.exists) return false;
        
        final challenge = MultiPartyChallenge.fromMap(
          challengeDoc.data() as Map<String, dynamic>);
        
        if (!challenge.canComplete) return false;
        
        final updatedChallenge = challenge.copyWith(status: ChallengeStatus.completed);
        transaction.update(challengeRef, updatedChallenge.toMap());
        
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Delete a challenge completely
  Future<bool> deleteChallenge(String challengeId) async {
    try {
      // Get the challenge to find all participating parties
      final challenge = await getChallenge(challengeId);
      if (challenge == null) return false;
      
      // Unlink from all participating parties
      for (final partyId in challenge.participatingParties) {
        await _unlinkChallengeFromParty(partyId, challengeId);
      }
      
      // Delete the challenge document
      await _challengesCollection.doc(challengeId).delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get pending challenge invitations for a party
  Future<List<MultiPartyChallenge>> getPendingInvitations(String partyId) async {
    try {
      final querySnapshot = await _challengesCollection
          .where('participatingParties', arrayContains: partyId)
          .where('partyInviteStatus.$partyId', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs
          .map((doc) => MultiPartyChallenge.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream pending challenge invitations for a party
  Stream<List<MultiPartyChallenge>> streamPendingInvitations(String partyId) {
    return _challengesCollection
        .where('participatingParties', arrayContains: partyId)
        .where('partyInviteStatus.$partyId', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MultiPartyChallenge.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Convert a single-party challenge to multi-party
  Future<String?> convertToMultiParty(String partyId, ChallengeState singlePartyChallenge) async {
    try {
      final multiPartyChallenge = MultiPartyChallenge.fromSingleParty(
        singlePartyChallenge, partyId);
      
      final challengeId = _challengesCollection.doc().id;
      final updatedChallenge = multiPartyChallenge.copyWith(id: challengeId);
      
      await _challengesCollection.doc(challengeId).set(updatedChallenge.toMap());
      
      return challengeId;
    } catch (e) {
      return null;
    }
  }

  // Private helper methods

  /// Link a challenge to a party's document
  Future<void> _linkChallengeToParty(String partyId, String challengeId) async {
    try {
      await _partiesCollection.doc(partyId).update({
        'linkedChallenges': FieldValue.arrayUnion([challengeId]),
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Unlink a challenge from a party's document
  Future<void> _unlinkChallengeFromParty(String partyId, String challengeId) async {
    try {
      await _partiesCollection.doc(partyId).update({
        'linkedChallenges': FieldValue.arrayRemove([challengeId]),
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Send a challenge invitation to a party
  Future<void> _sendChallengeInvitation(String partyId, String challengeId) async {
    try {
      // Create an invitation document for notifications
      await _firestore.collection('challengeInvitations').add({
        'challengeId': challengeId,
        'invitedPartyId': partyId,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      // Handle error silently for now
    }
  }
}