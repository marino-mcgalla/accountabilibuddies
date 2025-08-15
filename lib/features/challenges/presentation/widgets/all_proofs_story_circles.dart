import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/proof_providers.dart';
import '../pages/proof_story_viewer.dart';

/// Shows story circles for ALL proofs (not just pending) - useful for viewing all activity
class AllProofsStoryCircles extends ConsumerWidget {
  const AllProofsStoryCircles({
    required this.challengeId,
    super.key,
  });

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final allProofsAsync = ref.watch(challengeProofsProvider(challengeId));

    if (user == null) {
      return const SizedBox.shrink();
    }

    return allProofsAsync.when(
      data: (allProofs) {
        if (allProofs.isEmpty) {
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proof Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No proofs submitted yet. Be the first!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Group proofs by user
        final proofsByUser = <String, List<ProofSubmission>>{};
        for (final proof in allProofs) {
          if (!proofsByUser.containsKey(proof.userId)) {
            proofsByUser[proof.userId] = [];
          }
          proofsByUser[proof.userId]!.add(proof);
        }

        // Sort users by most recent proof
        final sortedUsers = proofsByUser.entries.toList()
          ..sort((a, b) {
            final aLatest = a.value.map((p) => p.submissionDate).reduce((a, b) => a.isAfter(b) ? a : b);
            final bLatest = b.value.map((p) => p.submissionDate).reduce((a, b) => a.isAfter(b) ? a : b);
            return bLatest.compareTo(aLatest);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Proof Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allProofs.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sortedUsers.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entry = sortedUsers[index];
                  final userId = entry.key;
                  final userProofs = entry.value;
                  
                  if (userProofs.isEmpty) return const SizedBox.shrink();
                  
                  final userName = userProofs.first.userName;
                  final isCurrentUser = userId == user.id;
                  final pendingCount = userProofs.where((p) => p.isPending).length;
                  final hasNewActivity = userProofs.any((p) => !p.hasBeenViewedBy(user.id) && !isCurrentUser);
                  
                  return _StoryCircle(
                    userName: userName,
                    proofCount: userProofs.length,
                    pendingCount: pendingCount,
                    hasNewActivity: hasNewActivity,
                    isCurrentUser: isCurrentUser,
                    onTap: () => _openStoryViewer(context, userId, userName, userProofs),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _openStoryViewer(
    BuildContext context, 
    String userId, 
    String userName, 
    List<ProofSubmission> proofs,
  ) {
    // Sort proofs by date (newest first)
    final sortedProofs = List<ProofSubmission>.from(proofs)
      ..sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProofStoryViewer(
          userId: userId,
          userName: userName,
          proofs: sortedProofs,
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
    required this.pendingCount,
    required this.hasNewActivity,
    required this.isCurrentUser,
    required this.onTap,
  });

  final String userName;
  final int proofCount;
  final int pendingCount;
  final bool hasNewActivity;
  final bool isCurrentUser;
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
                  gradient: hasNewActivity || pendingCount > 0
                      ? LinearGradient(
                          colors: pendingCount > 0
                              ? [Colors.orange, Colors.deepOrange]
                              : [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasNewActivity || pendingCount > 0 ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  border: Border.all(
                    color: hasNewActivity || pendingCount > 0
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
                      backgroundColor: isCurrentUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: isCurrentUser
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
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
                      color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
              // Pending indicator
              if (pendingCount > 0 && !isCurrentUser)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              isCurrentUser ? 'You' : (userName.length > 8 ? '${userName.substring(0, 8)}...' : userName),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
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