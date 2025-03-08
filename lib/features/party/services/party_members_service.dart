import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling party member-related operations
class PartyMembersService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PartyMembersService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Fetch details for a list of members
  Future<Map<String, Map<String, dynamic>>> fetchMemberDetails(
      List<String> members) async {
    Map<String, Map<String, dynamic>> memberDetails = {};

    for (String memberId in members) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        memberDetails[memberId] = userDoc.data() as Map<String, dynamic>;
      }
    }

    return memberDetails;
  }

  /// Send an invite to a user by email
  Future<bool> sendInvite(String inviteeEmail, String partyId) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || inviteeEmail.isEmpty) {
      return false;
    }

    QuerySnapshot userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: inviteeEmail)
        .get();

    if (userQuery.docs.isEmpty) {
      return false;
    }

    String inviteeId = userQuery.docs.first.id;

    await _firestore.collection('invites').add({
      'inviterId': currentUserId,
      'inviteeId': inviteeId,
      'partyId': partyId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// Accept an invite to join a party
  Future<void> acceptInvite(String inviteId, String partyId) async {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('invites').doc(inviteId).update({
      'status': 'accepted',
    });

    await _firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    await _firestore.collection('parties').doc(partyId).update({
      'members': FieldValue.arrayUnion([currentUserId]),
    });
  }

  /// Cancel a pending invite
  Future<void> cancelInvite(String inviteId) async {
    await _firestore.collection('invites').doc(inviteId).delete();
  }

  /// Stream of incoming pending invites
  Stream<QuerySnapshot> fetchIncomingPendingInvites() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      // Create a StreamController to return an empty stream
      final controller = StreamController<QuerySnapshot>.broadcast();
      // Close the controller immediately to avoid memory leaks
      controller.close();
      return controller.stream;
    }

    return _firestore
        .collection('invites')
        .where('inviteeId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Stream of outgoing pending invites
  Stream<QuerySnapshot> fetchOutgoingPendingInvites(String partyId) {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      // Create a StreamController to return an empty stream
      final controller = StreamController<QuerySnapshot>.broadcast();
      // Close the controller immediately to avoid memory leaks
      controller.close();
      return controller.stream;
    }

    return _firestore
        .collection('invites')
        .where('inviterId', isEqualTo: currentUserId)
        .where('partyId', isEqualTo: partyId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Future<void> leaveParty(String partyId) async {
  //   String? currentUserId = _auth.currentUser?.uid;
  //   if (currentUserId == null) {
  //     throw Exception('User not logged in');
  //   }

  //   await _firestore.collection('users').doc(currentUserId).update({
  //     'partyId': FieldValue.delete(),
  //   });

  //   await _firestore.collection('parties').doc(partyId).update({
  //     'members': FieldValue.arrayRemove([currentUserId]),
  //   });
  // }

  // /// Close an entire party (for party owner)
  // Future<void> closeParty(String partyId, List<String> members) async {
  //   String? currentUserId = _auth.currentUser?.uid;
  //   if (currentUserId == null) {
  //     throw Exception('User not logged in');
  //   }

  //   // Delete the party document
  //   await _firestore.collection('parties').doc(partyId).delete();

  //   // Remove partyId from all members
  //   for (String memberId in members) {
  //     await _firestore.collection('users').doc(memberId).update({
  //       'partyId': FieldValue.delete(),
  //     });
  //   }
  // }
}
