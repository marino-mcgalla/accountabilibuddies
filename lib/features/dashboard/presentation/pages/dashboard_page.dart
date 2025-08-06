import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../../../auth/auth.dart';
import '../../../goals/presentation/providers/goal_providers.dart';
import '../../../goals/presentation/providers/goal_template_providers.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../challenges/presentation/providers/challenge_providers.dart';
import '../../../challenges/presentation/providers/proof_providers.dart';
import '../../../challenges/presentation/pages/challenge_commitment_page.dart';
import '../../../challenges/presentation/widgets/party_members_story_circles.dart';
import '../../../challenges/presentation/widgets/challenge_goal_progress_widget.dart';
import '../../../challenges/presentation/widgets/all_users_progress_widget.dart';
import '../../../challenges/presentation/widgets/multi_goal_proof_submission_widget.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../../goals/domain/entities/goal.dart' hide GoalType;
import '../../../challenges/domain/entities/challenge.dart';
import '../../../challenges/domain/entities/challenge_goal.dart';
import '../../../parties/domain/entities/party.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../challenges/domain/entities/proof_submission.dart';
import '../../../challenges/data/models/proof_submission_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/display_name_utils.dart';

// Provider for persisting selected party ID across navigation
final selectedPartyIdProvider = StateProvider<String?>((ref) => null);

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  StreamSubscription? _proofSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize the selected party ID after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedParty();
    });
  }

  @override
  void dispose() {
    _proofSubscription?.cancel();
    _cleanupCamera(); // Ensure camera is stopped when widget is disposed
    super.dispose();
  }

  /// Cleanup camera resources - stops all video tracks and removes camera container
  void _cleanupCamera() {
    if (kIsWeb) {
      try {
        // Find and stop any active camera streams
        final container = html.document.getElementById('camera-container');
        if (container != null) {
          final video = container.querySelector('#camera-preview') as html.VideoElement?;
          if (video?.srcObject != null) {
            final stream = video!.srcObject as html.MediaStream;
            final tracks = stream.getVideoTracks();
            for (var track in tracks) {
              track.stop();
            }
          }
          container.remove();
        }
      } catch (e) {
        // Silently handle cleanup errors to avoid disrupting app flow
      }
    }
  }

  void _initializeSelectedParty() {
    final partiesAsync = ref.read(partiesProvider);
    final parties = partiesAsync.value;
    
    // Only set initial party if none is selected and we have parties
    if (parties != null && parties.isNotEmpty) {
      final selectedPartyId = ref.read(selectedPartyIdProvider);
      if (selectedPartyId == null) {
        ref.read(selectedPartyIdProvider.notifier).state = parties.first.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final partiesAsync = ref.watch(partiesProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final templatesAsync = ref.watch(goalTemplatesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section - REMOVED INTENTIONALLY (always showed static "Welcome back!")
            // _buildWelcomeSection(context, user),
            // const SizedBox(height: 24),

            // Party switcher (only show if user has multiple parties)
            partiesAsync.when(
              data: (parties) => _buildPartySwitcher(parties),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Proof approvals section (only show if user has parties)
            partiesAsync.when(
              data: (parties) {
                if (parties.isNotEmpty) {
                  return Column(
                    children: [
                      _buildProofApprovalsSection(context),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Challenge status section
            partiesAsync.when(
              data: (parties) {
                if (parties.isNotEmpty) {
                  return Column(
                    children: [
                      _buildChallengeStatusSection(context, parties),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Your goals section - REMOVED INTENTIONALLY (can be restored if needed)
            // _buildYourGoalsSection(context, goalsAsync, templatesAsync),
            // const SizedBox(height: 24),

            // Party section - REMOVED INTENTIONALLY (can be restored if needed)
            // partiesAsync.when(
            //   data: (parties) {
            //     if (parties.isNotEmpty) {
            //       return Column(
            //         children: [
            //           _buildPartySection(context, parties),
            //           const SizedBox(height: 24),
            //         ],
            //       );
            //     }
            //     return const SizedBox.shrink();
            //   },
            //   loading: () => const SizedBox.shrink(),
            //   error: (_, __) => const SizedBox.shrink(),
            // ),

            // Quick actions - REMOVED INTENTIONALLY (can be restored if needed)
            // _buildQuickActionsSection(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProofSubmissionFlow(context, ref),
        label: const Text('Submit Proof'),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, UserModel? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.displayName?.substring(0, 1).toUpperCase() ?? 
                user?.email.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    user != null ? DisplayNameUtils.getDisplayNameSync(user) : 'User',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofApprovalsSection(BuildContext context) {
    final partiesAsync = ref.watch(partiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Approvals',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        partiesAsync.when(
            data: (parties) {
              if (parties.isEmpty) return const SizedBox.shrink();
              
              final currentParty = _getCurrentParty(parties);
              final currentChallengeAsync = ref.watch(currentChallengeProvider(currentParty.id));
              
              return currentChallengeAsync.when(
                data: (challenge) {
                  if (challenge == null) {
                    return Center(
                      child: Text(
                        'No active challenges',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return PartyMembersStoryCircles(challenge: challenge);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'Failed to load approvals',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildChallengeStatusSection(BuildContext context, List<Party> parties) {
    if (parties.isEmpty) return const SizedBox.shrink();

    final currentParty = _getCurrentParty(parties);
    final currentChallengeAsync = ref.watch(currentChallengeProvider(currentParty.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            currentChallengeAsync.when(
              data: (challenge) {
                if (challenge == null) {
                  return _buildNoChallengeState(context, currentParty);
                }
                return Column(
                  children: [
                    _buildChallengeActiveState(context, challenge, currentParty),
                    const SizedBox(height: 12),
                    // Your progress section in its own card
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Progress',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ChallengeGoalProgressWidget(challenge: challenge),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    // All users progress section
                    AllUsersProgressWidget(challenge: challenge),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text('Failed to load challenge status'),
                    TextButton(
                      onPressed: () => ref.refresh(currentChallengeProvider(currentParty.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChallengeState(BuildContext context, Party party) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey),
          ),
          child: const Text(
            'No active challenge',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/challenges/create'),
              icon: const Icon(Icons.add_circle, size: 16),
              label: const Text('Start Challenge'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/party/${party.id}'),
              icon: const Icon(Icons.group, size: 16),
              label: const Text('Manage Party'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChallengeActiveState(BuildContext context, Challenge challenge, Party party) {
    final user = ref.read(userProvider);
    final participationsAsync = ref.watch(challengeParticipationsProvider(challenge.id));
    
    return participationsAsync.when(
      data: (participations) {
        final isParticipating = participations.any((p) => p.userId == user?.id);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                isParticipating ? 'Challenge Active' : 'Challenge Active - Join Now',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              challenge.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (challenge.description.isNotEmpty)
              Text(
                challenge.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isParticipating)
                  ElevatedButton.icon(
                    onPressed: () => _lockInGoals(context, challenge),
                    icon: const Icon(Icons.flag, size: 16),
                    label: const Text('Lock In My Goals'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.go('/challenges/${challenge.id}'),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Challenge'),
                  ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              'Challenge Active',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            challenge.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildYourGoalsSection(
    BuildContext context, 
    AsyncValue<List<Goal>> goalsAsync,
    AsyncValue<List<GoalTemplate>> templatesAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/goals/templates'),
                  child: const Text('Manage Templates'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return _buildEmptyGoalsState(context);
                }
                return Column(
                  children: goals.map((goal) => _buildGoalCard(context, goal)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text('Failed to load goals'),
                    TextButton(
                      onPressed: () => ref.refresh(goalsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoalsState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'No active goals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create goal templates and join challenges to start tracking your progress!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/goals/templates'),
            icon: const Icon(Icons.add),
            label: const Text('Create Goal Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGoalStatusColor(goal).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getGoalStatusText(goal),
                  style: TextStyle(
                    color: _getGoalStatusColor(goal),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (goal.description.isNotEmpty)
            Text(
              goal.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
          // Progress widget - simplified for now
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.3, // TODO: Calculate actual progress
              child: Container(
                decoration: BoxDecoration(
                  color: _getGoalStatusColor(goal),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: () => _showProofSubmission(context, goal),
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Submit Proof'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartySection(BuildContext context, List<Party> parties) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Parties',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.party),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...parties.take(3).map((party) => _buildPartyCard(context, party)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyCard(BuildContext context, Party party) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.group, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${party.memberIds.length} members',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go('/party/${party.id}'),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  context,
                  icon: Icons.add,
                  label: 'Create Goal',
                  onTap: () => context.go('/goals/templates/create'),
                ),
                _buildActionChip(
                  context,
                  icon: Icons.group_add,
                  label: 'Join Party',
                  onTap: () => context.go('/party/join'),
                ),
                _buildActionChip(
                  context,
                  icon: Icons.create,
                  label: 'Create Party',
                  onTap: () => context.go('/party/create'),
                ),
                _buildActionChip(
                  context,
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => context.go(AppRoutes.profile),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Color _getGoalStatusColor(Goal goal) {
    // TODO: Implement actual goal status logic
    return Colors.blue;
  }

  String _getGoalStatusText(Goal goal) {
    // TODO: Implement actual goal status logic
    return 'Active';
  }

  void _showProofSubmission(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submit Proof for ${goal.title}'),
        content: const Text('Proof submission feature will be available when you join an active challenge.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to challenges or party page
              context.go('/challenges/create');
            },
            child: const Text('Start Challenge'),
          ),
        ],
      ),
    );
  }

  void _lockInGoals(BuildContext context, Challenge challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChallengeCommitmentPage(challenge: challenge),
      ),
    );
  }

  void _showProofSubmissionFlow(BuildContext context, WidgetRef ref) async {
    
    // Go directly to camera - no selection dialog
    await _openCamera();
  }

  Future<void> _openCamera() async {
    try {
      if (kIsWeb) {
        // Create UI elements for camera with mobile-optimized styling
        final html.DivElement container = html.DivElement()
          ..id = 'camera-container'
          ..style.position = 'fixed'
          ..style.top = '0'
          ..style.left = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'black'
          ..style.zIndex = '9999'
          ..style.display = 'flex'
          ..style.flexDirection = 'column'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.padding = '0'
          ..style.margin = '0'
          ..style.overflow = 'hidden';

        // Create elements but don't add video to DOM yet
        final html.VideoElement video = html.VideoElement()
          ..id = 'camera-preview'
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..setAttribute('controls', 'false')
          ..setAttribute('disablePictureInPicture', 'true')
          ..setAttribute('controlsList', 'nodownload nofullscreen noremoteplayback')
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.setProperty('-webkit-media-controls', 'none')
          ..style.setProperty('-moz-media-controls', 'none')
          ..style.setProperty('media-controls', 'none')
          ..style.setProperty('-webkit-media-controls-panel', 'none')
          ..style.setProperty('-webkit-media-controls-play-button', 'none')
          ..style.setProperty('-webkit-media-controls-timeline', 'none')
          ..style.setProperty('-webkit-media-controls-current-time-display', 'none')
          ..style.setProperty('-webkit-media-controls-time-remaining-display', 'none')
          ..style.setProperty('-webkit-media-controls-timeline-container', 'none')
          ..style.setProperty('-webkit-media-controls-volume-slider', 'none')
          ..style.setProperty('-webkit-media-controls-fullscreen-button', 'none')
          ..style.pointerEvents = 'none'; // Prevent right-click context menu

        final html.CanvasElement canvas = html.CanvasElement()
          ..id = 'canvas-element'
          ..style.display = 'none';

        final html.ImageElement imagePreview = html.ImageElement()
          ..id = 'image-preview'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.display = 'none';

        final html.DivElement buttonsContainer = html.DivElement()
          ..style.position = 'absolute'
          ..style.bottom = '0'
          ..style.left = '0'
          ..style.right = '0'
          ..style.display = 'flex'
          ..style.flexDirection = 'row'
          ..style.justifyContent = 'space-around'
          ..style.alignItems = 'center'
          ..style.padding = '20px'
          ..style.paddingBottom = '40px' // Extra padding for home indicator
          ..style.width = '100%'
          ..style.boxSizing = 'border-box'
          ..style.background = 'linear-gradient(to top, rgba(0,0,0,0.7), transparent)';

        final html.ButtonElement captureButton = html.ButtonElement()
          ..style.width = '70px'
          ..style.height = '70px'
          ..style.borderRadius = '50%'
          ..style.backgroundColor = 'white'
          ..style.border = '3px solid white'
          ..style.cursor = 'pointer'
          ..style.position = 'relative'
          ..style.touchAction = 'manipulation'
          ..style.boxShadow = '0 2px 10px rgba(0,0,0,0.3)';

        final html.ButtonElement galleryButton = html.ButtonElement()
          ..text = '🖼️'
          ..style.width = '50px'
          ..style.height = '50px'
          ..style.borderRadius = '50%'
          ..style.backgroundColor = 'rgba(255,255,255,0.2)'
          ..style.color = 'white'
          ..style.border = '2px solid rgba(255,255,255,0.5)'
          ..style.cursor = 'pointer'
          ..style.fontSize = '24px'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.touchAction = 'manipulation';

        final html.ButtonElement submitButton = html.ButtonElement()
          ..text = '✓'
          ..style.width = '70px'
          ..style.height = '70px'
          ..style.borderRadius = '50%'
          ..style.backgroundColor = '#4CAF50'
          ..style.color = 'white'
          ..style.border = '3px solid #4CAF50'
          ..style.cursor = 'pointer'
          ..style.fontSize = '30px'
          ..style.display = 'none'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.touchAction = 'manipulation'
          ..style.boxShadow = '0 2px 10px rgba(0,0,0,0.3)';

        final html.ButtonElement retakeButton = html.ButtonElement()
          ..text = '↺'
          ..style.width = '50px'
          ..style.height = '50px'
          ..style.borderRadius = '50%'
          ..style.backgroundColor = 'rgba(255,255,255,0.2)'
          ..style.color = 'white'
          ..style.border = '2px solid rgba(255,255,255,0.5)'
          ..style.cursor = 'pointer'
          ..style.fontSize = '24px'
          ..style.display = 'none'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.touchAction = 'manipulation';

        final html.ButtonElement cancelButton = html.ButtonElement()
          ..text = '✕'
          ..style.width = '50px'
          ..style.height = '50px'
          ..style.borderRadius = '50%'
          ..style.backgroundColor = 'rgba(255,255,255,0.2)'
          ..style.color = 'white'
          ..style.border = '2px solid rgba(255,255,255,0.5)'
          ..style.cursor = 'pointer'
          ..style.fontSize = '24px'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.touchAction = 'manipulation';

        // Add elements to DOM - Cancel, Capture, Gallery layout
        buttonsContainer.children.add(cancelButton);
        buttonsContainer.children.add(captureButton);
        buttonsContainer.children.add(galleryButton);
        buttonsContainer.children.add(submitButton);
        buttonsContainer.children.add(retakeButton);
        // Don't add video yet - will add after camera permission check
        container.children.add(canvas);
        container.children.add(imagePreview);
        container.children.add(buttonsContainer);
        html.document.body?.append(container);
        
        // Inject additional CSS to hide any remaining video controls
        final html.StyleElement style = html.StyleElement()
          ..text = '''
            #camera-container video::-webkit-media-controls,
            #camera-container video::-webkit-media-controls-panel,
            #camera-container video::-webkit-media-controls-play-button,
            #camera-container video::-webkit-media-controls-timeline,
            #camera-container video::-webkit-media-controls-current-time-display,
            #camera-container video::-webkit-media-controls-time-remaining-display,
            #camera-container video::-webkit-media-controls-timeline-container,
            #camera-container video::-webkit-media-controls-volume-slider,
            #camera-container video::-webkit-media-controls-fullscreen-button {
              display: none !important;
              opacity: 0 !important;
              visibility: hidden !important;
            }
            #camera-container video {
              outline: none !important;
            }
          ''';
        html.document.head?.append(style);
        

        // Set up event listeners with both click and touch events
        void setupButtonEvents(html.ButtonElement button, void Function() callback) {
          button.onClick.listen((event) {
            event.preventDefault();
            callback();
          });
          button.onTouchEnd.listen((event) {
            event.preventDefault();
            callback();
          });
        }
        
        setupButtonEvents(cancelButton, () {
          _cleanupCamera();
        });

        setupButtonEvents(captureButton, () {
          
          try {
            // Capture image from video
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            canvas.context2D.drawImage(video, 0, 0);

            // Convert to blob and show preview
            canvas.toBlob('image/jpeg', 0.85).then((blob) {
              final url = html.Url.createObjectUrl(blob);
              imagePreview.src = url;
              
              // Switch to preview mode
              video.style.display = 'none';
              imagePreview.style.display = 'block';
              
              // Show preview buttons, hide capture buttons
              captureButton.style.display = 'none';
              galleryButton.style.display = 'none';
              submitButton.style.display = 'inline-block';
              retakeButton.style.display = 'inline-block';
              
            });
          } catch (e) {
          }
        });

        galleryButton.onClick.listen((event) async {
          // Close camera immediately to stop the camera light
          _cleanupCamera();
          container.remove();
          
          // Open gallery picker
          final ImagePicker picker = ImagePicker();
          final XFile? photo = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85, // Compress to reduce file size
          );
          
          if (photo != null) {
            if (_isValidImageFile(photo)) {
              // Convert to blob and show multi-goal submission with selected image
              final bytes = await photo.readAsBytes();
              if (kIsWeb) {
                final blob = html.Blob([bytes], 'image/jpeg');
                await _showMultiGoalSubmission(blob);
              } else {
                await _showMultiGoalSubmission(bytes);
              }
            } else {
              _showInvalidFileTypeError();
              // Don't reopen camera - stay on form and let user try again
            }
          } else {
            // If no photo selected, reopen camera
            await _openCamera();
          }
        });

        submitButton.onClick.listen((event) async {
          // Check if we have a gallery image or camera capture
          final galleryBlobUrl = imagePreview.dataset['imageBlob'];
          
          if (galleryBlobUrl != null) {
            // Gallery image submission
            final response = await html.HttpRequest.request(galleryBlobUrl, responseType: 'blob');
            final blob = response.response as html.Blob;
            
            // Clean up the blob URL
            html.Url.revokeObjectUrl(galleryBlobUrl);
            
            // Stop camera and close camera UI
            _cleanupCamera();
            
            // Show multi-goal selection
            if (mounted) {
              await _showMultiGoalSelectionForProof(context, blob);
            }
          } else {
            // Camera capture submission
            canvas.toBlob('image/jpeg', 0.85).then((blob) async {
              // Stop camera and close camera UI
              _cleanupCamera();
              
              // Show multi-goal selection
              if (mounted) {
                await _showMultiGoalSelectionForProof(context, blob);
              }
            });
          }
        });

        retakeButton.onClick.listen((event) {
          // Switch back to camera mode
          imagePreview.style.display = 'none';
          video.style.display = 'block';
          
          // Show capture buttons, hide preview buttons
          captureButton.style.display = 'inline-block';
          galleryButton.style.display = 'inline-block';
          submitButton.style.display = 'none';
          retakeButton.style.display = 'none';
          
          // Clean up the preview image and gallery blob
          if (imagePreview.src != null) {
            html.Url.revokeObjectUrl(imagePreview.src!);
          }
          final galleryBlobUrl = imagePreview.dataset['imageBlob'];
          if (galleryBlobUrl != null) {
            html.Url.revokeObjectUrl(galleryBlobUrl);
            imagePreview.dataset.remove('imageBlob');
          }
          
        });

        // Start camera with null checks for mobile compatibility
        
        // Check if MediaDevices API is available before creating UI
        final mediaDevices = html.window.navigator.mediaDevices;
        final isHttps = html.window.location.protocol == 'https:';
        final isLocalhost = html.window.location.hostname == 'localhost' || 
                           html.window.location.hostname == '127.0.0.1';
        
        
        // Immediately fall back if camera API won't work
        if (mediaDevices == null || (!isHttps && !isLocalhost)) {
          
          // Remove container immediately
          container.remove();
          
          // Open native camera picker directly
          final ImagePicker picker = ImagePicker();
          final XFile? photo = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          
          if (photo != null) {
            final bytes = await photo.readAsBytes();
            if (mounted) {
              if (kIsWeb) {
                final blob = html.Blob([bytes], 'image/jpeg');
                await _showMultiGoalSubmission(blob);
              } else {
                await _showMultiGoalSubmission(bytes);
              }
            }
          }
          return;
        }
        
        // Only try camera access if we're on HTTPS or localhost
        try {
          
          // Start with simple constraints
          Map<String, dynamic> constraints = {
            'video': true,
            'audio': false
          };
          
          final stream = await mediaDevices.getUserMedia(constraints);
          
          // Now add video to the container since camera access succeeded
          container.insertBefore(video, canvas);
          
          video.srcObject = stream;
          await video.play();
          
        } catch (e) {
          
          // Clean up and fall back to native picker
          container.remove();
          
          final ImagePicker picker = ImagePicker();
          final XFile? photo = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          
          if (photo != null) {
            final bytes = await photo.readAsBytes();
            if (mounted) {
              if (kIsWeb) {
                final blob = html.Blob([bytes], 'image/jpeg');
                await _showMultiGoalSubmission(blob);
              } else {
                await _showMultiGoalSubmission(bytes);
              }
            }
          }
          return;
        }
        
        
        // Add page visibility listener to cleanup camera when tab is hidden
        html.document.addEventListener('visibilitychange', (event) {
          if (html.document.hidden == true) {
            _cleanupCamera();
          }
        });
        
        // Add beforeunload listener to cleanup camera when page is closing
        html.window.addEventListener('beforeunload', (event) {
          _cleanupCamera();
        });
      } else {
        // For mobile native apps, use image picker directly
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        
        if (photo != null) {
          // Convert XFile to blob-like format for the submission widget
          final bytes = await photo.readAsBytes();
          if (kIsWeb) {
            final blob = html.Blob([bytes], 'image/jpeg');
            await _showMultiGoalSubmission(blob);
          } else {
            await _showMultiGoalSubmission(bytes);
          }
        } else {
        }
      }
    } catch (e) {
      // Cleanup camera on any error
      _cleanupCamera();
    }
  }

  Future<void> _showMultiGoalSelectionForProof(BuildContext context, html.Blob imageBlob) async {
    await _showMultiGoalSubmission(imageBlob);
  }
  
  Future<void> _showMultiGoalSubmission(dynamic imageBlob) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    // Show the multi-goal selection widget in a modal
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(
                    imageBlob != null ? Icons.camera_alt : Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    imageBlob != null ? 'Submit Photo Proof' : 'Submit Proof',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Multi-goal submission widget
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MultiGoalProofSubmissionWidget(imageBlob: imageBlob),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Cleanup camera if modal was dismissed without completing submission
    // The MultiGoalProofSubmissionWidget handles cleanup on successful submission
    if (result == null) {
      _cleanupCamera();
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProofToFirebase(html.Blob imageBlob, ChallengeGoal selectedGoal) async {
    final user = ref.read(userProvider);
    if (user == null) throw Exception('User not authenticated');

    // Get current party and challenge (reuse from context)
    final partiesAsync = ref.read(partiesProvider);
    final parties = partiesAsync.value ?? [];
    if (parties.isEmpty) throw Exception('No parties found');

    final currentParty = parties.first;
    final currentChallengeAsync = ref.read(currentChallengeProvider(currentParty.id));
    final challenge = currentChallengeAsync.value;
    if (challenge == null) throw Exception('No active challenge');

    // Get user participation for participation ID
    final userParticipationAsync = ref.read(userParticipationProvider((
      challengeId: challenge.id,
      userId: user.id,
    )));
    final participation = userParticipationAsync.value;
    if (participation == null) throw Exception('User participation not found');

    // Delete existing daily goal proofs for today if this is a daily goal
    if (selectedGoal.goalType == GoalType.daily) {
      await _deleteExistingDailyProofs(challenge.id, selectedGoal, user.id);
    }

    // Convert blob to Uint8List for Firebase upload
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.onLoad.listen((e) {
      completer.complete(reader.result as Uint8List);
    });
    reader.readAsArrayBuffer(imageBlob);
    final imageData = await completer.future;

    // Upload image to Firebase Storage
    final uuid = const Uuid();
    final proofId = uuid.v4();
    final fileName = 'proof_${proofId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('proof_images')
        .child(fileName);

    final uploadTask = storageRef.putData(imageData);
    final snapshot = await uploadTask;
    final imageUrl = await snapshot.ref.getDownloadURL();

    // Create proof submission document
    final now = DateTime.now();
    // Create challenge-goal state
    final challengeGoalState = ChallengeGoalProofState(
      challengeId: challenge.id,
      participationId: participation.id,
      goalTemplateId: selectedGoal.templateId,
      status: ProofStatus.pending,
    );
    
    final challengeGoalStates = <String, ChallengeGoalProofState>{
      '${challenge.id}:${selectedGoal.templateId}': challengeGoalState,
    };

    final proofSubmission = ProofSubmission(
      id: proofId,
      userId: user.id,
      userName: DisplayNameUtils.getDisplayNameSync(user),
      submissionDate: now,
      createdAt: now,
      updatedAt: now,
      contentType: ProofContentType.image,
      imageUrls: [imageUrl],
      challengeGoalStates: challengeGoalStates,
    );

    // Save to Firestore using the proper model
    final proofModel = ProofSubmissionModel.fromEntity(proofSubmission);
    await FirebaseFirestore.instance
        .collection('proofSubmissions')
        .doc(proofId)
        .set(proofModel.toFirestore());

  }

  Future<bool> _checkForExistingDailyProof(ChallengeGoal goal) async {
    final user = ref.read(userProvider);
    if (user == null) return false;

    // Get all proofs for the current challenge
    final partiesAsync = ref.read(partiesProvider);
    final parties = partiesAsync.value ?? [];
    if (parties.isEmpty) return false;

    final currentParty = parties.first;
    final currentChallengeAsync = ref.read(currentChallengeProvider(currentParty.id));
    final challenge = currentChallengeAsync.value;
    if (challenge == null) return false;

    // Get proofs from the stream provider (which works without needing a custom index)
    final challengeProofsAsync = ref.read(challengeProofsProvider(challenge.id));
    final allProofs = challengeProofsAsync.value ?? [];

    // Filter to user's proofs for this goal on today's date
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final existingTodayProofs = allProofs.where((proof) {
      final proofDate = proof.submissionDate;
      final proofDateString = '${proofDate.year}-${proofDate.month.toString().padLeft(2, '0')}-${proofDate.day.toString().padLeft(2, '0')}';
      
      return proof.userId == user.id &&
             proof.goalTemplateIds.contains(goal.templateId) &&
             proofDateString == todayString;
    }).toList();

    return existingTodayProofs.isNotEmpty;
  }

  Future<bool> _showDuplicateProofDialog(BuildContext context, ChallengeGoal goal) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Proof Already Exists'),
        content: Text(
          'You have already submitted a proof for "${goal.name}" today. '
          'Daily goals only allow one proof per day.\n\n'
          'Do you want to delete the existing proof and submit this new one?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Replace Proof'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<void> _deleteExistingDailyProofs(String challengeId, ChallengeGoal goal, String userId) async {
    // Get proofs from the stream provider (which works without needing a custom index)
    final challengeProofsAsync = ref.read(challengeProofsProvider(challengeId));
    final allProofs = challengeProofsAsync.value ?? [];

    // Find existing proofs for this user, goal, and today
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final existingTodayProofs = allProofs.where((proof) {
      final proofDate = proof.submissionDate;
      final proofDateString = '${proofDate.year}-${proofDate.month.toString().padLeft(2, '0')}-${proofDate.day.toString().padLeft(2, '0')}';
      
      return proof.userId == userId &&
             proof.goalTemplateIds.contains(goal.templateId) &&
             proofDateString == todayString;
    }).toList();

    // Delete each existing proof using the repository
    final proofRepository = ref.read(proofRepositoryProvider);
    for (final proof in existingTodayProofs) {
      try {
        await proofRepository.deleteProof(proof.id);
      } catch (e) {
        // Ignore delete errors for now
      }
    }
  }

  /// Get the currently selected party or first party if none selected
  Party _getCurrentParty(List<Party> parties) {
    if (parties.isEmpty) throw StateError('No parties available');
    
    final selectedPartyId = ref.read(selectedPartyIdProvider);
    
    // If no party is selected, return the first party but don't modify state during build
    if (selectedPartyId == null) {
      return parties.first;
    }
    
    // Find the selected party
    final selectedParty = parties.where((p) => p.id == selectedPartyId).firstOrNull;
    if (selectedParty != null) {
      return selectedParty;
    }
    
    // Fallback to first party if selected party not found
    return parties.first;
  }

  /// Build party switcher dropdown
  Widget _buildPartySwitcher(List<Party> parties) {
    if (parties.length <= 1) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.groups,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Party:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: ref.watch(selectedPartyIdProvider),
                isExpanded: true,
                items: parties.map((party) {
                  return DropdownMenuItem<String>(
                    value: party.id,
                    child: Text(
                      party.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newPartyId) {
                  ref.read(selectedPartyIdProvider.notifier).state = newPartyId;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Validates that the selected file is a supported image format
  bool _isValidImageFile(XFile file) {
    // On web, file.path might be a blob URL, so we primarily rely on MIME type
    if (kIsWeb && file.mimeType != null) {
      const allowedMimeTypes = [
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/webp'
      ];
      return allowedMimeTypes.contains(file.mimeType!.toLowerCase());
    }
    
    // For non-web platforms or when MIME type is not available, check extension
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    final extension = file.path.toLowerCase().split('.').last;
    
    // Check if the path is a blob URL (web)
    if (file.path.startsWith('blob:')) {
      // For blob URLs without MIME type, we can't validate - allow it
      return true;
    }
    
    // Check file extension
    return allowedExtensions.contains(extension);
  }

  /// Shows an error dialog for invalid file types
  void _showInvalidFileTypeError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Invalid File Type'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select a valid image file.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('Supported formats:'),
            const SizedBox(height: 4),
            const Text('• JPEG (.jpg, .jpeg)'),
            const Text('• PNG (.png)'),
            const Text('• WebP (.webp)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Unsupported formats may cause upload failures',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

