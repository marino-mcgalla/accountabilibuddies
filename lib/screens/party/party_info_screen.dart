import 'package:flutter/material.dart';
import '../../refactor/compact_progress_tracker.dart';
import '../../refactor/party_provider.dart';
import 'package:provider/provider.dart';
import '../../refactor/goal_model.dart';

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
            Text("Party ID: $partyId"),
            Text("Party Name: $partyName"),
            const SizedBox(height: 20),
            ...members.map((memberId) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (partyProvider.memberDetails.containsKey(memberId))
                      Text(partyProvider.memberDetails[memberId]?['email'] ??
                          ''),

                    // Directly use partyMemberGoals instead of FutureBuilder
                    if (partyMemberGoals.containsKey(memberId) &&
                        partyMemberGoals[memberId]!.isNotEmpty)
                      Column(
                        children: partyMemberGoals[memberId]!
                            .map((goal) => CompactProgressTracker(goal: goal))
                            .toList(),
                      )
                    else
                      const Text('No goals found'),

                    const SizedBox(height: 10),
                  ],
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: leaveParty,
              child: const Text("Leave Party"),
            ),
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
