import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/proof_submission.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../providers/challenge_providers.dart';
import '../providers/proof_providers.dart';
import '../pages/proof_story_viewer.dart';
import '../../../../core/providers/display_name_providers.dart';

/// Story circles showing all party members (like Snapchat) - always visible
class PartyMembersStoryCircles extends ConsumerWidget {
  const PartyMembersStoryCircles({
    required this.challenge,
    super.key,
  });

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final partyAsync = ref.watch(partyProvider(challenge.partyId));
    final participationsAsync = ref.watch(challengeParticipationsProvider(challenge.id));
    final allProofsAsync = ref.watch(challengeProofsProvider(challenge.id));

    if (user == null) {
      return const SizedBox.shrink();
    }

    return partyAsync.when(
      data: (party) {
        if (party == null) return const SizedBox.shrink();

        // Always show ALL party members, regardless of challenge participation
        return allProofsAsync.when(
          data: (allProofs) {
            // Create story circles for ALL party members (like Snapchat)
            final storyCircles = <Widget>[];
            
            // Group proofs by user
            final proofsByUser = <String, List<ProofSubmission>>{};
            for (final proof in allProofs) {
              if (!proofsByUser.containsKey(proof.userId)) {
                proofsByUser[proof.userId] = [];
              }
              proofsByUser[proof.userId]!.add(proof);
            }

            // Get participations for additional data, but don't require them
            final participationsData = participationsAsync.whenOrNull(data: (p) => p) ?? [];
            final participationsByUser = <String, UserChallengeParticipation>{};
            for (final participation in participationsData) {
              participationsByUser[participation.userId] = participation;
            }

            // Add story circle for EVERY party member (not just participants)
            for (final memberId in party.memberIds) {
              final userProofs = proofsByUser[memberId] ?? [];
              final participation = participationsByUser[memberId];
              final isCurrentUser = memberId == user.id;
              
              // Count unviewed proofs for this user in this challenge
              final unviewedProofs = userProofs.where((proof) => 
                proof.challengeGoalStates.values.any((state) => 
                  state.challengeId == challenge.id && !state.viewedBy.contains(user.id)
                )
              ).toList();
              
              // Count pending approval proofs (need approval from current user)
              final pendingApprovalProofs = userProofs.where((proof) => 
                proof.isPending && proof.userId != user.id
              ).toList();
              
              // Combine counts for unseen and pending approval proofs
              final unseenOrPendingProofs = <ProofSubmission>{};
              unseenOrPendingProofs.addAll(unviewedProofs);
              unseenOrPendingProofs.addAll(pendingApprovalProofs);
              
              final hasNewProofs = unseenOrPendingProofs.isNotEmpty && !isCurrentUser;
              final hasPendingProofs = userProofs.any((proof) => 
                proof.challengeGoalStates.values.any((state) => 
                  state.challengeId == challenge.id && state.status == ProofStatus.pending
                )
              );
              final hasAnyProofs = userProofs.isNotEmpty;
              
              storyCircles.add(
                _PartyMemberStoryCircle(
                  userId: memberId,
                  proofCount: unseenOrPendingProofs.length,
                  hasNewActivity: hasNewProofs,
                  hasPendingProofs: hasPendingProofs && !isCurrentUser,
                  isCurrentUser: isCurrentUser,
                  hasAnyProofs: hasAnyProofs,
                  allProofsViewed: hasAnyProofs && unseenOrPendingProofs.isEmpty,
                  allProofs: userProofs,
                  onTap: () => _openStoryViewer(
                    context,
                    ref,
                    memberId,
                    userProofs,
                  ),
                ),
              );
            }

            // Always show the circles - even if no proofs or participations
            if (storyCircles.isEmpty) {
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Text(
                        'No party members found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: storyCircles.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => storyCircles[index],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }


  void _openStoryViewer(
    BuildContext context,
    WidgetRef ref,
    String userId,
    List<ProofSubmission> proofs,
  ) async {
    if (proofs.isEmpty) return;
    
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;
    
    // Filter to unviewed proofs (not seen by current user)
    final unviewedProofs = proofs.where(
      (proof) => !proof.hasBeenViewedBy(currentUser.id)
    ).toList();
    
    // Filter to pending approval proofs (need approval from current user)
    final pendingApprovalProofs = proofs.where(
      (proof) => proof.isPending && proof.userId != currentUser.id
    ).toList();
    
    // Combine unseen and pending approval proofs (treat pending as unseen)
    final unseenOrPendingProofs = <ProofSubmission>{};
    unseenOrPendingProofs.addAll(unviewedProofs);
    unseenOrPendingProofs.addAll(pendingApprovalProofs);
    
    List<ProofSubmission> proofsToShow;
    
    // Determine which proofs to show for this session
    if (unseenOrPendingProofs.isNotEmpty) {
      // If there are unseen proofs OR proofs needing approval, show only those
      proofsToShow = unseenOrPendingProofs.toList();
    } else {
      // Only show previously seen proofs if there are NO unseen proofs AND NO pending approvals
      proofsToShow = proofs;
    }
    
    // Sort proofs: pending first, then by date (oldest first)
    final sortedProofs = List<ProofSubmission>.from(proofsToShow)
      ..sort((a, b) {
        // Pending proofs come first
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        // Within same status, sort by date
        return a.submissionDate.compareTo(b.submissionDate);
      });

    // Get display name dynamically
    final displayName = await ref.read(displayNameProvider(userId).future);
    
    if (!context.mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProofStoryViewer(
          userId: userId,
          userName: displayName,
          proofs: sortedProofs,
          challengeId: challenge.id,
        ),
        fullscreenDialog: true,
      ),
    );
  }
  
}

class _PartyMemberStoryCircle extends ConsumerWidget {
  const _PartyMemberStoryCircle({
    required this.userId,
    required this.proofCount,
    required this.hasNewActivity,
    required this.hasPendingProofs,
    required this.isCurrentUser,
    required this.hasAnyProofs,
    required this.allProofsViewed,
    required this.allProofs,
    required this.onTap,
  });

  final String userId;
  final int proofCount;
  final bool hasNewActivity;
  final bool hasPendingProofs;
  final bool isCurrentUser;
  final bool hasAnyProofs;
  final bool allProofsViewed;
  final List<ProofSubmission> allProofs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              // Main circle with gradient/color based on state
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasNewActivity || hasPendingProofs
                      ? LinearGradient(
                          colors: hasPendingProofs
                              ? [Colors.orange, Colors.deepOrange]
                              : [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasNewActivity || hasPendingProofs 
                      ? null 
                      : (proofCount > 0 ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  border: Border.all(
                    color: hasNewActivity || hasPendingProofs
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
                    child: _buildCircleContent(),
                  ),
                ),
              ),

              // Proof count badge (only show if there are unviewed proofs from others)
              if (proofCount > 0 && !isCurrentUser)
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Pending indicator (clock icon)
              if (hasPendingProofs)
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
                    child: const Icon(
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
            child: isCurrentUser 
              ? Text(
                  'You',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Consumer(
                  builder: (context, ref, child) {
                    final displayNameAsync = ref.watch(displayNameProvider(userId));
                    return displayNameAsync.when(
                      data: (displayName) => Text(
                        displayName.length > 8 ? '${displayName.substring(0, 8)}...' : displayName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => Text(
                        'Loading...',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      error: (_, __) => Text(
                        'Unknown',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleContent() {
    Widget content;
    
    // Show image preview if there are any proofs
    if (hasAnyProofs && allProofs.isNotEmpty) {
      // For circle preview, always show the most recent proof image
      final proofsWithImages = allProofs.where((p) => 
        p.contentType == ProofContentType.image && p.imageUrls.isNotEmpty
      ).toList();
      
      ProofSubmission? proofToShow;
      
      if (proofsWithImages.isNotEmpty) {
        // Sort by date (most recent first for circle preview)
        proofsWithImages.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
        proofToShow = proofsWithImages.first;
      }
      
      // Show the proof image if we found one
      if (proofToShow != null && 
          proofToShow.contentType == ProofContentType.image && 
          proofToShow.imageUrls.isNotEmpty) {
        content = ClipOval(
          child: Image.network(
            proofToShow.imageUrls.first,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar();
            },
          ),
        );
      } else {
        // No image proofs found, show avatar
        content = _buildDefaultAvatar();
      }
    } else {
      // No proofs at all - show default avatar
      content = _buildDefaultAvatar();
    }
    
    // Add dark overlay if all proofs have been viewed
    if (allProofsViewed) {
      return Stack(
        children: [
          content,
          // Dark overlay to indicate all proofs viewed
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black45, // Semi-transparent dark overlay
            ),
          ),
        ],
      );
    }
    
    return content;
  }

  Widget _buildDefaultAvatar() {
    return Builder(
      builder: (context) {
        if (isCurrentUser) {
          return CircleAvatar(
            radius: 26,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              'Y',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          );
        }
        
        return Consumer(
          builder: (context, ref, child) {
            final displayNameAsync = ref.watch(displayNameProvider(userId));
            return displayNameAsync.when(
              data: (displayName) => CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  displayName.isNotEmpty 
                      ? displayName.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              loading: () => CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              error: (_, __) => CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}