import 'package:cloud_firestore/cloud_firestore.dart';
import 'party_provider.dart';

extension PartyActions on PartyProvider {
  Future<void> createParty(String partyName) async {
    String currentUserId = auth.currentUser?.uid ?? "";

    if (partyName.isEmpty) {
      return;
    }

    DocumentReference partyRef = await firestore.collection('parties').add({
      'createdBy': currentUserId,
      'partyOwner': currentUserId,
      'members': [currentUserId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    String partyId = partyRef.id;

    await partyRef.update({'partyName': partyName});

    this.partyId = partyId;
    this.partyName = partyName;
    this.members = [currentUserId];

    await firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    fetchMemberDetails();
    triggerNotifyListeners(); // Call the public method to notify listeners
  }

  Future<void> leaveParty() async {
    String currentUserId = auth.currentUser?.uid ?? "";

    if (members.length == 1) {
      await closeParty();
    } else {
      await firestore.collection('users').doc(currentUserId).update({
        'partyId': FieldValue.delete(),
      });

      await firestore.collection('parties').doc(partyId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });

      partyId = null;
      partyName = null;
      members = [];
      memberDetails = {};
      triggerNotifyListeners(); // Call the public method to notify listeners
    }
  }

  Future<void> closeParty() async {
    if (partyId != null) {
      await firestore.collection('parties').doc(partyId).delete();

      for (String memberId in members) {
        await firestore.collection('users').doc(memberId).update({
          'partyId': FieldValue.delete(),
        });
      }

      partyId = null;
      partyName = null;
      members = [];
      memberDetails = {};
      triggerNotifyListeners(); // Call the public method to notify listeners
    }
  }

  Future<void> updateCounter(String memberId, int value) async {
    DocumentReference userRef = firestore.collection('users').doc(memberId);
    DocumentSnapshot userDoc = await userRef.get();

    if (userDoc.exists) {
      int currentCounter = userDoc['counter'] ?? 0;
      await userRef.update({'counter': currentCounter + value});
      triggerNotifyListeners(); // Call the public method to notify listeners
    }
  }

  Stream<QuerySnapshot> fetchIncomingPendingInvites() {
    String currentUserId = auth.currentUser?.uid ?? "";
    return firestore
        .collection('invites')
        .where('inviteeId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> fetchOutgoingPendingInvites() {
    String currentUserId = auth.currentUser?.uid ?? "";
    return firestore
        .collection('invites')
        .where('inviterId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptInvite(String inviteId, String partyId) async {
    String currentUserId = auth.currentUser?.uid ?? "";

    await firestore.collection('invites').doc(inviteId).update({
      'status': 'accepted',
    });

    await firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    await firestore.collection('parties').doc(partyId).update({
      'members': FieldValue.arrayUnion([currentUserId]),
    });

    this.partyId = partyId;
    fetchMemberDetails();
    triggerNotifyListeners(); // Call the public method to notify listeners
  }

  Future<void> sendInvite() async {
    String currentUserId = auth.currentUser?.uid ?? "";
    String inviteeEmail = inviteController.text;

    if (inviteeEmail.isEmpty) {
      return;
    }

    QuerySnapshot userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: inviteeEmail)
        .get();

    if (userQuery.docs.isNotEmpty) {
      String inviteeId = userQuery.docs.first.id;

      await firestore.collection('invites').add({
        'inviterId': currentUserId,
        'inviteeId': inviteeId,
        'partyId': this.partyId ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      inviteController.clear();
      triggerNotifyListeners(); // Call the public method to notify listeners
    }
  }

  Future<void> cancelInvite(String inviteId) async {
    await firestore.collection('invites').doc(inviteId).delete();
    triggerNotifyListeners(); // Call the public method to notify listeners
  }
}
