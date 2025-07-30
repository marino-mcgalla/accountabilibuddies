import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/proof_providers.dart';

/// Debug widget to show all proofs for a challenge - useful for testing
class ProofListDebugWidget extends ConsumerWidget {
  const ProofListDebugWidget({
    required this.challengeId,
    super.key,
  });

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final allProofsAsync = ref.watch(challengeProofsProvider(challengeId));

    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('User not logged in'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Debug: All Proofs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            allProofsAsync.when(
              data: (proofs) {
                if (proofs.isEmpty) {
                  return Column(
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No proofs submitted yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        'Challenge ID: $challengeId',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${proofs.length} proof(s):',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...proofs.map((proof) => _buildProofItem(context, proof, user.id)),
                  ],
                );
              },
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading proofs...'),
                ],
              ),
              error: (error, stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 4),
                  Text(
                    'Error loading proofs: $error',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofItem(BuildContext context, ProofSubmission proof, String currentUserId) {
    final isOwnProof = proof.userId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwnProof 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOwnProof 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isOwnProof 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
                child: Text(
                  proof.userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proof.userName + (isOwnProof ? ' (You)' : ''),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDateTime(proof.submissionDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(proof.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(proof.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  proof.statusDisplay,
                  style: TextStyle(
                    color: _getStatusColor(proof.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            proof.primaryContent,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.flag,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Goal ID: ${proof.goalTemplateId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProofStatus status) {
    switch (status) {
      case ProofStatus.pending:
        return Colors.orange;
      case ProofStatus.approved:
        return Colors.green;
      case ProofStatus.disputed:
        return Colors.red;
      case ProofStatus.rejected:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}