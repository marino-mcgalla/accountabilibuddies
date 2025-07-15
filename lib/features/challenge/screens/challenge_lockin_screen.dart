import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../goals/models/goal_template.dart';
import '../../goals/models/goal_instance.dart';
import '../../goals/services/goal_instance_service.dart';
import '../../goals/providers/goal_template_provider.dart';
import '../../goals/providers/simple_goals_provider.dart';
import '../../party/providers/simple_party_provider.dart';
import '../widgets/wager_selector.dart';

/// Screen for party members to lock in their goals and wager for a challenge
class ChallengeLockinScreen extends StatefulWidget {
  const ChallengeLockinScreen({super.key});

  @override
  State<ChallengeLockinScreen> createState() => _ChallengeLockinScreenState();
}

class _ChallengeLockinScreenState extends State<ChallengeLockinScreen> {
  final GoalInstanceService _goalInstanceService = GoalInstanceService();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  final int _totalSteps = 4; // Goal Selection, Frequency Edit, Wager, Confirmation
  
  List<GoalTemplate> _selectedTemplates = [];
  Map<String, int> _customFrequencies = {};
  double _wagerAmount = 10.0; // Default wager
  bool _isLoading = true;
  bool _isLockingIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserTemplates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTemplates() async {
    try {
      final partyProvider = Provider.of<SimplePartyProvider>(context, listen: false);
      final templateProvider = Provider.of<GoalTemplateProvider>(context, listen: false);
      
      if (partyProvider.partyId == null) {
        setState(() {
          _error = 'No party found';
          _isLoading = false;
        });
        return;
      }

      // Check if user has already locked in (might be editing their lock-in)
      final hasLockedIn = partyProvider.hasUserLockedIn(partyProvider.partyId!);
      
      if (hasLockedIn) {
        // Load existing goal instances for editing
        final instances = await _goalInstanceService.loadInstancesFromChallenge(
          partyId: partyProvider.partyId!,
          challengeType: 'activeChallenge',
          userId: partyProvider.currentUserId!,
        );
        
        // Convert instances back to selected templates for editing
        final templates = <GoalTemplate>[];
        final frequencies = <String, int>{};
        
        for (final instance in instances) {
          // Find the template that matches this instance
          final template = templateProvider.templates.firstWhere(
            (t) => t.id == instance.templateId,
            orElse: () => GoalTemplate(
              id: instance.templateId,
              name: instance.name,
              description: instance.description,
              type: instance.type,
              defaultFrequency: instance.frequency,
              category: instance.category,
              status: GoalStatus.active,
              createdAt: DateTime.now(),
              totalChallengesUsed: 1,
            ),
          );
          templates.add(template);
          frequencies[template.id] = instance.frequency;
        }
        
        setState(() {
          _selectedTemplates = templates;
          _customFrequencies = frequencies;
          _isLoading = false;
        });
      } else {
        // First time lock-in: user starts with no templates selected
        setState(() {
          _selectedTemplates = [];
          _customFrequencies = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading templates: $e';
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Goal selection
        if (_selectedTemplates.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one goal')),
          );
          return false;
        }
        return true;
      case 1: // Frequency editing
        return true; // Always allow proceeding from frequency step
      case 2: // Wager selection
        return true; // Always allow proceeding from wager step
      default:
        return true;
    }
  }

  Future<void> _lockInChallenge() async {
    if (_selectedTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one goal')),
      );
      return;
    }

    setState(() => _isLockingIn = true);

    try {
      final partyProvider = Provider.of<SimplePartyProvider>(context, listen: false);
      
      if (partyProvider.partyId == null) {
        throw Exception('No party found');
      }

      // 1. Create goal instances from selected templates
      final challengeId = 'challenge-${DateTime.now().millisecondsSinceEpoch}';
      final instances = <GoalInstance>[];
      
      for (final template in _selectedTemplates) {
        final frequency = _customFrequencies[template.id] ?? template.defaultFrequency;
        final instance = GoalInstance.fromTemplate(
          template: template,
          partyId: partyProvider.partyId!,
          challengeId: challengeId,
          ownerId: partyProvider.currentUserId!,
          customFrequency: frequency,
        );
        instances.add(instance);
      }
      
      // Save all instances to the challenge
      if (instances.isNotEmpty) {
        await _goalInstanceService.saveInstancesToChallenge(
          partyId: partyProvider.partyId!,
          challengeType: 'activeChallenge',
          userId: partyProvider.currentUserId!,
          instances: instances,
        );
      }

      // 2. Lock in for challenge with wager
      final success = await partyProvider.lockInForChallenge(
        partyProvider.partyId!,
        _wagerAmount,
      );

      if (success) {
        if (mounted) {
          // Refresh goals provider to load newly created goal instances
          final goalsProvider = Provider.of<SimpleGoalsProvider>(context, listen: false);
          await goalsProvider.refreshGoals();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully locked in! Challenge is now active for you.'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/home');
          }
        }
      } else {
        throw Exception('Failed to lock in challenge');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error locking in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLockingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lock In Challenge')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lock In Challenge')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Challenge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lock In Challenge'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGoalSelectionStep(),
                _buildFrequencyEditStep(),
                _buildWagerSelectionStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (index < _totalSteps - 1) const SizedBox(width: 8),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGoalSelectionStep() {
    return Consumer<GoalTemplateProvider>(
      builder: (context, templateProvider, child) {
        if (templateProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Goals',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your personal goal templates to include in this challenge. You can customize frequencies in the next step.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: templateProvider.templates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('No goal templates found'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => context.go('/goal-templates'),
                              child: const Text('Create Templates'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: templateProvider.templates.length,
                        itemBuilder: (context, index) {
                          final template = templateProvider.templates[index];
                          final isSelected = _selectedTemplates.contains(template);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedTemplates.add(template);
                                    _customFrequencies[template.id] = template.defaultFrequency;
                                  } else {
                                    _selectedTemplates.remove(template);
                                    _customFrequencies.remove(template.id);
                                  }
                                });
                              },
                              title: Text(template.name),
                              subtitle: Text('${template.description}\n${template.type.value} • ${template.defaultFrequency} times per week'),
                              isThreeLine: true,
                              secondary: Icon(
                                Icons.flag,
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrequencyEditStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize Frequencies',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust how often you want to complete each goal per week.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: _selectedTemplates.isEmpty
                ? const Center(
                    child: Text('No goals selected'),
                  )
                : ListView.builder(
                    itemCount: _selectedTemplates.length,
                    itemBuilder: (context, index) {
                      final template = _selectedTemplates[index];
                      final currentFrequency = _customFrequencies[template.id] ?? template.defaultFrequency;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(template.name),
                          subtitle: Text(template.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: currentFrequency > 1
                                    ? () {
                                        setState(() {
                                          _customFrequencies[template.id] = currentFrequency - 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$currentFrequency/week',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: currentFrequency < 14
                                    ? () {
                                        setState(() {
                                          _customFrequencies[template.id] = currentFrequency + 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWagerSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Your Wager',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how much you want to wager on completing your goals.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: WagerSelector(
              currentWager: _wagerAmount,
              onWagerChanged: (amount) {
                setState(() {
                  _wagerAmount = amount;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    final totalGoals = _selectedTemplates.length;
    final totalFrequency = _customFrequencies.values.fold(0, (sum, freq) => sum + freq);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Lock-In',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your commitment before locking in.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Challenge summary
                  _buildSummaryCard(
                    'Challenge Summary',
                    Column(
                      children: [
                        _buildSummaryRow('Goals', '$totalGoals goals'),
                        _buildSummaryRow('Total per week', '$totalFrequency completions'),
                        _buildSummaryRow('Your wager', '\$${_wagerAmount.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Goal breakdown
                  _buildSummaryCard(
                    'Your Goals',
                    Column(
                      children: _selectedTemplates.map((template) {
                        final frequency = _customFrequencies[template.id] ?? template.defaultFrequency;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  template.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${frequency}x/week',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Warning/commitment message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Important Commitment',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By locking in, you commit to completing your goals. '
                          'If you fail to meet your commitments, you will lose your wager. '
                          'The money will be distributed among members who complete their goals.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLockingIn ? null : _previousStep,
                child: const Text('Back'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLockingIn ? null : () {
                if (_currentStep == _totalSteps - 1) {
                  _lockInChallenge();
                } else {
                  // Validate current step before proceeding
                  if (_canProceedToNextStep()) {
                    _nextStep();
                  }
                }
              },
              child: _isLockingIn
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == _totalSteps - 1 ? 'Lock In Challenge' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}