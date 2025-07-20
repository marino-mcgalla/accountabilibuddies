import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_commitment.dart';
import '../widgets/goal_selection_widget.dart';
import '../widgets/wager_setting_widget.dart';

class ChallengeCommitmentPage extends ConsumerStatefulWidget {
  const ChallengeCommitmentPage({
    required this.challenge,
    super.key,
  });

  final Challenge challenge;

  @override
  ConsumerState<ChallengeCommitmentPage> createState() => _ChallengeCommitmentPageState();
}

class _ChallengeCommitmentPageState extends ConsumerState<ChallengeCommitmentPage> {
  List<GoalCommitment> _selectedGoalConfigs = [];
  double? _wagerAmount;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commit to Challenge'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Column(
        children: [
          // Challenge Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.challenge.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.challenge.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(widget.challenge.startDate)} - ${_formatDate(widget.challenge.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                if (widget.challenge.commitmentDeadline != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Commit by ${_formatDateTime(widget.challenge.commitmentDeadline!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal Selection Section
                  Text(
                    'Select Your Goals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose which goals you want to commit to for this challenge and set how often you plan to complete them.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // TODO: Replace with actual goal templates from provider
                  GoalSelectionWidget(
                    availableGoals: _getMockGoalTemplates(),
                    selectedGoalConfigs: _selectedGoalConfigs,
                    onGoalConfigsChanged: (configs) {
                      setState(() {
                        _selectedGoalConfigs = configs;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // Wager Setting Section
                  Text(
                    'Set Your Wager',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how much you\'re willing to risk. You\'ll only keep your wager if you achieve 100% completion.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  WagerSettingWidget(
                    wagerAmount: _wagerAmount,
                    onWagerChanged: (amount) {
                      setState(() {
                        _wagerAmount = amount;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // Summary Section
                  if (_selectedGoalConfigs.isNotEmpty) ...[
                    _CommitmentSummary(
                      goalConfigs: _selectedGoalConfigs,
                      wagerAmount: _wagerAmount,
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _optOut(),
                    child: const Text('Opt Out'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedGoalConfigs.isEmpty 
                        ? null 
                        : () => _commitToChallenge(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Commit to Challenge'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _commitToChallenge() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual commitment logic using use cases
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully committed to challenge!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to commit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _optOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opt Out of Challenge'),
        content: const Text('Are you sure you want to opt out of this challenge? You can still change your mind before the commitment deadline.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Opt Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement actual opt-out logic using use cases
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call
        
        if (mounted) {
          Navigator.of(context).pop(false); // Return false to indicate opt-out
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have opted out of this challenge.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to opt out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // TODO: Replace with actual goal templates from provider
  List<GoalTemplate> _getMockGoalTemplates() {
    return [
      GoalTemplate(
        id: '1',
        userId: 'user1',
        title: 'Morning Workout',
        description: 'Complete a 30-minute workout session',
        category: GoalCategory.fitness,
        goalType: GoalType.daily,
        plannedFrequency: 5,
        tags: ['fitness', 'morning'],
        status: GoalTemplateStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {},
      ),
      GoalTemplate(
        id: '2',
        userId: 'user1',
        title: 'Read for 30 minutes',
        description: 'Read books or educational material',
        category: GoalCategory.learning,
        goalType: GoalType.daily,
        plannedFrequency: 7,
        tags: ['reading', 'education'],
        status: GoalTemplateStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {},
      ),
      GoalTemplate(
        id: '3',
        userId: 'user1',
        title: 'Meditate',
        description: '10-15 minutes of mindfulness meditation',
        category: GoalCategory.health,
        goalType: GoalType.daily,
        plannedFrequency: 3,
        tags: ['meditation', 'mindfulness'],
        status: GoalTemplateStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {},
      ),
    ];
  }
}

class _CommitmentSummary extends StatelessWidget {
  const _CommitmentSummary({
    required this.goalConfigs,
    required this.wagerAmount,
  });

  final List<GoalCommitment> goalConfigs;
  final double? wagerAmount;

  @override
  Widget build(BuildContext context) {
    final totalWeeklyGoals = goalConfigs.fold<int>(0, (sum, config) => sum + config.weeklyFrequency);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Commitment Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goals Selected:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${goalConfigs.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Weekly Completions:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '$totalWeeklyGoals',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wager Amount:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  wagerAmount != null ? '\$${wagerAmount!.toStringAsFixed(2)}' : 'No wager',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: wagerAmount != null 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}