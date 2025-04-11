import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InviteList extends StatelessWidget {
  final Stream<QuerySnapshot> inviteStream;
  final String title;
  final Function(String, String) onAction;
  final bool isOutgoing;

  const InviteList({
    required this.inviteStream,
    required this.title,
    required this.onAction,
    required this.isOutgoing,
    Key? key,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: inviteStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No pending invites.");
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                var invite = doc.data() as Map<String, dynamic>;
                String userId =
                    isOutgoing ? invite['inviteeId'] : invite['inviterId'];
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUserDetails(userId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text("Loading..."),
                      );
                    }
                    if (!userSnapshot.hasData) {
                      return const ListTile(
                        leading: Icon(Icons.error),
                        title: Text("Error loading user details"),
                      );
                    }
                    var userDetails = userSnapshot.data!;
                    String displayName = userDetails['username'] ??
                        userDetails['email'] ??
                        'Unknown';
                    return ListTile(
                      leading: const Icon(Icons.mail),
                      title: Text(isOutgoing
                          ? "Sent to $displayName"
                          : "Invite from $displayName"),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            onAction(doc.id, invite['partyId'] ?? ''),
                        child: Text(isOutgoing ? "Cancel" : "Accept"),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
