import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final TextEditingController _inviteController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _members = ["User1", "User2", "User3"]; // Temporary mock data

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Party")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Party Members",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._members.map((member) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(member),
                )),
            const Divider(),
            const Text("Invite a User",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inviteController,
                    decoration: const InputDecoration(
                      labelText: "Enter username or email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendInvite,
                  child: const Text("Invite"),
                ),
              ],
            ),
            const Divider(),
            const Text("Pending Outgoing Invites",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('invites')
                  .where('senderId', isEqualTo: currentUserId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var sentInvites = snapshot.data!.docs;

                if (sentInvites.isEmpty) {
                  return const Text("No pending outgoing invites.");
                }

                return Column(
                  children: sentInvites.map((doc) {
                    var invite = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.send),
                      title: Text("Sent to ${invite['receiverId']}"),
                      trailing: ElevatedButton(
                        onPressed: () => _cancelInvite(doc.id),
                        child: const Text("Cancel"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(),
            const Text("Pending Incoming Invites",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('invites')
                  .where('receiverId', isEqualTo: currentUserId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var receivedInvites = snapshot.data!.docs;
                if (receivedInvites.isEmpty) {
                  return const Text("No pending incoming invites.");
                }

                return Column(
                  children: receivedInvites.map((doc) {
                    var invite = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.hourglass_empty),
                      title: Text("Invite from ${invite['senderId']}"),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            _acceptInvite(doc.id, invite['partyId']),
                        child: const Text("Accept"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _createParty() async {
    String currentUserId = _auth.currentUser?.uid ?? "";

    DocumentReference partyRef = await _firestore.collection('parties').add({
      'createdBy': currentUserId,
      'members': [currentUserId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    String partyId = partyRef.id;

    await _firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    return partyId;
  }

  void _sendInvite() async {
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
    String partyId = "somePartyId";

    await _firestore.collection('invites').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'partyId': partyId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _inviteController.clear();
  }

  void _acceptInvite(String inviteId, String partyId) async {
    String currentUserId = _auth.currentUser?.uid ?? "";

    DocumentReference partyRef = _firestore.collection('parties').doc(partyId);

    var partyDoc = await partyRef.get();
    if (!partyDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Party not found. It may have been deleted.")),
      );
      return;
    }

    await partyRef.update({
      'members': FieldValue.arrayUnion([currentUserId])
    });

    await _firestore.collection('invites').doc(inviteId).delete();
    setState(() {});
  }

  void _cancelInvite(String inviteId) async {
    await _firestore.collection('invites').doc(inviteId).delete();
    setState(() {});
  }
}
