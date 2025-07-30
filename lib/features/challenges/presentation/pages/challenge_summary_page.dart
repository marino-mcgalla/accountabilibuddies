import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../../domain/entities/proof_submission.dart';
import '../providers/challenge_providers.dart';
import '../providers/proof_providers.dart';
import '../pages/proof_story_viewer.dart';

/// Represents the wager distribution calculation for a participant
class WagerDistribution {
  const WagerDistribution({
    required this.userId,
    required this.amountWagered,
    required this.amountWon,
    required this.completionRate,
  });

  final String userId;
  final double amountWagered;
  final double amountWon;
  final double completionRate;

  double get netAmount => amountWon - amountWagered;
  bool get isPositive => netAmount > 0;
}

/// Page that shows the summary of a completed challenge with stats and outcomes
class ChallengeSummaryPage extends ConsumerWidget {
  const ChallengeSummaryPage({
    required this.challengeId,
    super.key,
  });

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeProvider(challengeId));
    final participationsAsync = ref.watch(challengeParticipationsProvider(challengeId));
    final challengeProofsAsync = ref.watch(challengeProofsProvider(challengeId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Summary'),
        elevation: 0,
      ),
      body: challengeAsync.when(
        data: (challenge) {
          if (challenge == null) {
            return const Center(
              child: Text('Challenge not found'),
            );
          }

          return participationsAsync.when(
            data: (participations) => challengeProofsAsync.when(
              data: (proofs) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Challenge Header
                    _buildChallengeHeader(context, challenge),
                    const SizedBox(height: 24),

                    // Statistics Overview
                    _buildStatsOverview(context, challenge, participations, proofs),
                    const SizedBox(height: 24),

                    // Wager Pool and Money Owed
                    _buildWagerSection(context, challenge, participations),
                    const SizedBox(height: 24),

                    // All Proof Submissions (Story Circles)
                    _buildProofSubmissionsSection(context, proofs),
                    const SizedBox(height: 24),

                    // Participant Results
                    _buildParticipantResults(context, challenge, participations, proofs),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading proofs: $error'),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading participations: $error'),
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('Error loading challenge: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeHeader(BuildContext context, Challenge challenge) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Challenge Completed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (challenge.description.isNotEmpty) ...[
              Text(
                challenge.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(challenge.startDate)} - ${_formatDate(challenge.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(
    BuildContext context,
    Challenge challenge,
    List<UserChallengeParticipation> participations,
    List<dynamic> proofs,
  ) {
    final totalParticipants = participations.length;
    final totalProofSubmissions = proofs.length;
    final challengeDuration = challenge.durationInDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Participants',
                    totalParticipants.toString(),
                    Icons.group,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Proof Submissions',
                    totalProofSubmissions.toString(),
                    Icons.photo_camera,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Duration',
                    '$challengeDuration days',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWagerSection(
    BuildContext context,
    Challenge challenge,
    List<UserChallengeParticipation> participations,
  ) {
    // Calculate wager distribution
    final wagerDistribution = _calculateWagerDistribution(participations, challenge.totalPool);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wager Pool Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pool:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${challenge.totalPool.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Distribution method
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribution Method:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only members with 100% completion receive payment. '
                    'Winners split the pot evenly from non-winners\' wagers.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Individual distributions
            if (wagerDistribution.isNotEmpty) ...[
              Text(
                'Individual Results:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...wagerDistribution.entries.map((entry) {
                final participation = participations.firstWhere((p) => p.userId == entry.key);
                final distribution = entry.value;
                return _buildDistributionRow(context, participation, distribution);
              }),
            ] else
              Text(
                'No wager distributions calculated.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(
    BuildContext context, 
    UserChallengeParticipation participation, 
    WagerDistribution distribution,
  ) {
    final netAmount = distribution.amountWon - distribution.amountWagered;
    final isPositive = netAmount > 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participation.userName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(distribution.completionRate * 100).toStringAsFixed(1)}% completion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPositive ? '+\$${netAmount.toStringAsFixed(2)}' : '\$${netAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  'Won: \$${distribution.amountWon.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate wager distribution - only 100% completion members split the pot evenly
  /// TODO: Add other distribution methods (weighted, tiered, etc.) in future versions
  Map<String, WagerDistribution> _calculateWagerDistribution(
    List<UserChallengeParticipation> participations,
    double totalPool,
  ) {
    // Only consider participants who have locked in and have wager amounts
    final validParticipants = participations
        .where((p) => p.isLockedIn && p.wagerAmount != null && p.wagerAmount! > 0)
        .toList();
    
    if (validParticipants.isEmpty) {
      return {};
    }
    
    // Separate winners (100% completion) from losers (<100% completion)
    final winners = validParticipants
        .where((p) => p.overallCompletionRate >= 1.0)
        .toList();
    
    final losers = validParticipants
        .where((p) => p.overallCompletionRate < 1.0)
        .toList();
    
    // Calculate the actual pot from losers' wagers only
    final actualPot = losers.fold<double>(0, (sum, loser) => sum + loser.wagerAmount!);
    
    // Calculate winnings per winner (split evenly)
    final winningsPerWinner = winners.isNotEmpty ? actualPot / winners.length : 0.0;
    
    // Create distributions for all participants
    final Map<String, WagerDistribution> distributions = {};
    
    // Winners: get their share of the pot, don't pay their wager
    for (final winner in winners) {
      distributions[winner.userId] = WagerDistribution(
        userId: winner.userId,
        amountWagered: 0.0, // Winners don't pay into the pot
        amountWon: winningsPerWinner,
        completionRate: winner.overallCompletionRate,
      );
    }
    
    // Losers: pay their wager, win nothing
    for (final loser in losers) {
      distributions[loser.userId] = WagerDistribution(
        userId: loser.userId,
        amountWagered: loser.wagerAmount!,
        amountWon: 0.0,
        completionRate: loser.overallCompletionRate,
      );
    }
    
    return distributions;
  }

  Widget _buildProofSubmissionsSection(BuildContext context, List<dynamic> proofs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Proof Submissions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (proofs.isNotEmpty) 
              _buildSummaryStoryCircles(context, proofs.cast<ProofSubmission>())
            else
              SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    'No proof submissions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantResults(
    BuildContext context,
    Challenge challenge,
    List<UserChallengeParticipation> participations,
    List<dynamic> proofs,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participant Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (participations.isNotEmpty)
              ...participations.map((participation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildParticipantRow(context, participation),
              ))
            else
              Text(
                'No participants found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(BuildContext context, UserChallengeParticipation participation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participation.userName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${participation.totalGoals} goals • ${(participation.overallCompletionRate * 100).toStringAsFixed(1)}% completion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (participation.wagerAmount != null)
                  Text(
                    'Wagered: \$${participation.wagerAmount!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                participation.statusDisplay,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: participation.isLockedIn ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (participation.areAllGoalsCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStoryCircles(BuildContext context, List<ProofSubmission> proofs) {
    // Group proofs by user
    final proofsByUser = <String, List<ProofSubmission>>{};
    for (final proof in proofs) {
      if (!proofsByUser.containsKey(proof.userId)) {
        proofsByUser[proof.userId] = [];
      }
      proofsByUser[proof.userId]!.add(proof);
    }

    if (proofsByUser.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'No proof submissions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    // Create story circles for each user
    final storyCircles = <Widget>[];
    
    for (final entry in proofsByUser.entries) {
      final userId = entry.key;
      final userProofs = entry.value;
      final userName = userProofs.isNotEmpty ? userProofs.first.userName : 'Unknown User';
      
      storyCircles.add(
        _SummaryStoryCircle(
          userId: userId,
          userName: userName,
          proofs: userProofs,
          challengeId: challengeId,
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
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Story circle widget for challenge summary page
class _SummaryStoryCircle extends StatelessWidget {
  const _SummaryStoryCircle({
    required this.userId,
    required this.userName,
    required this.proofs,
    required this.challengeId,
  });

  final String userId;
  final String userName;
  final List<ProofSubmission> proofs;
  final String challengeId;

  @override
  Widget build(BuildContext context) {
    final hasProofs = proofs.isNotEmpty;
    final proofCount = proofs.length;
    
    return GestureDetector(
      onTap: hasProofs ? () => _openStoryViewer(context) : null,
      child: Column(
        children: [
          Stack(
            children: [
              // Main circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasProofs
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasProofs ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  border: Border.all(
                    color: hasProofs 
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
                    child: _buildCircleContent(context),
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
                        fontSize: 11,
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

  Widget _buildCircleContent(BuildContext context) {
    if (proofs.isEmpty) {
      return _buildDefaultAvatar(context);
    }

    // Show image preview if available
    final proofsWithImages = proofs.where((p) => 
      p.contentType == ProofContentType.image && p.imageUrls.isNotEmpty
    ).toList();
    
    if (proofsWithImages.isNotEmpty) {
      // Sort by date (most recent first)
      proofsWithImages.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
      final latestProof = proofsWithImages.first;
      
      return ClipOval(
        child: Image.network(
          latestProof.imageUrls.first,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(context);
          },
        ),
      );
    }
    
    // Fallback to avatar
    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        userName.isNotEmpty 
            ? userName.substring(0, 1).toUpperCase()
            : '?',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context) {
    if (proofs.isEmpty) return;
    
    // Sort proofs by date (oldest first for viewing)
    final sortedProofs = List<ProofSubmission>.from(proofs)
      ..sort((a, b) => a.submissionDate.compareTo(b.submissionDate));

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