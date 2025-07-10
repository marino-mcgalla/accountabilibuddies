
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../goals/providers/simple_goals_provider.dart';
import '../../goals/providers/goal_template_provider.dart';
import '../../party/providers/simple_party_provider.dart';
import '../../goals/models/goal_model.dart';
import '../widgets/simple_progress_tracker.dart';

class SimpleDashboard extends StatelessWidget {
  const SimpleDashboard({super.key});

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
          child: Row(
            children: [
              // Story circles for pending proofs
              _buildStoryCircle(context, "JD", Colors.blue, true),
              const SizedBox(width: 12),
              _buildStoryCircle(context, "AS", Colors.green, false),
              const SizedBox(width: 12),
              _buildStoryCircle(context, "MK", Colors.orange, true),
              const SizedBox(width: 12),
              // Add more circles or show "no pending" message
              Expanded(
                child: Center(
                  child: Text(
                    'Tap circles to approve proofs',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCircle(BuildContext context, String initials, Color color, bool hasPending) {
    return GestureDetector(
      onTap: () {
        // TODO: Open story viewer for proof approval
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proof approval for $initials - coming soon!')),
        );
      },
      child: Container(
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
    );
  }

  Widget _buildChallengeStatus(BuildContext context, SimplePartyProvider partyProvider) {
    final firstParty = partyProvider.parties.first;
    final hasActiveChallenge = partyProvider.hasActiveChallenge(firstParty['id']);
    final hasPendingChallenge = partyProvider.hasPendingChallenge(firstParty['id']);
    
    String status = 'No active challenge';
    Color statusColor = Colors.grey;
    
    if (hasActiveChallenge) {
      status = 'Challenge Active';
      statusColor = Colors.green;
    } else if (hasPendingChallenge) {
      status = 'Challenge Pending';
      statusColor = Colors.orange;
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
          ],
        ),
      ),
    );
  }

  Widget _buildYourGoalsSection(BuildContext context, SimpleGoalsProvider goalsProvider) {
    final goals = goalsProvider.activeGoals;
    
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
            
            if (goals.isEmpty)
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
            else
              ...goals.map((goal) => _buildGoalCard(context, goal)).toList(),
          ],
        ),
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
              Text(
                'Progress: ${goal.completionsCount}/${goal.goalFrequency}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
    final TextEditingController proofController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submit Proof for ${goal.goalName}'),
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
                DateTime.now(),
              );
              
              Navigator.of(context).pop();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proof submitted successfully!'),
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
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}