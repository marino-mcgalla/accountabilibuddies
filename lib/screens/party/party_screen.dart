import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _inviteController = TextEditingController();
  List<String> _members = []; // Will be fetched from Firestore
  List<String> _pendingInvites = []; // Will be fetched from Firestore

  // Fetch current party members and pending invites
  Future<void> _fetchPartyData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Fetch party members
      DocumentSnapshot partyDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('party')
          .doc('partyDetails')
          .get();

      if (partyDoc.exists) {
        setState(() {
          _members = List<String>.from(partyDoc['members'] ?? []);
          _pendingInvites = List<String>.from(partyDoc['pendingInvites'] ?? []);
        });
      }
    }
  }

  // Send an invite to a user
  void _sendInvite() {
    String invitee = _inviteController.text.trim();
    if (invitee.isNotEmpty) {
      User? user = _auth.currentUser;
      if (user != null) {
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('party')
            .doc('partyDetails')
            .update({
          'pendingInvites': FieldValue.arrayUnion([invitee]),
        });

        setState(() {
          _pendingInvites.add(invitee);
        });
        _inviteController.clear();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPartyData();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text("Pending Invites",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._pendingInvites.map((invite) => ListTile(
                  leading: const Icon(Icons.hourglass_empty),
                  title: Text(invite),
                )),
          ],
        ),
      ),
    );
  }
}
