import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/multi_party_challenge.dart';
import '../providers/multi_party_challenge_provider.dart';
import '../../party/providers/simple_party_provider.dart';

/// Widget for displaying and managing challenge invitations
class ChallengeInvitationWidget extends StatelessWidget {
  const ChallengeInvitationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MultiPartyChallengeProvider, SimplePartyProvider>(
      builder: (context, challengeProvider, partyProvider, child) {
        final currentPartyId = partyProvider.currentPartyId;
        if (currentPartyId == null) {
          return const SizedBox.shrink();
        }

        final pendingInvitations = challengeProvider.pendingInvitations;
        
        if (pendingInvitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Challenge Invitations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingInvitations.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...pendingInvitations.map((invitation) => 
                  _buildInvitationItem(context, invitation, currentPartyId, challengeProvider, partyProvider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitationItem(
    BuildContext context,
    MultiPartyChallenge challenge,
    String currentPartyId,
    MultiPartyChallengeProvider challengeProvider,
    SimplePartyProvider partyProvider,
  ) {
    final creatorPartyName = _getPartyName(partyProvider, challenge.creatorPartyId);
    final participantCount = challenge.acceptedParties.length;
    final duration = challenge.endDate.difference(challenge.startDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Party Challenge',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From: $creatorPartyName',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _buildChallengeTypeChip(context, challenge),
            ],
          ),
          const SizedBox(height: 12),
          
          // Challenge details
          Row(
            children: [
              _buildDetailChip(context, Icons.groups, '$participantCount parties'),
              const SizedBox(width: 8),
              _buildDetailChip(context, Icons.schedule, '$duration days'),
              const SizedBox(width: 8),
              if (challenge.allowCrossPartyProofApproval)
                _buildDetailChip(context, Icons.share, 'Cross-party'),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Date range
          Text(
            '${_formatDate(challenge.startDate)} - ${_formatDate(challenge.endDate)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _declineInvitation(context, challenge.id, currentPartyId, challengeProvider),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptInvitation(context, challenge.id, currentPartyId, challengeProvider),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept & Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeTypeChip(BuildContext context, MultiPartyChallenge challenge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: challenge.isMultiParty 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        challenge.isMultiParty ? 'Multi-Party' : 'Single-Party',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: challenge.isMultiParty
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getPartyName(SimplePartyProvider partyProvider, String partyId) {
    // Try to find the party name
    final parties = partyProvider.parties;
    final party = parties.where((p) => p['id'] == partyId).firstOrNull;
    return party?['name'] ?? 'Unknown Party';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _acceptInvitation(
    BuildContext context,
    String challengeId,
    String partyId,
    MultiPartyChallengeProvider challengeProvider,
  ) async {
    try {
      final success = await challengeProvider.acceptChallengeInvitation(challengeId, partyId);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge invitation accepted! You can now participate.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept invitation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineInvitation(
    BuildContext context,
    String challengeId,
    String partyId,
    MultiPartyChallengeProvider challengeProvider,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: const Text('Are you sure you want to decline this challenge invitation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await challengeProvider.declineChallengeInvitation(challengeId, partyId);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge invitation declined.'),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline invitation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}