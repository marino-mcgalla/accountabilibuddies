import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_goal.dart';
import '../../domain/entities/proof_submission.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../providers/challenge_providers.dart';
import '../providers/proof_providers.dart';

/// Widget that displays goal progress for all users in a challenge (excluding current user)
class AllUsersProgressWidget extends ConsumerWidget {
  const AllUsersProgressWidget({
    required this.challenge,
    super.key,
  });

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);
    final participationsAsync = ref.watch(challengeParticipationsProvider(challenge.id));
    final challengeProofsAsync = ref.watch(challengeProofsProvider(challenge.id));

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return participationsAsync.when(
      data: (participations) {
        if (participations.isEmpty) {
          return const SizedBox.shrink();
        }

        return challengeProofsAsync.when(
          data: (allProofs) {
            // Filter out current user's participation
            final otherUsersParticipations = participations.where(
              (p) => p.userId != currentUser.id
            ).toList();
            
            if (otherUsersParticipations.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Party Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...otherUsersParticipations.map((participation) {
                  // Filter proofs for this user
                  final userProofs = allProofs.where((proof) => proof.userId == participation.userId).toList();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _UserProgressCard(
                      participation: participation,
                      userProofs: userProofs,
                      challenge: challenge,
                      isCurrentUser: false, // Never current user since we filtered them out
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Text(
            'Error loading progress',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _UserProgressCard extends StatefulWidget {
  const _UserProgressCard({
    required this.participation,
    required this.userProofs,
    required this.challenge,
    required this.isCurrentUser,
  });

  final UserChallengeParticipation participation;
  final List<ProofSubmission> userProofs;
  final Challenge challenge;
  final bool isCurrentUser;

  @override
  State<_UserProgressCard> createState() => _UserProgressCardState();
}

class _UserProgressCardState extends State<_UserProgressCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User header (always visible)
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      widget.participation.userName.isNotEmpty 
                          ? widget.participation.userName.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.participation.userName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Expand/collapse icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
              
              // Goals progress (only visible when expanded)
              if (_isExpanded) ...[
                const SizedBox(height: 6),
                
                if (widget.participation.goals.isNotEmpty) ...[
                  ...widget.participation.goals.values.map((goal) {
                    final goalProofs = widget.userProofs.where((proof) => 
                      proof.challengeGoalStates.containsKey('${widget.challenge.id}:${goal.templateId}')
                    ).toList();
                    
                    return _buildGoalProgressRow(context, goal, goalProofs);
                  }),
                ] else
                  Text(
                    'No goals assigned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalProgressRow(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          // Goal info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Compact progress indicator
          Expanded(
            flex: 2,
            child: _buildCompactProgressIndicator(context, goal, goalProofs),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProgressIndicator(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    switch (goal.goalType) {
      case GoalType.daily:
        return _buildCompactCircleProgress(context, goal, goalProofs);
      case GoalType.total:
        return _buildCompactBarProgress(context, goal, goalProofs);
    }
  }

  Widget _buildCompactCircleProgress(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    // Show last 7 days in compact form
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // If there are proofs and the most recent one is before this week, adjust the start date
    if (goalProofs.isNotEmpty) {
      final mostRecentProofDate = goalProofs.map((p) => p.submissionDate).reduce((a, b) => a.isAfter(b) ? a : b);
      final proofStartOfWeek = mostRecentProofDate.subtract(Duration(days: mostRecentProofDate.weekday - 1));
      
      if (proofStartOfWeek.isBefore(startOfWeek)) {
        final adjustedStartOfWeek = proofStartOfWeek;
        return _buildCircleRow(context, goal, goalProofs, adjustedStartOfWeek);
      }
    }
    
    return _buildCircleRow(context, goal, goalProofs, startOfWeek);
  }

  Widget _buildCircleRow(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs, DateTime startOfWeek) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 7 small circles
        ...List.generate(7, (dayIndex) {
          final dayDate = startOfWeek.add(Duration(days: dayIndex));
          final dayDateString = _formatDateForCompletion(dayDate);
          
          final isCompleted = goal.completedDates.contains(dayDateString);
          final dayProofs = goalProofs.where((proof) {
            final proofDate = _formatDateForCompletion(proof.submissionDate);
            return proofDate == dayDateString;
          }).toList();
          
          Color circleColor = Colors.transparent;
          if (dayProofs.isNotEmpty) {
            if (dayProofs.any((proof) => proof.isApprovedFor(widget.challenge.id, goal.templateId))) {
              circleColor = Colors.green;
            } else if (dayProofs.any((proof) => proof.isPendingFor(widget.challenge.id, goal.templateId))) {
              circleColor = Colors.orange;
            }
          } else if (isCompleted) {
            circleColor = Theme.of(context).colorScheme.primary;
          }
          
          return Container(
            margin: EdgeInsets.only(left: dayIndex > 0 ? 1 : 0),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(
                color: circleColor == Colors.transparent 
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
          );
        }),
        
        const SizedBox(width: 4),
        
        // Progress text
        Text(
          '${goal.completedDates.length}/${goal.targetFrequency}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            color: goal.isCompleted 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBarProgress(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    if (goal.targetFrequency <= 0) {
      return const SizedBox.shrink();
    }
    
    // Count proofs by status
    final approvedProofs = goalProofs.where((proof) => proof.isApprovedFor(widget.challenge.id, goal.templateId)).length;
    final pendingProofs = goalProofs.where((proof) => proof.isPendingFor(widget.challenge.id, goal.templateId)).length;
    final totalProofs = approvedProofs + pendingProofs;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Compact progress bar
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(
                children: [
                  if (approvedProofs > 0)
                    Flexible(
                      flex: approvedProofs,
                      child: Container(color: Colors.green),
                    ),
                  if (pendingProofs > 0)
                    Flexible(
                      flex: pendingProofs,
                      child: Container(color: Colors.orange),
                    ),
                  if (totalProofs < goal.targetFrequency)
                    Flexible(
                      flex: goal.targetFrequency - totalProofs,
                      child: Container(color: Colors.transparent),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        Text(
          '$totalProofs/${goal.targetFrequency}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            color: totalProofs >= goal.targetFrequency
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatDateForCompletion(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }
}