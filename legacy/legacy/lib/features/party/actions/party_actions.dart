import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/party_model.dart';
import '../repositories/party_repository.dart';

class PartyActions {
  final PartyRepository _repository;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PartyActions({
    PartyRepository? repository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _repository = repository ?? PartyRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> createParty(String partyName) async {
    if (partyName.trim().isEmpty) return null;
    
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      Party party = Party.create(currentUserId, partyName);
      final String partyId = await _repository.createParty(party);
      await _repository.updateUserPartyReference(currentUserId, partyId);
      
      return partyId;
    } catch (e) {
      return null;
    }
  }

  Future<bool> leaveParty(String partyId) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      List<String> updatedMembers = await _getCurrentMembers(partyId);
      updatedMembers.remove(currentUserId);

      if (updatedMembers.isEmpty) {
        await _firestore.collection('parties').doc(partyId).delete();
      } else {
        await _firestore.collection('parties').doc(partyId).update({
          'members': updatedMembers,
        });
      }

      await _firestore.collection('users').doc(currentUserId).update({
        'partyId': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> transferLeadership(String partyId, String newLeaderId, List<String> members) async {
    if (!members.contains(newLeaderId)) return false;
    
    try {
      await _firestore.collection('parties').doc(partyId).update({
        'partyOwner': newLeaderId,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMember(String partyId, String memberId, List<String> currentMembers) async {
    if (!currentMembers.contains(memberId)) return false;
    if (memberId == _auth.currentUser?.uid) return false; // Can't remove self
    
    try {
      List<String> updatedMembers = List<String>.from(currentMembers);
      updatedMembers.remove(memberId);

      await _firestore.collection('parties').doc(partyId).update({
        'members': updatedMembers,
      });

      await _firestore.collection('users').doc(memberId).update({
        'partyId': FieldValue.delete(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> _getCurrentMembers(String partyId) async {
    final doc = await _firestore.collection('parties').doc(partyId).get();
    return List<String>.from(doc.data()?['members'] ?? []);
  }

  // Challenge Management Methods
  Future<bool> startChallengePrep(String partyId) async {
    try {
      final challengeData = {
        'id': _firestore.collection('challenges').doc().id,
        'state': 'preparation',
        'startedBy': _auth.currentUser?.uid,
        'startedAt': FieldValue.serverTimestamp(),
        'lockedInMembers': <String>[],
        'optedOutMembers': <String>[],
        'wagers': <String, dynamic>{},
      };

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge': challengeData,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> lockInMember(String partyId, double wager) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.lockedInMembers': FieldValue.arrayUnion([currentUserId]),
        'activeChallenge.wagers.$currentUserId': wager,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> optOutMember(String partyId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.optedOutMembers': FieldValue.arrayUnion([currentUserId]),
        'activeChallenge.wagers.$currentUserId': 0,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startActiveChallenge(String partyId) async {
    try {
      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.state': 'active',
        'activeChallenge.weekStartDate': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelChallengePrep(String partyId) async {
    try {
      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge': null,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> endChallenge(String partyId) async {
    try {
      // Get current challenge data for archiving
      final partyDoc = await _firestore.collection('parties').doc(partyId).get();
      final challengeData = partyDoc.data()?['activeChallenge'];
      
      if (challengeData != null) {
        // Archive the challenge
        challengeData['endedAt'] = FieldValue.serverTimestamp();
        challengeData['state'] = 'completed';
        await _repository.archiveChallengeHistory(partyId, challengeData);
      }

      // Clear active challenge
      await _repository.clearActiveChallenge(partyId);

      return true;
    } catch (e) {
      return false;
    }
  }
}