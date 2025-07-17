import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SimplePartyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Simple party creation - just create party doc and add user to members
  Future<String?> createParty(String name) async {
    if (currentUserId == null) {
      
      return null;
    }

    try {
      final partyDoc = _firestore.collection('parties').doc();
      
      
      await partyDoc.set({
        'id': partyDoc.id,
        'name': name,
        'leaderId': currentUserId,
        'members': [currentUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'maxMembers': 10,
        'isActive': true,
      });

      
      return partyDoc.id;
    } catch (e) {
      
      return null;
    }
  }

  // Get party details by ID
  Future<Map<String, dynamic>?> getPartyById(String partyId) async {
    try {
      final doc = await _firestore.collection('parties').doc(partyId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          'name': doc.data()!['name'] ?? '',
          'leaderId': doc.data()!['leaderId'] ?? '',
          'members': List<String>.from(doc.data()!['members'] ?? []),
          'memberCount': doc.data()!['memberCount'] ?? 0,
          'maxMembers': doc.data()!['maxMembers'] ?? 10,
          'isActive': doc.data()!['isActive'] ?? true,
          'createdAt': doc.data()!['createdAt'],
        };
      }
      return null;
    } catch (e) {
      
      return null;
    }
  }

  // Join party (add user to members array)
  Future<bool> joinParty(String partyId) async {
    if (currentUserId == null) return false;

    try {
      await _firestore.collection('parties').doc(partyId).update({
        'members': FieldValue.arrayUnion([currentUserId]),
        'memberCount': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Leave party (remove user from members array)
  Future<bool> leaveParty(String partyId) async {
    if (currentUserId == null) return false;

    try {
      await _firestore.collection('parties').doc(partyId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
        'memberCount': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Remove member from party (leader only)
  Future<bool> removeMember(String partyId, String memberId) async {
    if (currentUserId == null) return false;

    try {
      // Check if current user is the leader
      final party = await getPartyById(partyId);
      if (party == null || party['leaderId'] != currentUserId) {
        return false;
      }

      await _firestore.collection('parties').doc(partyId).update({
        'members': FieldValue.arrayRemove([memberId]),
        'memberCount': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Delete party (leader only)
  Future<bool> deleteParty(String partyId) async {
    if (currentUserId == null) return false;

    try {
      // Check if current user is the leader
      final party = await getPartyById(partyId);
      if (party == null || party['leaderId'] != currentUserId) {
        return false;
      }

      await _firestore.collection('parties').doc(partyId).delete();
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Simple party list - get all parties where user is a member
  Stream<List<Map<String, dynamic>>> getUserPartiesStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('parties')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          
          return snapshot.docs.map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'] ?? '',
                'leaderId': doc.data()['leaderId'] ?? '',
                'members': List<String>.from(doc.data()['members'] ?? []),
                'memberCount': doc.data()['memberCount'] ?? 0,
                'maxMembers': doc.data()['maxMembers'] ?? 10,
                'isActive': doc.data()['isActive'] ?? true,
                'activeChallenge': doc.data()['activeChallenge'],
              }).toList();
        });
  }

  // Simple party list - get all parties where user is a member (one-time fetch)
  Future<List<Map<String, dynamic>>> getUserParties() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('parties')
          .where('members', arrayContains: currentUserId)
          .get();

      return snapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc.data()['name'] ?? '',
            'leaderId': doc.data()['leaderId'] ?? '',
            'members': List<String>.from(doc.data()['members'] ?? []),
            'activeChallenge': doc.data()['activeChallenge'],
          }).toList();
    } catch (e) {
      
      return [];
    }
  }

  // Send party invitation
  Future<bool> sendInvitation(String partyId, String inviteeEmail) async {
    if (currentUserId == null) return false;

    try {
      // Check if current user is the leader
      final party = await getPartyById(partyId);
      if (party == null || party['leaderId'] != currentUserId) {
        return false;
      }

      // Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return false; // User not found
      }

      final inviteeId = userQuery.docs.first.id;

      // Check if user is already a member
      if (party['members'].contains(inviteeId)) {
        return false; // Already a member
      }

      // Create invitation
      await _firestore.collection('invitations').add({
        'partyId': partyId,
        'partyName': party['name'],
        'inviterId': currentUserId,
        'inviteeId': inviteeId,
        'inviteeEmail': inviteeEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Get received invitations for current user
  Stream<List<Map<String, dynamic>>> getReceivedInvitationsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('invitations')
        .where('inviteeId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              'partyId': doc.data()['partyId'] ?? '',
              'partyName': doc.data()['partyName'] ?? '',
              'inviterId': doc.data()['inviterId'] ?? '',
              'status': doc.data()['status'] ?? 'pending',
              'createdAt': doc.data()['createdAt'],
            }).toList());
  }

  // Accept invitation
  Future<bool> acceptInvitation(String invitationId, String partyId) async {
    if (currentUserId == null) return false;

    try {
      // Update invitation status
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Add user to party
      await joinParty(partyId);

      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Decline invitation
  Future<bool> declineInvitation(String invitationId) async {
    if (currentUserId == null) return false;

    try {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Get user data by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          'email': doc.data()!['email'] ?? '',
          'username': doc.data()!['username'],
          'displayName': doc.data()!['displayName'],
        };
      }
      return null;
    } catch (e) {
      
      return null;
    }
  }

  // Get multiple users by IDs
  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final users = <Map<String, dynamic>>[];
      
      // Firestore 'in' queries are limited to 10 items, so we need to batch
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final query = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        users.addAll(query.docs.map((doc) => {
              'id': doc.id,
              'email': doc.data()['email'] ?? '',
              'username': doc.data()['username'],
              'displayName': doc.data()['displayName'],
            }));
      }
      
      return users;
    } catch (e) {
      
      return [];
    }
  }
}