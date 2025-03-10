import 'dart:async';

import 'package:auth_test/features/goals/models/goal_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/party_model.dart';

class PartyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PartyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Returns a clean stream of party data that handles nested subscriptions internally
  Stream<Map<String, dynamic>?> getUserPartyStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(null);
    }

    // Create a broadcast StreamController for the combined party state
    final controller = StreamController<Map<String, dynamic>?>.broadcast();

    // Track both subscriptions for proper cleanup
    StreamSubscription? userSubscription;
    StreamSubscription? partySubscription;

    userSubscription = _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((userDoc) {
      // Cancel previous party subscription when user document changes
      partySubscription?.cancel();

      if (!userDoc.exists ||
          userDoc.data() == null ||
          !(userDoc.data() as Map<String, dynamic>).containsKey('partyId')) {
        controller.add(null); // User has no party
        return;
      }

      String partyId = (userDoc.data() as Map<String, dynamic>)['partyId'];

      // Create new subscription to the party document
      partySubscription = _firestore
          .collection('parties')
          .doc(partyId)
          .snapshots()
          .listen((partyDoc) {
        if (!partyDoc.exists || partyDoc.data() == null) {
          controller.add(null); // Party no longer exists
          return;
        }

        // Combine data into a single map with the party ID included
        final partyData = partyDoc.data() as Map<String, dynamic>;
        controller.add({'partyId': partyId, ...partyData});
      });
    });

    // Clean up both subscriptions when the stream is closed
    controller.onCancel = () {
      userSubscription?.cancel();
      partySubscription?.cancel();
    };

    return controller.stream;
  }

  Stream<List<Goal>> getMemberGoalsStream(String memberId) {
    return _firestore
        .collection('userGoals')
        .doc(memberId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      List<dynamic> goalsData = doc.data()?['goals'] ?? [];
      return goalsData.map((data) => Goal.fromMap(data)).toList();
    });
  }

  /// Create a new party with the given name and set the current user as owner
  Future<String> createParty(Party party) async {
    DocumentReference partyRef = _firestore.collection('parties').doc();
    await partyRef.set(party.toMap());
    return partyRef.id;
  }

  /// Update a user's party ID reference
  Future<void> updateUserPartyReference(String userId, String? partyId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'partyId': partyId});
  }

  /// Close a party and clean up all related data
  Future<void> closeParty(String partyId, List<String> memberIds) async {
    WriteBatch batch = _firestore.batch();

    //delete all pending invites for the party
    QuerySnapshot pendingInvites = await _firestore
        .collection('invites')
        .where('partyId', isEqualTo: partyId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in pendingInvites.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('parties').doc(partyId));

    for (String memberId in memberIds) {
      batch.update(_firestore.collection('users').doc(memberId), {
        'partyId': FieldValue.delete(),
      });
    }

    await batch.commit();
  }
}
