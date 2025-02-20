import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PartyInfoScreen extends StatelessWidget {
  final String partyId;
  final String partyName;
  final List<String> members;
  final Function(String, int) updateCounter;
  final Function() leaveParty;
  final Function() closeParty;

  const PartyInfoScreen({
    required this.partyId,
    required this.partyName,
    required this.members,
    required this.updateCounter,
    required this.leaveParty,
    required this.closeParty,
    super.key,
  });

  Stream<DocumentSnapshot> _fetchUserDetailsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  Stream<DocumentSnapshot> _fetchPartyDetailsStream(String partyId) {
    return FirebaseFirestore.instance
        .collection('parties')
        .doc(partyId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<DocumentSnapshot>(
      stream: _fetchPartyDetailsStream(partyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return const Center(
              child: Text("Party not found or has been closed"));
        }
        var partyDetails = snapshot.data!.data() as Map<String, dynamic>;
        String partyOwner = partyDetails['partyOwner'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Party ID: $partyId"),
            Text("Party Name: $partyName"),
            const SizedBox(height: 20),
            const Text("Party Members",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...members.map((member) => StreamBuilder<DocumentSnapshot>(
                  stream: _fetchUserDetailsStream(member),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text("Loading..."),
                      );
                    }
                    if (!snapshot.hasData ||
                        snapshot.data == null ||
                        !snapshot.data!.exists) {
                      return const ListTile(
                        leading: Icon(Icons.error),
                        title: Text("Error loading user details"),
                      );
                    }
                    var userDetails =
                        snapshot.data!.data() as Map<String, dynamic>;
                    String displayName = userDetails['username'] ??
                        userDetails['email'] ??
                        'Unknown';
                    int counter = userDetails['counter'] ?? 0;
                    bool isOwner = member == partyOwner;
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Row(
                        children: [
                          Text(displayName),
                          if (isOwner)
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (member != currentUserId)
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => updateCounter(member, -1),
                            ),
                          Text('Counter: $counter'),
                          if (member != currentUserId)
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => updateCounter(member, 1),
                            ),
                        ],
                      ),
                    );
                  },
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: leaveParty,
              child: const Text("Leave Party"),
            ),
            if (currentUserId == partyOwner)
              ElevatedButton(
                onPressed: closeParty,
                child: const Text("Close Party"),
              ),
          ],
        );
      },
    );
  }
}
