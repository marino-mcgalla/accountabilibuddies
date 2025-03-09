import 'package:auth_test/features/party/widgets/member_item_widget.dart';
import 'package:flutter/material.dart';
import '../../features/common/widgets/compact_progress_tracker.dart';
import '../../features/party/providers/party_provider.dart';
import '../../features/goals/providers/goals_provider.dart';
import 'package:provider/provider.dart';
import '../../features/goals/models/goal_model.dart';
import '../../features/common/utils/utils.dart';

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

            // Pending challenge section
            if (partyProvider.hasPendingChallenge)
              _buildPendingChallengeCard(context),

            // Active challenge section
            if (partyProvider.hasActiveChallenge &&
                !partyProvider.hasPendingChallenge)
              _buildActiveChallengeCard(context),

            if (partyProvider.hasActiveChallenge ||
                partyProvider.hasPendingChallenge)
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
                  } else if (value == 'initiateChallenge') {
                    _showInitiateChallengeDialog(context);
                  } else if (value == 'cancelChallenge') {
                    _showCancelChallengeDialog(context);
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

                  // Initiate challenge option (leader only, when no active/pending challenge)
                  if (partyProvider.isCurrentUserPartyLeader &&
                      !partyProvider.hasActiveChallenge)
                    const PopupMenuItem<String>(
                      value: 'initiateChallenge',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Prepare New Challenge'),
                        ],
                      ),
                    ),

                  // Cancel challenge preparation (leader only, when there's a pending challenge)
                  if (partyProvider.isCurrentUserPartyLeader &&
                      partyProvider.hasPendingChallenge)
                    const PopupMenuItem<String>(
                      value: 'cancelChallenge',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Cancel Challenge Preparation'),
                        ],
                      ),
                    ),

                  // End challenge option (leader only, when there is an active challenge)
                  if (partyProvider.isCurrentUserPartyLeader &&
                      partyProvider.hasActiveChallenge &&
                      !partyProvider.hasPendingChallenge)
                    const PopupMenuItem<String>(
                      value: 'endChallenge',
                      child: Row(
                        children: [
                          Icon(Icons.stop, color: Colors.orange),
                          SizedBox(width: 10),
                          Text('End Current Challenge'),
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

  // Build the pending challenge card
  Widget _buildPendingChallengeCard(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    return Card(
      elevation: 3,
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_outlined,
                    color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Challenge Preparation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              partyProvider.isCurrentUserPartyLeader
                  ? 'Members are reviewing and locking in their goals.'
                  : 'The party leader is preparing a new challenge. Make any final edits to your goals before locking in.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),

            // Member lock-in status (for leader)
            if (partyProvider.isCurrentUserPartyLeader)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Member Status:',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...members.map((memberId) {
                    final name = partyProvider.memberDetails[memberId]
                            ?['displayName'] ??
                        'Unknown';
                    final isLockedIn =
                        partyProvider.lockedInMembers.contains(memberId);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            isLockedIn
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isLockedIn ? Colors.green : Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(name,
                              style: TextStyle(
                                color: isLockedIn ? Colors.black : Colors.grey,
                              )),
                          Spacer(),
                          Text(isLockedIn ? 'Ready' : 'Waiting',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: isLockedIn ? Colors.green : Colors.grey,
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.cancel),
                        label: Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => _showCancelChallengeDialog(context),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.play_arrow),
                        label: Text('Start Challenge'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _confirmStartChallenge(context),
                      ),
                    ],
                  ),
                ],
              ),

            // Lock in button (for regular members)
            if (!partyProvider.isCurrentUserPartyLeader)
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(
                    partyProvider.isCurrentUserLockedIn
                        ? Icons.check
                        : Icons.lock_outline,
                  ),
                  label: Text(
                    partyProvider.isCurrentUserLockedIn
                        ? 'Goals Locked In'
                        : 'Lock In My Goals',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: partyProvider.isCurrentUserLockedIn
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: partyProvider.isCurrentUserLockedIn
                      ? null
                      : () => _lockInMemberGoals(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build the active challenge card
  Widget _buildActiveChallengeCard(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);

    return Container(
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
          if (partyProvider.isCurrentUserPartyLeader)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton.icon(
                icon: Icon(Icons.stop),
                label: Text('End Challenge'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
                onPressed: () => _showEndChallengeConfirmation(context),
              ),
            ),
        ],
      ),
    );
  }

  void _lockInMemberGoals(BuildContext context) async {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    // Check if there are active TEMPLATE goals (not challenge goals)
    final activeGoals =
        goalsProvider.goalTemplates.where((goal) => goal.active).toList();

    if (activeGoals.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No Goals to Lock In'),
          content: Text(
              'You need at least one active goal to participate in the challenge.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final shouldLockIn = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Lock In Goals'),
            content: Text(
                'Once locked in, your goals will be ready for the challenge.\n\n'
                'Active goals that will be included:\n'
                '${activeGoals.map((g) => '• ${g.goalName}').join('\n')}\n\n'
                'Ready to lock in?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Lock In'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLockIn) {
      Utils.showFeedback(context, 'Locking in goals...');

      try {
        await goalsProvider.lockInGoalsForChallenge(partyId);
        Utils.showFeedback(context, 'Goals locked in successfully');
      } catch (e) {
        Utils.showFeedback(context, 'Error locking in goals: $e',
            isError: true);
      }
    }
  }

  // Confirm starting the challenge
  void _confirmStartChallenge(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Challenge'),
        content: const Text(
            'This will officially start the challenge. Members who haven\'t locked in goals '
            'will need to do so immediately.\n\n'
            'Are you ready to begin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              Utils.showFeedback(context, 'Starting challenge...');
              partyProvider.confirmChallengeStart(context);
            },
            child: const Text('Start Now'),
          ),
        ],
      ),
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

  // Show dialog for initiating challenge preparation
  void _showInitiateChallengeDialog(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prepare New Challenge'),
        content: const Text(
            'This will notify all members to review and lock in their goals for the upcoming challenge.\n\n'
            'You\'ll be able to start the challenge once members are ready.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Utils.showFeedback(context, 'Preparing challenge...');
              partyProvider.initiateChallengePreparation();
            },
            child: const Text('Prepare Challenge'),
          ),
        ],
      ),
    );
  }

  // Show dialog for canceling challenge preparation
  void _showCancelChallengeDialog(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Challenge Preparation'),
        content: const Text(
            'This will cancel the current challenge preparation. '
            'Any members who have already locked in will need to do so again when you restart.\n\n'
            'Are you sure you want to cancel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Preparing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Utils.showFeedback(context, 'Canceling challenge preparation...');
              partyProvider.cancelChallengePreparation();
            },
            child: const Text('Cancel Preparation'),
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
        title: const Text('End Challenge'),
        content: const Text(
            'This will finalize the current challenge. All unfinished goals will be marked as failed.\n\n'
            'Members will need to wait for you to start a new challenge before they can set new goals.\n\n'
            'Are you sure you want to end this challenge?'),
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
