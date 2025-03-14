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
    final canManage = !isCurrentUser && partyProvider.isCurrentUserPartyLeader;

    double memberWager = 0;
    if (partyProvider.hasActiveChallenge) {
      memberWager = partyProvider.getMemberWager(memberId);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias, // Fix corner clipping issue
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Theme(
        // Ensure ExpansionTile doesn't change background
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: GestureDetector(
          onLongPress: canManage
              ? () {
                  // Show the popup menu on long press
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final position = renderBox.localToGlobal(Offset.zero);
                  final size = renderBox.size;

                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      position.dx,
                      position.dy,
                      position.dx + size.width,
                      position.dy + size.height,
                    ),
                    items: [
                      if (!isLeader)
                        PopupMenuItem<String>(
                          value: 'transfer',
                          child: Row(
                            children: const [
                              Icon(Icons.change_circle, size: 20),
                              SizedBox(width: 10),
                              Text('Transfer Leadership'),
                            ],
                          ),
                        ),
                      PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: const [
                            Icon(Icons.person_remove,
                                size: 20, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Remove from Party',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ).then((value) {
                    if (value == 'transfer' && !isLeader) {
                      _showTransferDialog(context, partyProvider);
                    } else if (value == 'remove') {
                      _showRemoveDialog(context, partyProvider);
                    }
                  });
                }
              : null,
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        memberDetails?['email'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isLeader)
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: 18,
                            semanticLabel: 'Party Leader',
                          ),
                        ),
                    ],
                  ),
                ),
                if (partyProvider.hasActiveChallenge)
                  Text(
                    "\$${memberWager.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontStyle:
                          memberWager > 0 ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.transparent,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (goals.isNotEmpty)
                      ...goals.map((goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CompactProgressTracker(goal: goal),
                          )),
                    if (goals.isEmpty)
                      const Text('No goals',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
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
