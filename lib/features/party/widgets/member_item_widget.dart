import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/widgets/compact_progress_tracker.dart';
import '../../goals/models/goal_model.dart';
import '../providers/party_provider.dart';

class MemberItem extends StatelessWidget {
  final String memberId;
  final Map<String, dynamic>? memberDetails;
  final List<Goal> goals;

  const MemberItem({
    Key? key,
    required this.memberId,
    required this.memberDetails,
    required this.goals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);
    final isLeader = memberId == partyProvider.partyLeaderId;
    final isCurrentUser = memberId == FirebaseAuth.instance.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Replace the existing admin buttons with this popup menu approach

            Row(
              children: [
                Expanded(
                  child: Text(
                    memberDetails?['email'] ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isLeader)
                  const Icon(
                    Icons.workspace_premium, // Crown/trophy icon
                    color: Colors.amber,
                    size: 24,
                    semanticLabel: 'Party Leader',
                  ),
                if (!isCurrentUser && partyProvider.isCurrentUserPartyLeader)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Manage Member',
                    onSelected: (value) {
                      if (value == 'transfer' && !isLeader) {
                        _showTransferDialog(context, partyProvider);
                      } else if (value == 'remove') {
                        _showRemoveDialog(context, partyProvider);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isLeader)
                        const PopupMenuItem<String>(
                          value: 'transfer',
                          child: Row(
                            children: [
                              Icon(Icons.change_circle, size: 20),
                              SizedBox(width: 10),
                              Text('Transfer Leadership'),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove,
                                size: 20, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Remove from Party',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (goals.isNotEmpty)
              ...goals.map((goal) => CompactProgressTracker(goal: goal)),
            if (goals.isEmpty)
              const Text('No goals',
                  style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  void _showTransferDialog(BuildContext context, PartyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Leadership'),
        content: Text(
            'Make ${memberDetails?['email'] ?? 'this user'} the party leader?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.transferLeadership(memberId);
              Navigator.pop(context);
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, PartyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Remove ${memberDetails?['email'] ?? 'this user'} from the party?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.removeMember(memberId);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
