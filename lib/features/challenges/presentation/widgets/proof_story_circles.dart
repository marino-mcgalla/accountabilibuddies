import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/proof_providers.dart';
import '../pages/proof_story_viewer.dart';

class ProofStoryCircles extends ConsumerWidget {
  const ProofStoryCircles({
    required this.challengeId,
    super.key,
  });

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final pendingProofsByUserAsync = ref.watch(pendingProofsByUserProvider(challengeId));

    if (user == null) {
      return const SizedBox.shrink();
    }

    return pendingProofsByUserAsync.when(
      data: (proofsByUser) {
        if (proofsByUser.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter out current user's proofs (can't approve own proofs)
        final othersProofs = Map<String, List<ProofSubmission>>.from(proofsByUser)
          ..removeWhere((userId, proofs) => userId == user.id);

        // Always show the section, even if empty
        if (othersProofs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proof Reviews',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        proofsByUser.isEmpty 
                          ? 'No proofs submitted yet'
                          : 'No proofs pending review',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _debugShowAllProofs(context, proofsByUser, user.id),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View All'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proof Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: othersProofs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entry = othersProofs.entries.elementAt(index);
                  final userId = entry.key;
                  final userProofs = entry.value;
                  
                  if (userProofs.isEmpty) return const SizedBox.shrink();
                  
                  final userName = userProofs.first.userName;
                  final hasUnviewedProofs = userProofs.any((proof) => !proof.hasBeenViewedBy(user.id));
                  
                  return _StoryCircle(
                    userName: userName,
                    proofCount: userProofs.length,
                    hasUnviewed: hasUnviewedProofs,
                    onTap: () => _openStoryViewer(context, userId, userName, userProofs),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        logger.error('Error loading pending proofs for story circles', error: error, stackTrace: stack);
        return const SizedBox.shrink();
      },
    );
  }

  void _openStoryViewer(
    BuildContext context, 
    String userId, 
    String userName, 
    List<ProofSubmission> proofs,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProofStoryViewer(
          userId: userId,
          userName: userName,
          proofs: proofs,
          challengeId: challengeId,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _debugShowAllProofs(
    BuildContext context,
    Map<String, List<ProofSubmission>> proofsByUser,
    String currentUserId,
  ) {
    // Show all proofs including user's own for debugging
    final allProofs = <ProofSubmission>[];
    proofsByUser.forEach((userId, proofs) {
      allProofs.addAll(proofs);
    });
    
    if (allProofs.isEmpty) return;
    
    // Sort by submission date
    allProofs.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProofStoryViewer(
          userId: 'all_users',
          userName: 'All Proofs (Debug)',
          proofs: allProofs,
          challengeId: challengeId,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  const _StoryCircle({
    required this.userName,
    required this.proofCount,
    required this.hasUnviewed,
    required this.onTap,
  });

  final String userName;
  final int proofCount;
  final bool hasUnviewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              // Main circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasUnviewed
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasUnviewed ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  border: Border.all(
                    color: hasUnviewed 
                        ? Colors.transparent 
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Proof count badge
              if (proofCount > 1)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$proofCount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              userName.length > 8 ? '${userName.substring(0, 8)}...' : userName,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}