import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../../goals/presentation/providers/goal_template_providers.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_goal.dart';
import '../../domain/entities/goal_commitment.dart';
import '../../domain/entities/user_challenge_participation.dart';
import '../providers/challenge_providers.dart';
import '../widgets/goal_selection_widget.dart';
import '../widgets/wager_setting_widget.dart';
import '../../../../core/utils/display_name_utils.dart';

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
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final user = ref.watch(userProvider);
                      if (user == null) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Please log in to select goals'),
                          ),
                        );
                      }

                      final goalTemplatesAsync = ref.watch(goalTemplatesProvider);
                      
                      return goalTemplatesAsync.when(
                        data: (goalTemplates) {
                          final activeGoals = goalTemplates
                              .where((goal) => goal.status == GoalTemplateStatus.active)
                              .toList();
                              
                          return GoalSelectionWidget(
                            availableGoals: activeGoals,
                            selectedGoalConfigs: _selectedGoalConfigs,
                            onGoalConfigsChanged: (configs) {
                              setState(() {
                                _selectedGoalConfigs = configs;
                              });
                            },
                          );
                        },
                        loading: () => const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        error: (error, stack) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, size: 48),
                                const SizedBox(height: 8),
                                Text('Error loading goal templates: $error'),
                              ],
                            ),
                          ),
                        ),
                      );
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
                    'Choose how much you\'re willing to risk. You\'ll only keep your wager if you achieve 100% completion. All wagers go into the weekly pool. Enter \$0 to play for accountability only.',
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
                    onPressed: _isLoading || _selectedGoalConfigs.isEmpty || _wagerAmount == null || _wagerAmount! < 0
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
    final user = ref.read(userProvider);
    if (user == null) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('You must be logged in to commit to a challenge'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final challengeRepository = ref.read(challengeRepositoryProvider);
      
      // Create goals map from selected goal configs
      final goalsMap = <String, ChallengeGoal>{};
      for (final config in _selectedGoalConfigs) {
        final goalId = config.goalId;
        goalsMap[goalId] = ChallengeGoal(
          name: config.goalName,
          templateId: config.goalId,
          targetFrequency: config.weeklyFrequency,
          description: config.description ?? '',
          goalType: config.goalType,
          completedDates: const [],
          parameters: config.parameters,
        );
      }
      
      // Create the user's participation with embedded goals
      final participation = UserChallengeParticipation(
        id: '', // Will be set by repository
        challengeId: widget.challenge.id,
        userId: user.id,
        userName: DisplayNameUtils.getDisplayNameSync(user),
        status: ParticipationStatus.lockedIn,
        goals: goalsMap,
        wagerAmount: _wagerAmount,
        wagerCurrency: 'USD',
        lockedInDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {},
      );

      // logger.debug('Creating participation for user ${user.id} in challenge ${widget.challenge.id} with ${goalsMap.length} goals');
      final participationResult = await challengeRepository.saveParticipation(participation);
      
      if (participationResult.isFailure) {
        throw Exception('Failed to save participation: ${participationResult.failureOrNull!.message}');
      }

      final savedParticipation = participationResult.valueOrNull!;
      // logger.debug('Participation created with ID: ${savedParticipation.id}');

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Successfully committed to challenge with ${goalsMap.length} goals!'),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      }
    } catch (e, stackTrace) {
      logger.error('Error committing to challenge', error: e, stackTrace: stackTrace);
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to commit: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
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
        content: const Text('Are you sure you want to opt out of this challenge? This will remove any existing commitment you may have.'),
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
      final user = ref.read(userProvider);
      if (user == null) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final challengeRepository = ref.read(challengeRepositoryProvider);
        
        // Check if user has an existing participation
        final participationResult = await challengeRepository.getUserParticipation(
          widget.challenge.id, 
          user.id,
        );
        
        if (participationResult.isSuccess && participationResult.valueOrNull != null) {
          // Delete the participation (goals are embedded, so they get deleted automatically)
          await challengeRepository.deleteParticipation(widget.challenge.id, user.id);
          
          // logger.debug('Removed participation for user ${user.id}');
        }
        
        if (mounted) {
          Navigator.of(context).pop(false); // Return false to indicate opt-out
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('You have opted out of this challenge.'),
          //   ),
          // );
        }
      } catch (e, stackTrace) {
        logger.error('Error opting out of challenge', error: e, stackTrace: stackTrace);
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Failed to opt out: $e'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
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