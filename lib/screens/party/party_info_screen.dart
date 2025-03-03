import 'package:auth_test/features/party/widgets/member_item_widget.dart';
import 'package:flutter/material.dart';
import '../../features/common/widgets/compact_progress_tracker.dart';
import '../../features/party/providers/party_provider.dart';
import 'package:provider/provider.dart';
import '../../features/goals/models/goal_model.dart';

class PartyInfoScreen extends StatelessWidget {
  final String partyId;
  final String partyName;
  final List<String> members;
  final Function() leaveParty;
  final Function() closeParty;

  const PartyInfoScreen({
    required this.partyId,
    required this.partyName,
    required this.members,
    required this.leaveParty,
    required this.closeParty,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when partyMemberGoals changes
    return Selector<PartyProvider, Map<String, List<Goal>>>(
      selector: (_, provider) => provider.partyMemberGoals,
      builder: (context, partyMemberGoals, child) {
        final partyProvider =
            Provider.of<PartyProvider>(context, listen: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Party: $partyName",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Text(
              "Members",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...members.map((memberId) => MemberItem(
                  memberId: memberId,
                  memberDetails: partyProvider.memberDetails[memberId],
                  goals: partyMemberGoals[memberId] ?? [],
                )),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
// Replace the existing buttons row with this PopupMenuButton

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'leave') {
                    leaveParty();
                  } else if (value == 'close') {
                    closeParty();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings),
                      const SizedBox(width: 8),
                      Text(
                        'Party Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  // Leave party option only for non-leaders
                  if (!partyProvider.isCurrentUserPartyLeader)
                    const PopupMenuItem<String>(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app),
                          SizedBox(width: 10),
                          Text('Leave Party'),
                        ],
                      ),
                    ),
                  // Close party option only for leaders
                  if (partyProvider.isCurrentUserPartyLeader)
                    const PopupMenuItem<String>(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Close Party',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
