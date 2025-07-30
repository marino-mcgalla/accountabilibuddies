import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../auth/auth.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_goal.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/challenge_providers.dart';
import '../providers/proof_providers.dart';

/// Widget that displays goal progress for a challenge with proof status indicators
class ChallengeGoalProgressWidget extends ConsumerWidget {
  const ChallengeGoalProgressWidget({
    required this.challenge,
    super.key,
  });

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    final userParticipationAsync = ref.watch(userParticipationProvider((
      challengeId: challenge.id,
      userId: user.id,
    )));

    final challengeProofsAsync = ref.watch(challengeProofsProvider(challenge.id));

    return userParticipationAsync.when(
      data: (participation) {
        if (participation == null || participation.goals.isEmpty) {
          return const SizedBox.shrink();
        }

        return challengeProofsAsync.when(
          data: (allProofs) {
            // Filter proofs for this user
            final userProofs = allProofs.where((proof) => proof.userId == user.id).toList();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...participation.goals.values.map((goal) {
                  final goalProofs = userProofs.where((proof) => 
                    proof.challengeGoalStates.containsKey('${challenge.id}:${goal.templateId}')
                  ).toList();
                  
                  // Debug logging
                  logger.debug('ChallengeGoalProgress: Goal ${goal.name} (${goal.templateId})');
                  logger.debug('ChallengeGoalProgress: Found ${goalProofs.length} proofs for this goal');
                  for (final proof in goalProofs) {
                    final state = proof.getStateFor(challenge.id, goal.templateId);
                    logger.debug('ChallengeGoalProgress: Proof ${proof.id} status: ${state?.status}');
                  }
                  
                  return _buildGoalProgressRow(context, goal, goalProofs);
                }),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Text(
            'Error loading goal progress',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildGoalProgressRow(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Goal info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  goal.frequencyDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Progress indicators - Crystal clear logic
          Expanded(
            flex: 1,
            child: _buildProgressIndicator(context, goal, goalProofs),
          ),
        ],
      ),
    );
  }

  /// Builds the appropriate progress indicator based on goal type
  Widget _buildProgressIndicator(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    // Simple, explicit logic: daily goals show week view, total goals show progress bar
    switch (goal.goalType) {
      case GoalType.daily:
        return _buildCircleProgress(context, goal, goalProofs);
      case GoalType.total:
        return _buildBarProgress(context, goal, goalProofs);
    }
  }

  // Build circle progress for daily goals (7 circles for 7 days of the week)
  Widget _buildCircleProgress(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    // Show 7 days - but if there are recent proofs, make sure we include them
    final now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday as start of week
    
    // If there are proofs and the most recent one is before this week, adjust the start date
    if (goalProofs.isNotEmpty) {
      final mostRecentProofDate = goalProofs.map((p) => p.submissionDate).reduce((a, b) => a.isAfter(b) ? a : b);
      final proofStartOfWeek = mostRecentProofDate.subtract(Duration(days: mostRecentProofDate.weekday - 1));
      
      // If the most recent proof is from a previous week, show that week instead
      if (proofStartOfWeek.isBefore(startOfWeek)) {
        startOfWeek = proofStartOfWeek;
        logger.debug('Adjusted week to include recent proofs: $startOfWeek');
      }
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 7 circles for each day of the week - constrained to available width
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate optimal circle size based on available width
              // Account for text width (~40px) + spacing (6px) = ~46px reserved
              final availableWidth = constraints.maxWidth - 46;
              final totalSpacing = 6 * 1; // 1px spacing between circles
              final circleSize = ((availableWidth - totalSpacing) / 7).clamp(8.0, 12.0);
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (dayIndex) {
                  final dayDate = startOfWeek.add(Duration(days: dayIndex));
                  final dayDateString = _formatDateForCompletion(dayDate);
                  
                  // Check if this day has been completed
                  final isCompleted = goal.completedDates.contains(dayDateString);
                  final hasProofForThisDay = goalProofs.any((proof) {
                    final proofDate = _formatDateForCompletion(proof.submissionDate);
                    return proofDate == dayDateString;
                  });
                  
                  final circleColor = _getDayCircleColor(context, isCompleted, hasProofForThisDay, goalProofs, dayDateString, goal);
                  logger.debug('Day $dayIndex ($dayDateString): color = $circleColor, hasProof = $hasProofForThisDay, isCompleted = $isCompleted');
                  
                  return Padding(
                    padding: EdgeInsets.only(left: dayIndex > 0 ? 1 : 0),
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                        border: Border.all(
                          color: isCompleted 
                            ? Colors.transparent 
                            : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: circleSize > 10 ? _getDayCircleIcon(isCompleted, hasProofForThisDay, goalProofs, dayDateString, goal) : null,
                    ),
                  );
                }),
              );
            },
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Overall completion text
        Text(
          '${goal.completedDates.length}/${goal.targetFrequency}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: goal.isCompleted 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Build progress bar for total goals (not daily)
  Widget _buildBarProgress(BuildContext context, ChallengeGoal goal, List<ProofSubmission> goalProofs) {
    if (goal.targetFrequency <= 0) {
      return const SizedBox.shrink();
    }
    
    // Count proofs by status for this specific challenge/goal
    final approvedProofs = goalProofs.where((proof) => proof.isApprovedFor(challenge.id, goal.templateId)).length;
    final pendingProofs = goalProofs.where((proof) => proof.isPendingFor(challenge.id, goal.templateId)).length;
    final disputedProofs = goalProofs.where((proof) {
      final state = proof.getStateFor(challenge.id, goal.templateId);
      return state?.status == ProofStatus.disputed;
    }).length;
    final totalProofs = approvedProofs + pendingProofs + disputedProofs;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Segmented progress bar
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  // Green section for approved proofs
                  if (approvedProofs > 0)
                    Flexible(
                      flex: approvedProofs,
                      child: Container(
                        height: 8,
                        color: Colors.green,
                      ),
                    ),
                  // Orange/Yellow section for pending proofs
                  if (pendingProofs > 0)
                    Flexible(
                      flex: pendingProofs,
                      child: Container(
                        height: 8,
                        color: Colors.orange,
                      ),
                    ),
                  // Red section for disputed proofs
                  if (disputedProofs > 0)
                    Flexible(
                      flex: disputedProofs,
                      child: Container(
                        height: 8,
                        color: Colors.red,
                      ),
                    ),
                  // Empty space for remaining target
                  if (totalProofs < goal.targetFrequency)
                    Flexible(
                      flex: goal.targetFrequency - totalProofs,
                      child: Container(
                        height: 8,
                        color: Colors.transparent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Completion text showing total proofs vs target
        Text(
          '$totalProofs/${goal.targetFrequency}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: totalProofs >= goal.targetFrequency
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  /// Get color for individual day circles in daily goals
  Color _getDayCircleColor(BuildContext context, bool isCompleted, bool hasProof, List<ProofSubmission> goalProofs, String dayDateString, ChallengeGoal goal) {
    // Get proofs for this specific day
    final dayProofs = goalProofs.where((proof) {
      final proofDate = _formatDateForCompletion(proof.submissionDate);
      logger.debug('Comparing proof date $proofDate with day date $dayDateString');
      return proofDate == dayDateString;
    }).toList();
    
    logger.debug('Day $dayDateString: found ${dayProofs.length} proofs, isCompleted=$isCompleted, hasProof=$hasProof');
    
    // If there are proofs for this day, show proof status color
    if (dayProofs.isNotEmpty) {
      // Check proof status for this day using specific challenge/goal
      logger.debug('Checking proofs for day $dayDateString: ${dayProofs.length} proofs found');
      
      for (final proof in dayProofs) {
        final state = proof.getStateFor(challenge.id, goal.templateId);
        logger.debug('Proof ${proof.id}: state exists: ${state != null}, status: ${state?.status}');
        logger.debug('Proof ${proof.id} submission date: ${proof.submissionDate}');
      }
      
      if (dayProofs.any((proof) => proof.isApprovedFor(challenge.id, goal.templateId))) {
        logger.debug('Found approved proof for day $dayDateString - returning GREEN');
        return Colors.green; // Approved proof
      } else if (dayProofs.any((proof) => proof.isPendingFor(challenge.id, goal.templateId))) {
        logger.debug('Found pending proof for day $dayDateString - returning ORANGE');
        return Colors.orange; // Pending approval - YELLOW/ORANGE indicator
      } else if (dayProofs.any((proof) {
        final state = proof.getStateFor(challenge.id, goal.templateId);
        return state?.status == ProofStatus.disputed;
      })) {
        logger.debug('Found disputed proof for day $dayDateString - returning RED');
        return Colors.red; // Disputed
      }
    }
    
    // If completed but no proof
    if (isCompleted) {
      logger.debug('Day $dayDateString is completed but no proof - returning PRIMARY');
      return Theme.of(context).colorScheme.primary;
    }
    
    // Not completed and no proof
    logger.debug('Day $dayDateString not completed and no proof - returning TRANSPARENT');
    return Colors.transparent;
  }

  /// Get icon for individual day circles in daily goals
  Widget? _getDayCircleIcon(bool isCompleted, bool hasProof, List<ProofSubmission> goalProofs, String dayDateString, ChallengeGoal goal) {
    if (!isCompleted || !hasProof) return null;

    // Get proofs for this specific day
    final dayProofs = goalProofs.where((proof) {
      final proofDate = _formatDateForCompletion(proof.submissionDate);
      return proofDate == dayDateString;
    }).toList();
    
    if (dayProofs.any((proof) => proof.isApprovedFor(challenge.id, goal.templateId))) {
      return const Icon(Icons.check, color: Colors.white, size: 8);
    } else if (dayProofs.any((proof) => proof.isPendingFor(challenge.id, goal.templateId))) {
      return const Icon(Icons.access_time, color: Colors.white, size: 6);
    } else if (dayProofs.any((proof) {
      final state = proof.getStateFor(challenge.id, goal.templateId);
      return state?.status == ProofStatus.disputed;
    })) {
      return const Icon(Icons.close, color: Colors.white, size: 6);
    }

    return null;
  }


}