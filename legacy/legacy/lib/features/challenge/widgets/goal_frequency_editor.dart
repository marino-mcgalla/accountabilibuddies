import 'package:flutter/material.dart';
import '../../goals/models/goal_instance.dart';

/// Widget for editing goal frequencies during challenge lock-in
class GoalFrequencyEditor extends StatelessWidget {
  final List<GoalInstance> goalInstances;
  final Map<String, int> customFrequencies;
  final Function(Map<String, int>) onFrequenciesChanged;

  const GoalFrequencyEditor({
    super.key,
    required this.goalInstances,
    required this.customFrequencies,
    required this.onFrequenciesChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (goalInstances.isEmpty) {
      return Center(
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
              'No Goals Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('There are no goals set up for this challenge.'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can adjust how often you want to complete each goal per week. '
                  'These are your personal targets for this challenge.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),

        // Goal list
        Expanded(
          child: ListView.builder(
            itemCount: goalInstances.length,
            itemBuilder: (context, index) {
              final instance = goalInstances[index];
              final currentFrequency = customFrequencies[instance.templateId] ?? instance.frequency;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Goal header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  instance.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  instance.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Goal type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(instance.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              instance.type.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getTypeColor(instance.type),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Frequency controls
                      Row(
                        children: [
                          Text(
                            'Frequency per week:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _buildFrequencyControls(instance, currentFrequency),
                        ],
                      ),
                      
                      // Show total weekly commitment
                      const SizedBox(height: 8),
                      Text(
                        _getCommitmentText(instance.type, currentFrequency),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Summary footer
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total weekly targets:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${customFrequencies.values.fold(0, (sum, freq) => sum + freq)} completions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyControls(GoalInstance instance, int currentFrequency) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: currentFrequency > 1
                ? () => _updateFrequency(instance, currentFrequency - 1)
                : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentFrequency > 1 
                    ? Colors.blue.withValues(alpha: 0.1) 
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.remove,
                color: currentFrequency > 1 ? Colors.blue : Colors.grey,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Text(
                currentFrequency.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: currentFrequency < 7
                ? () => _updateFrequency(instance, currentFrequency + 1)
                : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentFrequency < 7 
                    ? Colors.blue.withValues(alpha: 0.1) 
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.add,
                color: currentFrequency < 7 ? Colors.blue : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(dynamic type) {
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('daily')) {
      return Colors.green;
    } else if (typeString.contains('total')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  String _getCommitmentText(dynamic type, int frequency) {
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('daily')) {
      return 'Complete this goal $frequency time${frequency == 1 ? '' : 's'} per week';
    } else if (typeString.contains('total')) {
      return 'Track $frequency completion${frequency == 1 ? '' : 's'} per week';
    }
    return 'Complete $frequency time${frequency == 1 ? '' : 's'} per week';
  }

  void _updateFrequency(GoalInstance instance, int newFrequency) {
    final Map<String, int> newFrequencies = Map.from(customFrequencies);
    newFrequencies[instance.templateId] = newFrequency;
    onFrequenciesChanged(newFrequencies);
  }
}