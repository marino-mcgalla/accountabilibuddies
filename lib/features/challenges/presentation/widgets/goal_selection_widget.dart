import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../goals/domain/entities/goal_template.dart';
import '../../domain/entities/goal_commitment.dart';

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
      goalType: goalTemplate.goalType,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Your Goals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_selectedConfigs.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedConfigs.length} selected',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ...(widget.availableGoals.map((goal) {
              final isSelected = _isGoalSelected(goal.id);
              final selectedConfig = isSelected 
                  ? _selectedConfigs.firstWhere((config) => config.goalId == goal.id)
                  : null;
                  
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _UnifiedGoalCard(
                  goalTemplate: goal,
                  isSelected: isSelected,
                  selectedConfig: selectedConfig,
                  onToggle: () => isSelected ? _removeGoal(goal.id) : _addGoal(goal),
                  onFrequencyChanged: isSelected 
                      ? (frequency) => _updateGoalFrequency(goal.id, frequency)
                      : null,
                ),
              );
            })),
          ],
        ),
      ),
    );
  }
}

class _UnifiedGoalCard extends StatelessWidget {
  const _UnifiedGoalCard({
    required this.goalTemplate,
    required this.isSelected,
    required this.onToggle,
    this.selectedConfig,
    this.onFrequencyChanged,
  });

  final GoalTemplate goalTemplate;
  final bool isSelected;
  final GoalCommitment? selectedConfig;
  final VoidCallback onToggle;
  final ValueChanged<int>? onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
            : null,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Main content row with fixed layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add/Remove button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.add,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Goal info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goalTemplate.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goalTemplate.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _CategoryChip(category: goalTemplate.category),
                            const SizedBox(width: 8),
                            if (goalTemplate.plannedFrequency != null && !isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Suggested: ${goalTemplate.plannedFrequency}x/week',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Frequency selector area - always present but only visible when selected
              const SizedBox(height: 12),
              SizedBox(
                height: 40, // Fixed height for frequency selector
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelected ? 1.0 : 0.0,
                    child: isSelected && selectedConfig != null && onFrequencyChanged != null
                        ? _CompactFrequencySelector(
                            frequency: selectedConfig!.weeklyFrequency,
                            onChanged: onFrequencyChanged!,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
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

class _CompactFrequencySelector extends StatelessWidget {
  const _CompactFrequencySelector({
    required this.frequency,
    required this.onChanged,
  });

  final int frequency;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Target:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: frequency > 1 ? () => onChanged(frequency - 1) : null,
                iconSize: 18,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
                color: Theme.of(context).colorScheme.primary,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: Text(
                  '$frequency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: frequency < 7 ? () => onChanged(frequency + 1) : null,
                iconSize: 18,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          frequency == 1 ? 'time/week' : 'times/week',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
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