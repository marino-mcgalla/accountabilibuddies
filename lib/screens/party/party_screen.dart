import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_party_screen.dart';
import 'party_info_screen.dart';
import '../../widgets/invite_list.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();

  String? _partyId;
  String? _partyName;
  List<String> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserPartyStatus();
  }

  Future<void> _checkUserPartyStatus() async {
    setState(() {
      _isLoading = true;
    });

    String currentUserId = _auth.currentUser?.uid ?? "";
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUserId).get();

    if (userDoc.exists &&
        userDoc.data() != null &&
        (userDoc.data() as Map<String, dynamic>).containsKey('partyId')) {
      String partyId = (userDoc.data() as Map<String, dynamic>)['partyId'];
      DocumentSnapshot partyDoc =
          await _firestore.collection('parties').doc(partyId).get();

      if (partyDoc.exists) {
        setState(() {
          _partyId = partyId;
          _partyName = partyDoc['partyName'];
          _members = List<String>.from(partyDoc['members']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Stream<QuerySnapshot> _fetchOutgoingPendingInvites() {
    String currentUserId = _auth.currentUser?.uid ?? "";
    return _firestore
        .collection('invites')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> _fetchIncomingPendingInvites() {
    String currentUserId = _auth.currentUser?.uid ?? "";
    return _firestore
        .collection('invites')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> _cancelInvite(String inviteId) async {
    await _firestore.collection('invites').doc(inviteId).delete();
    setState(() {});
  }

  Future<void> _acceptInvite(String inviteId, String? partyId) async {
    if (partyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Party ID is null")),
      );
      return;
    }

    String currentUserId = _auth.currentUser?.uid ?? "";

    await _firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    await _firestore.collection('parties').doc(partyId).update({
      'members': FieldValue.arrayUnion([currentUserId]),
    });

    await _firestore.collection('invites').doc(inviteId).delete();

    setState(() {
      _partyId = partyId;
    });

    _checkUserPartyStatus();
  }

  Future<void> _updateCounter(String userId, int delta) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    DocumentSnapshot userDoc = await userRef.get();
    if (userDoc.exists) {
      int currentCounter = userDoc['counter'] ?? 0;
      await userRef.update({'counter': currentCounter + delta});
    }
  }

  Future<void> _createParty() async {
    String currentUserId = _auth.currentUser?.uid ?? "";
    String partyName = _partyNameController.text.trim();

    if (partyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a party name")),
      );
      return;
    }

    DocumentReference partyRef = await _firestore.collection('parties').add({
      'createdBy': currentUserId,
      'partyOwner': currentUserId,
      'members': [currentUserId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    String partyId = partyRef.id;

    await partyRef.update({'partyName': partyName});

    setState(() {
      _partyId = partyId;
      _partyName = partyName;
      _members = [currentUserId];
    });

    await _firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    _partyNameController.clear();
  }

  Future<void> _sendInvite() async {
    String inviteeEmail = _inviteController.text.trim();
    if (inviteeEmail.isEmpty) return;

    var usersQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: inviteeEmail)
        .get();

    if (usersQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not found")));
      return;
    }

    String receiverId = usersQuery.docs.first.id;
    String senderId = _auth.currentUser?.uid ?? "";

    await _firestore.collection('invites').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'partyId': _partyId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _inviteController.clear();
  }

  Future<void> _leaveParty() async {
    String currentUserId = _auth.currentUser?.uid ?? "";

    if (_members.length == 1) {
      // If the current user is the only member, close the party
      await _closeParty();
    } else {
      // Otherwise, just leave the party
      await _firestore.collection('users').doc(currentUserId).update({
        'partyId': FieldValue.delete(),
      });

      await _firestore.collection('parties').doc(_partyId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });

      setState(() {
        _partyId = null;
        _partyName = null;
        _members = [];
      });
    }
  }

  Future<void> _closeParty() async {
    if (_partyId != null) {
      await _firestore.collection('parties').doc(_partyId).delete();

      for (String memberId in _members) {
        await _firestore.collection('users').doc(memberId).update({
          'partyId': FieldValue.delete(),
        });
      }

      setState(() {
        _partyId = null;
        _partyName = null;
        _members = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Party")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Party")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _partyId == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CreatePartyScreen(
                    partyNameController: _partyNameController,
                    createParty: _createParty,
                  ),
                  const SizedBox(height: 20),
                  InviteList(
                    inviteStream: _fetchIncomingPendingInvites(),
                    title: "Incoming Pending Invites",
                    onAction: (inviteId, partyId) =>
                        _acceptInvite(inviteId, partyId),
                    isOutgoing: false,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PartyInfoScreen(
                    partyId: _partyId!,
                    partyName: _partyName!,
                    members: _members,
                    updateCounter: _updateCounter,
                    leaveParty: _leaveParty,
                    closeParty: _closeParty,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _inviteController,
                    decoration: const InputDecoration(
                      labelText: "Invite Member by Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendInvite,
                    child: const Text("Send Invite"),
                  ),
                  const SizedBox(height: 20),
                  InviteList(
                    inviteStream: _fetchOutgoingPendingInvites(),
                    title: "Outgoing Pending Invites",
                    onAction: (inviteId, _) => _cancelInvite(inviteId),
                    isOutgoing: true,
                  ),
                ],
              ),
      ),
    );
  }
}
