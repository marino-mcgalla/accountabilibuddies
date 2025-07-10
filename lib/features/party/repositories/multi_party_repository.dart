import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/party_model_multi.dart';
import '../models/party_membership.dart';
import '../models/challenge_state.dart';
import '../../auth/models/user_model.dart';

class MultiPartyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MultiPartyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;
  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _partiesCollection =>
      _firestore.collection('parties');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _invitesCollection =>
      _firestore.collection('invites');

  // Party CRUD Operations
  Future<String?> createParty(MultiParty party) async {
    if (_currentUserId == null) return null;

    try {
      return await _firestore.runTransaction((transaction) async {
        // Create the party
        final partyRef = _partiesCollection.doc();
        final partyWithId = party.copyWith(id: partyRef.id);
        
        print('Creating party document at: ${partyRef.path}');
        transaction.set(partyRef, partyWithId.toFirestore());

        // Create membership for the leader
        final membership = PartyMembership(
          partyId: partyRef.id,
          partyName: party.name,
          role: PartyRole.leader,
          joinedAt: DateTime.now(),
          status: MembershipStatus.active,
          memberCount: 1,
          lastActivityAt: DateTime.now(),
        );

        // Update user's party memberships by reading and updating the parties map
        final userRef = _usersCollection.doc(_currentUserId!);
        final userSnapshot = await transaction.get(userRef);
        
        Map<String, dynamic> userData = {};
        Map<String, dynamic> currentParties = {};
        
        if (userSnapshot.exists) {
          userData = userSnapshot.data()!;
          currentParties = Map<String, dynamic>.from(userData['parties'] as Map<String, dynamic>? ?? {});
        }
        
        // Add the new party to the parties map
        currentParties[partyRef.id] = membership.toMap();
        
        // Update the user document with the new parties map
        final updatedUserData = Map<String, dynamic>.from(userData);
        updatedUserData['parties'] = currentParties;
        updatedUserData['activePartyCount'] = currentParties.length;
        updatedUserData['lastActiveAt'] = FieldValue.serverTimestamp();
        
        // If this is a new user, set required fields
        if (!userSnapshot.exists) {
          updatedUserData['uid'] = _currentUserId;
          updatedUserData['email'] = '';
          updatedUserData['createdAt'] = FieldValue.serverTimestamp();
        }
        
        transaction.set(userRef, updatedUserData);
        print('Updated user doc with ${currentParties.length} parties including ${partyRef.id}');
        
        print('Transaction completed, party ID: ${partyRef.id}');
        return partyRef.id;
      });
    } catch (e) {
      print('Transaction failed: $e');
      return null;
    }
  }

  // Debug method to verify party exists after creation
  Future<void> verifyPartyExists(String partyId) async {
    try {
      final doc = await _partiesCollection.doc(partyId).get();
      print('🔍 PARTY VERIFICATION: $partyId exists = ${doc.exists}');
      if (doc.exists) {
        final data = doc.data()!;
        print('🔍 PARTY DATA: name=${data['name']}, leaderId=${data['leaderId']}');
      }
    } catch (e) {
      print('🔍 PARTY VERIFICATION ERROR: $e');
    }
  }

  Future<bool> updateParty(MultiParty party) async {
    try {
      await _partiesCollection.doc(party.id).update(party.toFirestore());
      return true;
    } catch (e) {
      print('Error updating party: $e');
      return false;
    }
  }

  Future<bool> deleteParty(String partyId) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Only leader can delete party
        if (party.leaderId != _currentUserId) return false;

        // Remove party from all members' user documents
        for (final memberId in party.members) {
          final userRef = _usersCollection.doc(memberId);
          transaction.update(userRef, {
            'parties.$partyId': FieldValue.delete(),
            'activePartyCount': FieldValue.increment(-1),
            'lastActiveAt': FieldValue.serverTimestamp(),
          });
        }

        // Delete the party
        transaction.delete(partyRef);
        
        return true;
      });
    } catch (e) {
      print('Error deleting party: $e');
      return false;
    }
  }

  // Member Management
  Future<bool> joinParty(String partyId, String userId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final userRef = _usersCollection.doc(userId);
        
        final partyDoc = await transaction.get(partyRef);
        final userDoc = await transaction.get(userRef);
        
        if (!partyDoc.exists || !userDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Check if user is already a member
        if (party.isMember(userId)) return false;
        
        // Check party capacity
        if (!party.canAddMembers) return false;
        
        // Add user to party
        final updatedParty = party.addMember(userId);
        transaction.update(partyRef, updatedParty.toFirestore());
        
        // Create membership for the user
        final membership = PartyMembership(
          partyId: partyId,
          partyName: party.name,
          role: PartyRole.member,
          joinedAt: DateTime.now(),
          status: MembershipStatus.active,
          memberCount: updatedParty.memberCount,
          lastActivityAt: DateTime.now(),
        );
        
        // Update user's party memberships
        transaction.update(userRef, {
          'parties.$partyId': membership.toMap(),
          'activePartyCount': FieldValue.increment(1),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      });
    } catch (e) {
      print('Error joining party: $e');
      return false;
    }
  }

  Future<bool> leaveParty(String partyId, String userId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final userRef = _usersCollection.doc(userId);
        
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Check if user is a member
        if (!party.isMember(userId)) return false;
        
        // If user is the leader and there are other members, transfer leadership
        if (party.isLeader(userId) && party.memberCount > 1) {
          final newLeader = party.members.firstWhere((id) => id != userId);
          final updatedParty = party.transferLeadership(newLeader).removeMember(userId);
          
          transaction.update(partyRef, updatedParty.toFirestore());
          
          // Update new leader's membership
          final newLeaderRef = _usersCollection.doc(newLeader);
          transaction.update(newLeaderRef, {
            'parties.$partyId.role': PartyRole.leader.value,
            'parties.$partyId.memberCount': updatedParty.memberCount,
            'lastActiveAt': FieldValue.serverTimestamp(),
          });
        } else if (party.isLeader(userId) && party.memberCount == 1) {
          // Last member leaving - delete the party
          transaction.delete(partyRef);
        } else {
          // Regular member leaving
          final updatedParty = party.removeMember(userId);
          transaction.update(partyRef, updatedParty.toFirestore());
        }
        
        // Remove party from user's memberships
        transaction.update(userRef, {
          'parties.$partyId': FieldValue.delete(),
          'activePartyCount': FieldValue.increment(-1),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      });
    } catch (e) {
      print('Error leaving party: $e');
      return false;
    }
  }

  Future<bool> transferLeadership(String partyId, String newLeaderId) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Only current leader can transfer leadership
        if (party.leaderId != _currentUserId) return false;
        
        // New leader must be a member
        if (!party.isMember(newLeaderId)) return false;
        
        final updatedParty = party.transferLeadership(newLeaderId);
        transaction.update(partyRef, updatedParty.toFirestore());
        
        // Update old leader's membership
        final oldLeaderRef = _usersCollection.doc(_currentUserId!);
        transaction.update(oldLeaderRef, {
          'parties.$partyId.role': PartyRole.member.value,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        
        // Update new leader's membership
        final newLeaderRef = _usersCollection.doc(newLeaderId);
        transaction.update(newLeaderRef, {
          'parties.$partyId.role': PartyRole.leader.value,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      });
    } catch (e) {
      print('Error transferring leadership: $e');
      return false;
    }
  }

  Future<bool> removeMember(String partyId, String memberId) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Only leader can remove members
        if (party.leaderId != _currentUserId) return false;
        
        // Can't remove leader
        if (party.isLeader(memberId)) return false;
        
        // Check if user is a member
        if (!party.isMember(memberId)) return false;
        
        final updatedParty = party.removeMember(memberId);
        transaction.update(partyRef, updatedParty.toFirestore());
        
        // Remove party from member's memberships
        final memberRef = _usersCollection.doc(memberId);
        transaction.update(memberRef, {
          'parties.$partyId': FieldValue.delete(),
          'activePartyCount': FieldValue.increment(-1),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      });
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  // Invitation System
  Future<String?> createInvitation(String partyId, String inviteeEmail) async {
    if (_currentUserId == null) return null;

    try {
      // Check if party exists and user is a member
      final partyDoc = await _partiesCollection.doc(partyId).get();
      if (!partyDoc.exists) return null;
      
      final party = MultiParty.fromFirestore(partyDoc);
      if (!party.isMember(_currentUserId!)) return null;
      
      // Check if invitation already exists
      final existingInvites = await _invitesCollection
          .where('partyId', isEqualTo: partyId)
          .where('inviteeEmail', isEqualTo: inviteeEmail)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (existingInvites.docs.isNotEmpty) return null;
      
      // Create invitation
      final inviteData = {
        'partyId': partyId,
        'partyName': party.name,
        'inviterEmail': _auth.currentUser?.email ?? '',
        'inviterId': _currentUserId!,
        'inviteeEmail': inviteeEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      };
      
      final inviteRef = await _invitesCollection.add(inviteData);
      return inviteRef.id;
    } catch (e) {
      print('Error creating invitation: $e');
      return null;
    }
  }

  Future<bool> acceptInvitation(String inviteId) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final inviteRef = _invitesCollection.doc(inviteId);
        final inviteDoc = await transaction.get(inviteRef);
        
        if (!inviteDoc.exists) return false;
        
        final inviteData = inviteDoc.data()!;
        final partyId = inviteData['partyId'] as String;
        
        // Check if invitation is valid
        if (inviteData['status'] != 'pending') return false;
        if (inviteData['inviteeEmail'] != _auth.currentUser?.email) return false;
        
        final expiresAt = (inviteData['expiresAt'] as Timestamp).toDate();
        if (DateTime.now().isAfter(expiresAt)) {
          // Mark as expired
          transaction.update(inviteRef, {'status': 'expired'});
          return false;
        }
        
        // Join the party
        final success = await joinParty(partyId, _currentUserId!);
        if (!success) return false;
        
        // Mark invitation as accepted
        transaction.update(inviteRef, {
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      });
    } catch (e) {
      print('Error accepting invitation: $e');
      return false;
    }
  }

  Future<bool> declineInvitation(String inviteId) async {
    try {
      await _invitesCollection.doc(inviteId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error declining invitation: $e');
      return false;
    }
  }

  // Stream Methods
  Stream<List<MultiParty>> streamUserParties() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _usersCollection.doc(_currentUserId!).snapshots(includeMetadataChanges: true).map((userDoc) {
      if (!userDoc.exists) return [];
      
      final userData = userDoc.data()!;
      final parties = userData['parties'] as Map<String, dynamic>? ?? {};
      final partyIds = parties.keys.toList();
      
      // Simple debug
      print('User has ${partyIds.length} parties: $partyIds');
      return partyIds;
    }).asyncExpand((partyIds) {
      if (partyIds.isEmpty) return Stream.value(<MultiParty>[]);
      
      return _partiesCollection
          .where(FieldPath.documentId, whereIn: partyIds)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            print('Found ${snapshot.docs.length} party docs for ${partyIds.length} IDs');
            for (final doc in snapshot.docs) {
              print('Party found: ${doc.id} - ${doc.data()['name']}');
            }
            
            return snapshot.docs
                .map((doc) => MultiParty.fromFirestore(doc))
                .toList();
          });
    });
  }

  Stream<MultiParty?> streamParty(String partyId) {
    return _partiesCollection.doc(partyId).snapshots().map((doc) {
      return doc.exists ? MultiParty.fromFirestore(doc) : null;
    });
  }

  Stream<List<Map<String, dynamic>>> streamPendingInvitations() {
    if (_currentUserId == null || _auth.currentUser?.email == null) {
      return Stream.value([]);
    }

    return _invitesCollection
        .where('inviteeEmail', isEqualTo: _auth.currentUser!.email!)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Stream<List<Map<String, dynamic>>> streamSentInvitations(String partyId) {
    return _invitesCollection
        .where('partyId', isEqualTo: partyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Utility Methods
  Future<UserModel?> getUserModel(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getting user model: $e');
      return null;
    }
  }

  Future<MultiParty?> getParty(String partyId) async {
    try {
      final doc = await _partiesCollection.doc(partyId).get();
      return doc.exists ? MultiParty.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getting party: $e');
      return null;
    }
  }

  Future<List<MultiParty>> getUserParties() async {
    if (_currentUserId == null) return [];

    try {
      // Force server read to bypass cache
      final userDoc = await _usersCollection.doc(_currentUserId!).get(const GetOptions(source: Source.server));
      
      if (!userDoc.exists) return [];
      
      final userData = userDoc.data()!;
      final parties = userData['parties'] as Map<String, dynamic>? ?? {};
      final partyIds = parties.keys.toList();
      
      print('FORCE REFRESH: User has ${partyIds.length} party IDs: $partyIds');
      
      if (partyIds.isEmpty) return [];
      
      // Force server read for parties too
      final partyDocs = await _partiesCollection
          .where(FieldPath.documentId, whereIn: partyIds)
          .get(const GetOptions(source: Source.server));
      
      print('FORCE REFRESH: Found ${partyDocs.docs.length} party documents');
      for (final doc in partyDocs.docs) {
        print('FORCE REFRESH: Party ${doc.id} - ${doc.data()['name']}');
      }
      
      return partyDocs.docs
          .map((doc) => MultiParty.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user parties: $e');
      return [];
    }
  }

  // Challenge Management Methods
  
  /// Party leader initiates challenge setup phase
  Future<bool> setupChallenge(String partyId, DateTime startDate, DateTime endDate) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Only leader can setup challenge
        if (party.leaderId != _currentUserId) return false;
        
        // Don't allow setup if challenge already exists
        if (party.hasActiveChallenge) return false;
        
        final challengeId = 'challenge_${DateTime.now().millisecondsSinceEpoch}';
        
        final challenge = ChallengeState(
          id: challengeId,
          status: ChallengeStatus.setup,
          startDate: startDate,
          endDate: endDate,
        );

        final updatedParty = party.copyWith(
          activeChallenge: challenge,
          lastActivityAt: DateTime.now(),
        );
        
        transaction.update(partyRef, updatedParty.toFirestore());
        
        return true;
      });
    } catch (e) {
      print('Error setting up challenge: $e');
      return false;
    }
  }

  /// User locks in their goals and wager for the challenge
  Future<bool> lockInForChallenge(String partyId, double wagerAmount) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Must be a member
        if (!party.isMember(_currentUserId!)) return false;
        
        // Must have challenge in setup
        if (!party.hasChallengeInSetup) return false;
        
        // Update challenge state
        final updatedChallenge = party.activeChallenge!.lockInUser(_currentUserId!, wagerAmount);
        final updatedParty = party.copyWith(
          activeChallenge: updatedChallenge,
          lastActivityAt: DateTime.now(),
        );
        
        transaction.update(partyRef, updatedParty.toFirestore());
        
        return true;
      });
    } catch (e) {
      print('Error locking in for challenge: $e');
      return false;
    }
  }

  /// User opts out of the challenge
  Future<bool> optOutOfChallenge(String partyId) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Must be a member
        if (!party.isMember(_currentUserId!)) return false;
        
        // Must have challenge in setup
        if (!party.hasChallengeInSetup) return false;
        
        // Update challenge state
        final updatedChallenge = party.activeChallenge!.optOutUser(_currentUserId!);
        final updatedParty = party.copyWith(
          activeChallenge: updatedChallenge,
          lastActivityAt: DateTime.now(),
        );
        
        transaction.update(partyRef, updatedParty.toFirestore());
        
        return true;
      });
    } catch (e) {
      print('Error opting out of challenge: $e');
      return false;
    }
  }

  /// Party leader starts the challenge (moves from setup to active)
  Future<bool> startChallenge(String partyId) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Only leader can start challenge
        if (party.leaderId != _currentUserId) return false;
        
        // Must have challenge in setup and ready to start
        if (!party.hasChallengeInSetup || !party.canStartChallenge) return false;
        
        // Update challenge status
        final updatedChallenge = party.activeChallenge!.copyWith(
          status: ChallengeStatus.active,
        );
        
        final updatedParty = party.copyWith(
          activeChallenge: updatedChallenge,
          currentChallengeId: updatedChallenge.id,
          lastActivityAt: DateTime.now(),
        );
        
        transaction.update(partyRef, updatedParty.toFirestore());
        
        return true;
      });
    } catch (e) {
      print('Error starting challenge: $e');
      return false;
    }
  }

  /// Cancel/clear the challenge (only in setup phase)
  Future<bool> cancelChallenge(String partyId) async {
    if (_currentUserId == null) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final partyRef = _partiesCollection.doc(partyId);
        final partyDoc = await transaction.get(partyRef);
        
        if (!partyDoc.exists) return false;
        
        final party = MultiParty.fromFirestore(partyDoc);
        
        // Only leader can cancel challenge
        if (party.leaderId != _currentUserId) return false;
        
        // Can only cancel in setup phase
        if (!party.hasChallengeInSetup) return false;
        
        final updatedParty = party.copyWith(
          activeChallenge: null,
          currentChallengeId: null,
          lastActivityAt: DateTime.now(),
        );
        
        transaction.update(partyRef, updatedParty.toFirestore());
        
        return true;
      });
    } catch (e) {
      print('Error canceling challenge: $e');
      return false;
    }
  }
}