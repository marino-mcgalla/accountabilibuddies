import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../domain/entities/challenge_commitment.dart';

class GoalSelectionWidget extends ConsumerStatefulWidget {
  const GoalSelectionWidget({
    required this.availableGoals,
    required this.selectedGoalConfigs,
    required this.onGoalConfigsChanged,
    super.key,
  });

  final List<GoalTemplate> availableGoals;
  final List<GoalCommitment> selectedGoalConfigs;
  final ValueChanged<List<GoalCommitment>> onGoalConfigsChanged;

  @override
  ConsumerState<GoalSelectionWidget> createState() => _GoalSelectionWidgetState();
}

class _GoalSelectionWidgetState extends ConsumerState<GoalSelectionWidget> {
  late List<GoalCommitment> _selectedConfigs;

  @override
  void initState() {
    super.initState();
    _selectedConfigs = List.from(widget.selectedGoalConfigs);
  }

  @override
  void didUpdateWidget(GoalSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedGoalConfigs != oldWidget.selectedGoalConfigs) {
      _selectedConfigs = List.from(widget.selectedGoalConfigs);
    }
  }

  void _updateGoalConfigs() {
    widget.onGoalConfigsChanged(_selectedConfigs);
  }

  void _addGoal(GoalTemplate goalTemplate) {
    final config = GoalCommitment(
      goalId: goalTemplate.id,
      goalName: goalTemplate.title,
      weeklyFrequency: goalTemplate.plannedFrequency ?? 1,
      parameters: {},
      description: goalTemplate.description,
    );
    
    setState(() {
      _selectedConfigs.add(config);
    });
    _updateGoalConfigs();
  }

  void _removeGoal(String goalId) {
    setState(() {
      _selectedConfigs.removeWhere((config) => config.goalId == goalId);
    });
    _updateGoalConfigs();
  }

  void _updateGoalFrequency(String goalId, int newFrequency) {
    setState(() {
      final index = _selectedConfigs.indexWhere((config) => config.goalId == goalId);
      if (index >= 0) {
        _selectedConfigs[index] = _selectedConfigs[index].copyWith(
          weeklyFrequency: newFrequency,
        );
      }
    });
    _updateGoalConfigs();
  }

  bool _isGoalSelected(String goalId) {
    return _selectedConfigs.any((config) => config.goalId == goalId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableGoals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Goal Templates Available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create some goal templates first to use in challenges.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Goals Section
        if (_selectedConfigs.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Selected Goals (${_selectedConfigs.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...(_selectedConfigs.map((config) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: _SelectedGoalCard(
                        goalConfig: config,
                        onFrequencyChanged: (frequency) => _updateGoalFrequency(config.goalId, frequency),
                        onRemove: () => _removeGoal(config.goalId),
                      ),
                    );
                  })),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Available Goals Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Goals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...(widget.availableGoals.map((goal) {
                  final isSelected = _isGoalSelected(goal.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _AvailableGoalCard(
                      goalTemplate: goal,
                      isSelected: isSelected,
                      onTap: isSelected ? null : () => _addGoal(goal),
                    ),
                  );
                })),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedGoalCard extends StatelessWidget {
  const _SelectedGoalCard({
    required this.goalConfig,
    required this.onFrequencyChanged,
    required this.onRemove,
  });

  final GoalCommitment goalConfig;
  final ValueChanged<int> onFrequencyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goalConfig.goalName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (goalConfig.description != null) ...[
            const SizedBox(height: 4),
            Text(
              goalConfig.description!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          _FrequencySelector(
            frequency: goalConfig.weeklyFrequency,
            onChanged: onFrequencyChanged,
          ),
        ],
      ),
    );
  }
}

class _AvailableGoalCard extends StatelessWidget {
  const _AvailableGoalCard({
    required this.goalTemplate,
    required this.isSelected,
    required this.onTap,
  });

  final GoalTemplate goalTemplate;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goalTemplate.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goalTemplate.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _CategoryChip(category: goalTemplate.category),
                      const SizedBox(width: 8),
                      if (goalTemplate.plannedFrequency != null)
                        Text(
                          '${goalTemplate.plannedFrequency}x/week',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            else
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final GoalCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({
    required this.frequency,
    required this.onChanged,
  });

  final int frequency;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Frequency:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: frequency > 1 ? () => onChanged(frequency - 1) : null,
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$frequency',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: frequency < 7 ? () => onChanged(frequency + 1) : null,
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
        const SizedBox(width: 8),
        Text(
          frequency == 1 ? 'time/week' : 'times/week',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}