import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_commitment.dart';

class ChallengeManagementPage extends ConsumerStatefulWidget {
  const ChallengeManagementPage({
    required this.challenge,
    required this.commitments,
    required this.isLeader,
    super.key,
  });

  final Challenge challenge;
  final List<ChallengeCommitment> commitments;
  final bool isLeader;

  @override
  ConsumerState<ChallengeManagementPage> createState() => _ChallengeManagementPageState();
}

class _ChallengeManagementPageState extends ConsumerState<ChallengeManagementPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final committedMembers = widget.commitments.where((c) => c.isCommitted).length;
    final optedOutMembers = widget.commitments.where((c) => c.hasOptedOut).length;
    final pendingMembers = widget.commitments.where((c) => c.isPending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Management'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        actions: [
          if (widget.isLeader && widget.challenge.status == ChallengeStatus.pending)
            PopupMenuButton<String>(
              onSelected: _onMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'start',
                  child: Text('Start Challenge'),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text('Cancel Challenge'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Overview Card
            _ChallengeOverviewCard(challenge: widget.challenge),
            const SizedBox(height: 16),

            // Status Summary Card
            _StatusSummaryCard(
              challenge: widget.challenge,
              committedCount: committedMembers,
              optedOutCount: optedOutMembers,
              pendingCount: pendingMembers,
            ),
            const SizedBox(height: 16),

            // Member Commitments Section
            Text(
              'Member Commitments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            if (widget.commitments.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Commitments Yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Members haven\'t started committing to this challenge yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...widget.commitments.map((commitment) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: _MemberCommitmentCard(commitment: commitment),
              )),
            ],

            const SizedBox(height: 24),

            // Leader Actions
            if (widget.isLeader) ...[
              Text(
                'Leader Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _LeaderActionsCard(
                challenge: widget.challenge,
                committedCount: committedMembers,
                onAction: _onLeaderAction,
                isLoading: _isLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'start':
        _startChallenge();
        break;
      case 'cancel':
        _cancelChallenge();
        break;
    }
  }

  void _onLeaderAction(String action) {
    switch (action) {
      case 'start':
        _startChallenge();
        break;
      case 'cancel':
        _cancelChallenge();
        break;
      case 'complete':
        _completeChallenge();
        break;
      case 'settle':
        _settleChallenge();
        break;
    }
  }

  void _startChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Challenge'),
        content: const Text('Are you sure you want to start this challenge? Members will no longer be able to modify their commitments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start Challenge'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement actual start challenge logic using use cases
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call
        
        if (mounted) {
          Navigator.of(context).pop(); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge started successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _cancelChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Challenge'),
        content: const Text('Are you sure you want to cancel this challenge? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Challenge'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Challenge'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement actual cancel challenge logic using use cases
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call
        
        if (mounted) {
          Navigator.of(context).pop(); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge cancelled.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _completeChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Challenge'),
        content: const Text('Mark this challenge as complete and begin calculating results?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement actual complete challenge logic using use cases
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge marked as complete. Calculating results...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _settleChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settle Challenge'),
        content: const Text('Finalize the challenge results and mark as settled?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Settle'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement actual settle challenge logic using use cases
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call
        
        if (mounted) {
          Navigator.of(context).pop(); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge settled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to settle challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

class _ChallengeOverviewCard extends StatelessWidget {
  const _ChallengeOverviewCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusChip(status: challenge.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(challenge.startDate)} - ${_formatDate(challenge.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            if (challenge.commitmentDeadline != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Commitment deadline: ${_formatDateTime(challenge.commitmentDeadline!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.challenge,
    required this.committedCount,
    required this.optedOutCount,
    required this.pendingCount,
  });

  final Challenge challenge;
  final int committedCount;
  final int optedOutCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusColumn(
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                  count: committedCount,
                  label: 'Committed',
                ),
                _StatusColumn(
                  icon: Icons.schedule,
                  iconColor: Colors.orange,
                  count: pendingCount,
                  label: 'Pending',
                ),
                _StatusColumn(
                  icon: Icons.cancel,
                  iconColor: Colors.red,
                  count: optedOutCount,
                  label: 'Opted Out',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MemberCommitmentCard extends StatelessWidget {
  const _MemberCommitmentCard({required this.commitment});

  final ChallengeCommitment commitment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commitment.userName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _CommitmentStatusChip(status: commitment.status),
              ],
            ),
            if (commitment.isCommitted) ...[
              const SizedBox(height: 8),
              Text(
                'Goals: ${commitment.totalGoals} (${commitment.totalWeeklyFrequency} total/week)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Wager: ${commitment.formattedWager}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaderActionsCard extends StatelessWidget {
  const _LeaderActionsCard({
    required this.challenge,
    required this.committedCount,
    required this.onAction,
    required this.isLoading,
  });

  final Challenge challenge;
  final int committedCount;
  final ValueChanged<String> onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            if (challenge.status == ChallengeStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading || committedCount == 0 ? null : () => onAction('start'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Challenge'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => onAction('cancel'),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Challenge'),
                ),
              ),
              if (committedCount == 0) ...[
                const SizedBox(height: 8),
                Text(
                  'At least one member must commit before starting.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ] else if (challenge.status == ChallengeStatus.active) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => onAction('complete'),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as Complete'),
                ),
              ),
            ] else if (challenge.status == ChallengeStatus.settling) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => onAction('settle'),
                  icon: const Icon(Icons.gavel),
                  label: const Text('Settle Challenge'),
                ),
              ),
            ] else if (challenge.status == ChallengeStatus.completed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Challenge completed and settled',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (challenge.status == ChallengeStatus.cancelled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Challenge was cancelled',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ChallengeStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (status) {
      case ChallengeStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case ChallengeStatus.active:
        color = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case ChallengeStatus.settling:
        color = Colors.purple;
        icon = Icons.calculate;
        break;
      case ChallengeStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ChallengeStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentStatusChip extends StatelessWidget {
  const _CommitmentStatusChip({required this.status});

  final CommitmentStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (status) {
      case CommitmentStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case CommitmentStatus.committed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case CommitmentStatus.optedOut:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 2),
          Text(
            status.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}