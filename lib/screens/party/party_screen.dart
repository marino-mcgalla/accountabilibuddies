import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _partyNameController = TextEditingController();

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
            ? _buildCreatePartyScreen()
            : _buildPartyInfoScreen(),
      ),
    );
  }

  Widget _buildCreatePartyScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _partyNameController,
          decoration: const InputDecoration(
            labelText: "Party Name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _createParty,
          child: const Text("Create Party"),
        ),
      ],
    );
  }

  Widget _buildPartyInfoScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Party ID: $_partyId"),
        Text("Party Name: $_partyName"),
        const SizedBox(height: 20),
        const Text("Party Members",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._members.map((member) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(member),
            )),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _leaveParty,
          child: const Text("Leave Party"),
        ),
        ElevatedButton(
          onPressed: _closeParty,
          child: const Text("Close Party"),
        ),
      ],
    );
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
}
