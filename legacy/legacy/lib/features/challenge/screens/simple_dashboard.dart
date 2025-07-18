
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
import '../widgets/story_circle.dart';
import '../widgets/challenge_invitation_widget.dart';
import '../providers/multi_party_challenge_provider.dart';
import '../../goals/widgets/simple_proof_submission_dialog.dart';
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

    final currentParty = partyProvider.currentParty;
    final activeChallenge = currentParty?['activeChallenge'] as Map<String, dynamic>?;
    final pendingChallenge = currentParty?['pendingChallenge'] as Map<String, dynamic>?;
    final challengeId = activeChallenge?['id'] ?? pendingChallenge?['id'];

    if (challengeId != null) {
      _proofSubscription = FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .collection('memberGoals')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _cachedMemberProofs = _processSnapshotData(snapshot, currentParty, partyProvider);
          });
        }
      });
    } else {
      // No challenge yet, but still show party members with no proofs
      setState(() {
        // Create empty member data for all party members
        final members = currentParty?['members'] as List? ?? [];
        final List<Map<String, dynamic>> emptyMemberData = [];
        
        for (final memberId in members) {
          if (memberId is String) {
            emptyMemberData.add({
              'userId': memberId,
              'userName': partyProvider.getUserDisplayName(memberId),
              'proofs': <Map<String, dynamic>>[],
              'goals': <Goal>[],
            });
          }
        }
        
        _cachedMemberProofs = emptyMemberData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 0,
        actions: [
          Consumer<SimplePartyProvider>(
            builder: (context, partyProvider, child) {
              if (!partyProvider.hasParties || partyProvider.parties.length == 1) {
                return const SizedBox.shrink();
              }
              
              return PopupMenuButton<String>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      partyProvider.partyName ?? 'Select Party',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
                onSelected: (String partyId) {
                  partyProvider.setCurrentParty(partyId);
                },
                itemBuilder: (BuildContext context) {
                  return partyProvider.parties.map((party) {
                    final partyId = party['id'] as String;
                    final partyName = party['name'] as String;
                    final isSelected = partyProvider.currentPartyId == partyId;
                    
                    return PopupMenuItem<String>(
                      value: partyId,
                      child: Row(
                        children: [
                          if (isSelected) 
                            Icon(
                              Icons.check, 
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          else 
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(partyName)),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer4<SimpleGoalsProvider, GoalTemplateProvider, SimplePartyProvider, MultiPartyChallengeProvider>(
        builder: (context, goalsProvider, templateProvider, partyProvider, challengeProvider, child) {
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
                // Challenge Invitations
                const ChallengeInvitationWidget(),
                
                // Story-style Proof Notifications
                _buildProofStoriesSection(context, partyProvider),
                const SizedBox(height: 8),
                
                // Challenge Status or Party Progress
                if (partyProvider.hasParties)
                  _buildChallengeStatusOrPartyProgress(context, partyProvider),
                
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
    // Don't show this section if user has no parties
    if (!partyProvider.hasParties) {
      return const SizedBox.shrink();
    }
    
    // Set up subscription if not already done and party data is available
    if (_proofSubscription == null) {
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

  List<Map<String, dynamic>> _processSnapshotData(QuerySnapshot snapshot, Map<String, dynamic>? currentParty, SimplePartyProvider partyProvider) {
    if (currentParty == null) return [];
    
    
    // Get party members
    final members = currentParty['members'] as List?;
    
    // Initialize all party members
    final Map<String, List<Map<String, dynamic>>> proofsPerUser = {};
    final Map<String, List<Goal>> goalsPerUser = {};
    final Map<String, String> userNames = {};
    
    if (members != null) {
      for (final memberId in members) {
        if (memberId is String) {
          proofsPerUser[memberId] = [];
          goalsPerUser[memberId] = [];
          userNames[memberId] = partyProvider.getUserDisplayName(memberId);
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
        goalsPerUser[memberId] = [];
        userNames[memberId] = partyProvider.getUserDisplayName(memberId);
      }
      
      for (var goalData in userGoals) {
        try {
          final goal = Goal.fromMap(Map<String, dynamic>.from(goalData));
          
          // Store all goals for this user
          goalsPerUser[memberId]!.add(goal);
          
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
    for (final userId in proofsPerUser.keys) {
      final proofsList = proofsPerUser[userId] ?? [];
      final goalsList = goalsPerUser[userId] ?? [];
      
      result.add({
        'userId': userId,
        'userName': userNames[userId] ?? 'Unknown',
        'proofs': proofsList,
        'goals': goalsList,
      });
    }
    
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
    
    
    // Find the most recent pending proof image
    String? mostRecentImageUrl;
    if (hasPending && proofs.isNotEmpty) {
      // Sort proofs by submission date (most recent first)
      final sortedProofs = List<Map<String, dynamic>>.from(proofs);
      sortedProofs.sort((a, b) {
        final proofA = a['proof'] as Proof;
        final proofB = b['proof'] as Proof;
        return proofB.submissionDate.compareTo(proofA.submissionDate);
      });
      
      // Get the most recent proof's image URL
      final mostRecentProof = sortedProofs.first['proof'] as Proof;
      mostRecentImageUrl = mostRecentProof.imageUrl;
    }
    
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
          StoryCircle(
            imageUrl: mostRecentImageUrl,
            hasNotification: hasPending,
            child: mostRecentImageUrl == null ? CircleAvatar(
              backgroundColor: color,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ) : null,
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

  Widget _buildChallengeStatusOrPartyProgress(BuildContext context, SimplePartyProvider partyProvider) {
    final hasUserLockedIn = partyProvider.lockedInMembers.contains(partyProvider.currentUserId);
    
    // If user is locked in, show party progress instead of challenge status
    if (hasUserLockedIn) {
      return _buildPartyProgress(context, partyProvider);
    } else {
      return _buildChallengeStatus(context, partyProvider);
    }
  }

  Widget _buildPartyProgress(BuildContext context, SimplePartyProvider partyProvider) {
    // Use the cached member data if available, otherwise show loading
    if (_cachedMemberProofs == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Party Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Party Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._cachedMemberProofs!.map((memberData) {
              final userId = memberData['userId'] as String;
              final userName = memberData['userName'] as String;
              final proofs = memberData['proofs'] as List<Map<String, dynamic>>;
              final goals = memberData['goals'] as List<Goal>? ?? [];
              
              return _buildMemberProgressRow(context, userId, userName, proofs, goals);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberProgressRow(BuildContext context, String userId, String userName, List<Map<String, dynamic>> proofs, List<Goal> goals) {
    final currentUserId = Provider.of<SimplePartyProvider>(context, listen: false).currentUserId;
    final isCurrentUser = userId == currentUserId;
    int pendingProofsCount = proofs.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser 
            ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: isCurrentUser ? Theme.of(context).colorScheme.primary : Colors.blue,
                child: Text(
                  userName.isNotEmpty 
                      ? userName.substring(0, 2).toUpperCase()
                      : '??',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              Text(
                isCurrentUser ? '$userName (You)' : userName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (pendingProofsCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingProofsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          // Individual goal progress bars
          if (goals.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...goals.map((goal) => _buildIndividualGoalProgress(context, goal)),
          ],
        ],
      ),
    );
  }

  Widget _buildIndividualGoalProgress(BuildContext context, Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Goal name (truncated)
          SizedBox(
            width: 80,
            child: Text(
              goal.goalName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          
          // Progress bar based on goal type
          Expanded(
            child: Container(
              height: 8,
              child: goal.goalType == GoalType.daily 
                  ? _buildDailyGoalProgressBar(context, goal)
                  : _buildTotalGoalProgressBar(context, goal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalProgressBar(BuildContext context, Goal goal) {
    // Generate days of the week (Mon-Sun)
    final now = DateTime.now();
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final daysOfWeek = List.generate(7, (index) {
      final date = mondayOfWeek.add(Duration(days: index));
      return date.toIso8601String().split('T')[0];
    });

    final completions = goal.challengeData?.completions ?? {};
    final plannedDays = goal.challengeData?.plannedDays ?? <int>{};

    return Row(
      children: daysOfWeek.asMap().entries.map((entry) {
        final index = entry.key;
        final dateString = entry.value;
        final dayOfWeek = index + 1; // Convert 0-based index to 1-based day (Mon=1, Sun=7)
        final status = completions[dateString] ?? 'default';
        final isPlanned = plannedDays.contains(dayOfWeek);
        
        Color dayColor;
        
        // Prioritize actual completion status over planning
        switch (status) {
          case 'pending':
            dayColor = Colors.yellow[700]!;
            break;
          case 'completed':
            dayColor = Colors.green;
            break;
          case 'denied':
            dayColor = Colors.red;
            break;
          default:
            // If no actual status, check if it's planned
            dayColor = isPlanned ? Colors.blue : Colors.grey[300]!;
        }
        
        return Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            decoration: BoxDecoration(
              color: dayColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalGoalProgressBar(BuildContext context, Goal goal) {
    final challengeData = goal.challengeData;
    if (challengeData == null) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final totalProofs = challengeData.proofs;
    final frequency = goal.goalFrequency;
    
    if (frequency == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // Count proofs by status
    int approvedCount = 0;
    int pendingCount = 0;
    int deniedCount = 0;
    
    for (final proof in totalProofs) {
      switch (proof.status) {
        case ProofStatus.approved:
          approvedCount++;
          break;
        case ProofStatus.pending:
          pendingCount++;
          break;
        case ProofStatus.denied:
          deniedCount++;
          break;
      }
    }

    // Calculate the number of empty slots
    final totalSubmitted = approvedCount + pendingCount + deniedCount;
    final emptySlots = frequency - totalSubmitted;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Approved sections (green)
          ...List.generate(approvedCount, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
          // Pending sections (yellow)
          ...List.generate(pendingCount, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.yellow[700]!,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
          // Denied sections (red)
          ...List.generate(deniedCount, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
          // Empty sections (grey)
          ...List.generate(emptySlots, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.grey[300]!,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChallengeStatus(BuildContext context, SimplePartyProvider partyProvider) {
    final hasActiveChallenge = partyProvider.currentPartyHasActiveChallenge;
    final hasPendingChallenge = partyProvider.currentPartyHasPendingChallenge;
    final hasUserLockedIn = partyProvider.lockedInMembers.contains(partyProvider.currentUserId);
    
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
                  // Challenge creation buttons for party leaders when no challenge exists
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Multi-Party Challenge button
                          TextButton.icon(
                            onPressed: () => context.go('/create-multi-party-challenge'),
                            icon: const Icon(Icons.groups, size: 16),
                            label: const Text('Multi-Party'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Single-Party Challenge button
                          ElevatedButton.icon(
                            onPressed: () => context.go('/challenge-setup'),
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text('Start Challenge'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
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
            partyProvider.lockedInMembers.contains(partyProvider.currentUserId);
        final needsToLockIn = hasChallenge && !hasUserLockedIn;
        
        // During the transition period, if there's a challenge but user hasn't locked in,
        // we don't show goals because they need to lock in first to create their instances
    
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
    showDialog(
      context: context,
      builder: (context) => SimpleProofSubmissionDialog(
        goal: goal,
        isOverwrite: isOverwrite,
        onSubmit: (imageUrl, yesterday) async {
          final provider = Provider.of<SimpleGoalsProvider>(context, listen: false);
          final submissionDate = yesterday ? date.subtract(const Duration(days: 1)) : date;
          
          final success = await provider.submitProof(
            goal.id,
            imageUrl ?? '', // Use empty string as placeholder text since we're using images
            imageUrl,
            submissionDate,
            isOverwrite: isOverwrite,
          );
          
          if (context.mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isOverwrite ? 'Proof replaced successfully!' : 'Proof submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit proof'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}