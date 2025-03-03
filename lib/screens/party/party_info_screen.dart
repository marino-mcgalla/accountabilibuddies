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

            // Challenge status section (only show if there's an active challenge)
            if (partyProvider.hasActiveChallenge)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Active Challenge",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Started: ${partyProvider.challengeStartDate?.toString().substring(0, 10) ?? 'Unknown'}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Ends: ${partyProvider.challengeEndDate?.toString().substring(0, 10) ?? 'Unknown'}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (partyProvider.hasActiveChallenge) const SizedBox(height: 20),

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
            Align(
              alignment: Alignment.center,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'leave') {
                    leaveParty();
                  } else if (value == 'close') {
                    closeParty();
                  } else if (value == 'challengeDay') {
                    _showChallengeStartDayPicker(context);
                  } else if (value == 'startChallenge') {
                    _showStartChallengeConfirmation(context);
                  } else if (value == 'endChallenge') {
                    _showEndChallengeConfirmation(context);
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

                  // Challenge day configuration (leader only)
                  if (partyProvider.isCurrentUserPartyLeader)
                    PopupMenuItem<String>(
                      value: 'challengeDay',
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 10),
                          Text(
                              'Set Challenge Start Day (${partyProvider.challengeStartDayName})'),
                        ],
                      ),
                    ),

                  // Start challenge option (leader only, when no active challenge)
                  if (partyProvider.isCurrentUserPartyLeader &&
                      !partyProvider.hasActiveChallenge)
                    const PopupMenuItem<String>(
                      value: 'startChallenge',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Start New Week Challenge'),
                        ],
                      ),
                    ),

                  // End challenge option (leader only, when there is an active challenge)
                  if (partyProvider.isCurrentUserPartyLeader &&
                      partyProvider.hasActiveChallenge)
                    const PopupMenuItem<String>(
                      value: 'endChallenge',
                      child: Row(
                        children: [
                          Icon(Icons.stop, color: Colors.orange),
                          SizedBox(width: 10),
                          Text('End Current Week Challenge'),
                        ],
                      ),
                    ),

                  // Close party option (leader only)
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

  // Show dialog to select the challenge start day
  void _showChallengeStartDayPicker(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Challenge Start Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select which day of the week challenges will start:'),
            const SizedBox(height: 16),
            ...List.generate(7, (index) {
              final dayName = PartyProvider.dayNames[index];
              return ListTile(
                title: Text(dayName),
                leading: Radio<int>(
                  value: index,
                  groupValue: partyProvider.challengeStartDay,
                  onChanged: (int? value) {
                    Navigator.pop(context);
                    if (value != null) {
                      partyProvider.setChallengeStartDay(value);
                    }
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for starting a new challenge
  void _showStartChallengeConfirmation(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Weekly Challenge'),
        content: const Text(
            'This will begin a new week-long challenge. Members will set their goals for the week, '
            'and their progress will be tracked until the challenge ends.\n\n'
            'Are you ready to start the challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              partyProvider.startNewChallenge();
            },
            child: const Text('Start Challenge'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for ending the current challenge
  void _showEndChallengeConfirmation(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Weekly Challenge'),
        content: const Text(
            'This will finalize the current challenge. All unfinished goals will be marked as failed.\n\n'
            'Members will need to wait for you to start a new challenge before they can set new goals.\n\n'
            'Are you sure you want to end this week\'s challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              partyProvider.endCurrentChallenge();
            },
            child: const Text('End Challenge'),
          ),
        ],
      ),
    );
  }
}
