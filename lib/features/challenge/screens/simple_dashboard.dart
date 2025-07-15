
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../goals/providers/simple_goals_provider.dart';
import '../../goals/providers/goal_template_provider.dart';
import '../../party/providers/simple_party_provider.dart';
import '../../goals/models/goal_model.dart';
import '../../goals/models/proof_model.dart';
import '../widgets/simple_progress_tracker.dart';
import 'proof_story_viewer.dart';

class SimpleDashboard extends StatefulWidget {
  const SimpleDashboard({super.key});

  @override
  State<SimpleDashboard> createState() => _SimpleDashboardState();
}

class _SimpleDashboardState extends State<SimpleDashboard> {
  StreamSubscription<QuerySnapshot>? _proofSubscription;
  List<Map<String, dynamic>>? _cachedMemberProofs;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _proofSubscription?.cancel();
    super.dispose();
  }

  void _setupProofSubscription() {
    final partyProvider = Provider.of<SimplePartyProvider>(context, listen: false);
    if (!partyProvider.hasParties) return;

    final firstParty = partyProvider.parties.first;
    final activeChallenge = firstParty['activeChallenge'] as Map<String, dynamic>?;
    final pendingChallenge = firstParty['pendingChallenge'] as Map<String, dynamic>?;
    final challengeId = activeChallenge?['id'] ?? pendingChallenge?['id'];

    if (challengeId != null) {
      print('SUBSCRIPTION: Setting up manual subscription for challenge $challengeId');
      _proofSubscription = FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .collection('memberGoals')
          .snapshots()
          .listen((snapshot) {
        print('MANUAL SUBSCRIPTION: Received update, processing...');
        if (mounted) {
          setState(() {
            _cachedMemberProofs = _processSnapshotData(snapshot, firstParty);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 0,
      ),
      body: Consumer3<SimpleGoalsProvider, GoalTemplateProvider, SimplePartyProvider>(
        builder: (context, goalsProvider, templateProvider, partyProvider, child) {
          if (goalsProvider.isLoading || templateProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Story-style Proof Notifications
                _buildProofStoriesSection(context, partyProvider),
                const SizedBox(height: 8),
                
                // Challenge Status
                if (partyProvider.hasParties)
                  _buildChallengeStatus(context, partyProvider),
                
                if (partyProvider.hasParties)
                  const SizedBox(height: 16),
                
                // Your Goals Section
                _buildYourGoalsSection(context, goalsProvider),
                const SizedBox(height: 16),
                
                // Party Information
                if (partyProvider.hasParties)
                  _buildPartySection(context, partyProvider),
                
                if (partyProvider.hasParties)
                  const SizedBox(height: 16),
                
                // Quick Actions
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildProofStoriesSection(BuildContext context, SimplePartyProvider partyProvider) {
    // Set up subscription if not already done and party data is available
    if (_proofSubscription == null && partyProvider.hasParties) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupProofSubscription();
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pending Approvals",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: _cachedMemberProofs == null
            ? const Center(child: CircularProgressIndicator())
            : _cachedMemberProofs!.isEmpty
              ? Center(
                  child: Text(
                    'No pending proofs to review',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._cachedMemberProofs!.map((memberData) {
                        final userId = memberData['userId'] as String;
                        final userName = memberData['userName'] as String;
                        final proofs = memberData['proofs'] as List<Map<String, dynamic>>;
                        final hasProofs = proofs.isNotEmpty;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildStoryCircle(
                            context, 
                            userName, 
                            Colors.blue, 
                            hasProofs,
                            userId,
                            proofs,
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      // Help text
                      Text(
                        'Tap circles to review proofs',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _processSnapshotData(QuerySnapshot snapshot, Map<String, dynamic>? firstParty) {
    if (firstParty == null) return [];
    
    print('REAL-TIME UPDATE: Processing ${snapshot.docs.length} member documents');
    
    // Get party members for user names
    final members = firstParty['members'] as List?;
    final userIdToName = {
      'woixNy5MHAgYypmylQmEPZqlUHt1': 'Bobby',
      'swMvqZCvPvg1vUsAZLMEvNXtBWD2': 'Reno',
    };
    
    // Initialize all party members
    final Map<String, List<Map<String, dynamic>>> proofsPerUser = {};
    final Map<String, String> userNames = {};
    
    if (members != null) {
      for (final memberId in members) {
        if (memberId is String) {
          proofsPerUser[memberId] = [];
          userNames[memberId] = userIdToName[memberId] ?? 'User-${memberId.substring(0, 4)}';
        }
      }
    }
    
    // Process each member's goals
    for (final memberDoc in snapshot.docs) {
      final memberId = memberDoc.id;
      final memberData = memberDoc.data() as Map<String, dynamic>;
      final userGoals = memberData['goals'] as List? ?? [];
      
      // Ensure user exists in our maps
      if (!proofsPerUser.containsKey(memberId)) {
        proofsPerUser[memberId] = [];
        userNames[memberId] = userIdToName[memberId] ?? 'User-${memberId.substring(0, 4)}';
      }
      
      for (var goalData in userGoals) {
        try {
          final goal = Goal.fromMap(Map<String, dynamic>.from(goalData));
          final pendingProofs = goal.pendingProofs;
          
          // Add all pending proofs for this goal
          for (final proof in pendingProofs) {
            proofsPerUser[memberId]!.add({
              'proof': proof,
              'instance': goal,
              'goalName': goal.goalName,
            });
          }
        } catch (e) {
          // Error parsing goal
        }
      }
    }
    
    // Convert to list format expected by UI
    final List<Map<String, dynamic>> result = [];
    int totalPending = 0;
    for (final userId in proofsPerUser.keys) {
      final proofsList = proofsPerUser[userId] ?? [];
      totalPending += proofsList.length;
      
      result.add({
        'userId': userId,
        'userName': userNames[userId] ?? 'Unknown',
        'proofs': proofsList,
      });
    }
    
    print('REAL-TIME UPDATE: Found $totalPending total pending proofs across ${result.length} users');
    return result;
  }

  Widget _buildStoryCircle(
    BuildContext context, 
    String userName, 
    Color color, 
    bool hasPending,
    String userId,
    List<Map<String, dynamic>> proofs,
  ) {
    final initials = userName.isNotEmpty 
        ? (userName.length >= 2 ? userName.substring(0, 2).toUpperCase() : userName.toUpperCase())
        : '??';
    
    print('STORY CIRCLE: $userName has ${proofs.length} proofs, hasPending=$hasPending');
    
    return GestureDetector(
      onTap: () {
        if (hasPending) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProofStoryViewer(
                userId: userId,
                userName: userName,
                pendingProofs: proofs,
                currentUserId: Provider.of<SimplePartyProvider>(context, listen: false).currentUserId ?? '',
              ),
            ),
          );
        } else {
          // Show a message for users with no pending proofs
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName has no pending proofs to review'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasPending ? Colors.yellow : Colors.grey,
                width: hasPending ? 3 : 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: color,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Show pending proof count if there are any
          if (hasPending && proofs.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${proofs.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeStatus(BuildContext context, SimplePartyProvider partyProvider) {
    final firstParty = partyProvider.parties.first;
    final hasActiveChallenge = partyProvider.hasActiveChallenge(firstParty['id']);
    final hasPendingChallenge = partyProvider.hasPendingChallenge(firstParty['id']);
    final hasUserLockedIn = partyProvider.hasUserLockedIn(firstParty['id']);
    
    String status = 'No active challenge';
    Color statusColor = Colors.grey;
    
    if (hasActiveChallenge) {
      status = hasUserLockedIn ? 'Challenge Active' : 'Challenge Active - Not Locked In';
      statusColor = hasUserLockedIn ? Colors.green : Colors.orange;
    } else if (hasPendingChallenge) {
      status = hasUserLockedIn ? 'Locked In - Waiting for Others' : 'Lock In Required';
      statusColor = hasUserLockedIn ? Colors.blue : Colors.orange;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Action buttons based on state
                if (!hasActiveChallenge && !hasPendingChallenge && partyProvider.isCurrentUserPartyLeader)
                  // Start Challenge button for party leaders when no challenge exists
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/challenge-setup'),
                        icon: const Icon(Icons.add_circle, size: 16),
                        label: const Text('Start Challenge'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  )
                else if ((hasActiveChallenge || hasPendingChallenge) && !hasUserLockedIn)
                  // Lock In button for members who haven't locked in yet
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Debug: Cancel button for party leaders
                          if (partyProvider.isCurrentUserPartyLeader)
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Cancel Challenge"),
                                    content: const Text("Cancel this challenge? All data will be lost."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Keep"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                        child: const Text("Cancel"),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true && context.mounted) {
                                  await partyProvider.clearChallenge(partyProvider.partyId!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Challenge cancelled")),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.cancel, size: 16),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/challenge-lockin'),
                            icon: const Icon(Icons.lock, size: 16),
                            label: const Text('Lock In Goals'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
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

  Widget _buildYourGoalsSection(BuildContext context, SimpleGoalsProvider goalsProvider) {
    final goals = goalsProvider.activeGoals;
    
    return Consumer<SimplePartyProvider>(
      builder: (context, partyProvider, child) {
        // Check if user needs to lock in
        final hasChallenge = partyProvider.hasParties && 
            (partyProvider.currentPartyHasActiveChallenge || partyProvider.currentPartyHasPendingChallenge);
        final hasUserLockedIn = partyProvider.hasParties && 
            partyProvider.hasUserLockedIn(partyProvider.parties.first['id']);
        final needsToLockIn = hasChallenge && !hasUserLockedIn;
        
        // During the transition period, if there's a challenge but user hasn't locked in,
        // we don't show goals because they need to lock in first to create their instances
        final shouldHideGoalsForLockIn = hasChallenge && !hasUserLockedIn;

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
                      onPressed: () => context.go('/goal-templates'),
                      child: const Text('Manage Templates'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Show lock-in prompt if needed
                if (needsToLockIn)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Challenge Goals Pending',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lock in your goals and wager to see your challenge goals and start tracking progress.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/challenge-lockin'),
                          icon: const Icon(Icons.lock, size: 16),
                          label: const Text('Lock In Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (goals.isEmpty && !needsToLockIn)
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No active goals'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/goal-templates'),
                          child: const Text('Create Goals'),
                        ),
                      ],
                    ),
                  )
                else if (!needsToLockIn)
                  ...goals.map((goal) => _buildGoalCard(context, goal)),
              ],
            ),
          ),
        );
      },
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
                  goal.goalName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: goal.isCompleted 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.isCompleted ? 'Completed' : 'Active',
                  style: TextStyle(
                    color: goal.isCompleted ? Colors.green : Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goal.goalCriteria,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SimpleProgressTracker(goalId: goal.id),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(), // Remove duplicate progress display
              ElevatedButton.icon(
                onPressed: () => _showProofDialog(context, goal),
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

  Widget _buildPartySection(BuildContext context, SimplePartyProvider partyProvider) {
    final parties = partyProvider.parties;
    
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
                  onPressed: () => context.go('/party'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...parties.map((party) {
              final memberCount = party['memberCount'] ?? 0;
              final maxMembers = party['maxMembers'] ?? 10;
              
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
                            party['name'] ?? 'Unnamed Party',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '$memberCount/$maxMembers members',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/party'),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
                  onTap: () => context.go('/goal-templates'),
                ),
                _buildActionChip(
                  context,
                  icon: Icons.group_add,
                  label: 'Join Party',
                  onTap: () => context.go('/join-party'),
                ),
                _buildActionChip(
                  context,
                  icon: Icons.timer,
                  label: 'Time Machine',
                  onTap: () => context.go('/time-machine'),
                ),
                _buildActionChip(
                  context,
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => context.go('/user-info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, {
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

  void _showProofDialog(BuildContext context, Goal goal) {
    final now = DateTime.now();
    final dateKey = now.toIso8601String().split('T')[0];
    
    // Check if there's already a proof for today (for daily goals)
    final existingProof = goal.goalType == GoalType.daily 
        ? goal.challengeData?.dailyProofs[dateKey]
        : null;
    
    if (existingProof != null) {
      // Show overwrite warning dialog
      _showOverwriteWarningDialog(context, goal, existingProof, now);
    } else {
      // Show normal proof submission dialog
      _showProofSubmissionDialog(context, goal, now);
    }
  }

  void _showOverwriteWarningDialog(BuildContext context, Goal goal, Proof existingProof, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proof Already Exists'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You already have a proof submitted for today:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${existingProof.status.name.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: existingProof.status == ProofStatus.pending 
                          ? Colors.orange
                          : existingProof.status == ProofStatus.approved
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Description: ${existingProof.proofText}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: ${existingProof.submissionDate.toLocal().toString().split('.')[0]}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do you want to overwrite this proof with a new one?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showProofSubmissionDialog(context, goal, date, isOverwrite: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
  }

  void _showProofSubmissionDialog(BuildContext context, Goal goal, DateTime date, {bool isOverwrite = false}) {
    final TextEditingController proofController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isOverwrite ? "Overwrite Proof for" : "Submit Proof for"} ${goal.goalName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: proofController,
              decoration: const InputDecoration(
                labelText: 'Proof Description',
                hintText: 'Describe what you did...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Photo upload coming soon!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (proofController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a description')),
                );
                return;
              }
              
              final provider = Provider.of<SimpleGoalsProvider>(context, listen: false);
              final success = await provider.submitProof(
                goal.id,
                proofController.text,
                null, // No image for now
                date,
                isOverwrite: isOverwrite,
              );
              
              if (context.mounted) {
                Navigator.of(context).pop();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isOverwrite ? 'Proof overwritten successfully!' : 'Proof submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to submit proof'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isOverwrite ? 'Overwrite' : 'Submit'),
          ),
        ],
      ),
    );
  }
}