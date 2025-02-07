import 'package:flutter/material.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final TextEditingController _inviteController = TextEditingController();
  List<String> _members = ["User1", "User2", "User3"]; // Temporary mock data
  List<String> _pendingInvites = ["PendingUser1", "PendingUser2"]; // Mock data

  void _sendInvite() {
    String invitee = _inviteController.text.trim();
    if (invitee.isNotEmpty) {
      setState(() {
        _pendingInvites.add(invitee);
      });
      _inviteController.clear();
    }
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
