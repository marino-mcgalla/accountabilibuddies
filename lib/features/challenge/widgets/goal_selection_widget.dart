import 'package:flutter/material.dart';
import '../../goals/models/goal_template.dart';

/// Widget for selecting goal templates and customizing frequencies for a challenge
class GoalSelectionWidget extends StatelessWidget {
  final List<GoalTemplate> availableTemplates;
  final List<GoalTemplate> selectedTemplates;
  final Map<String, int> customFrequencies;
  final Function(List<GoalTemplate>, Map<String, int>) onSelectionChanged;

  const GoalSelectionWidget({
    Key? key,
    required this.availableTemplates,
    required this.selectedTemplates,
    required this.customFrequencies,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (availableTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Goal Templates Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create some goal templates first before setting up a challenge.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to goal templates screen
                Navigator.of(context).pushNamed('/goal-templates');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Goal Templates'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Selection summary
        if (selectedTemplates.isNotEmpty)
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
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${selectedTemplates.length} goal${selectedTemplates.length == 1 ? '' : 's'} selected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onSelectionChanged([], {});
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

        // Goal template list
        Expanded(
          child: ListView.builder(
            itemCount: availableTemplates.length,
            itemBuilder: (context, index) {
              final template = availableTemplates[index];
              final isSelected = selectedTemplates.any((t) => t.id == template.id);
              final customFreq = customFrequencies[template.id];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      _toggleSelection(template, selected ?? false);
                    },
                    title: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(template.type).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                template.type.value.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getTypeColor(template.type),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${customFreq ?? template.defaultFrequency}x per week',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    secondary: isSelected
                        ? _buildFrequencyControls(template, customFreq ?? template.defaultFrequency)
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyControls(GoalTemplate template, int currentFrequency) {
    return Container(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Frequency',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: currentFrequency > 1
                    ? () => _updateFrequency(template, currentFrequency - 1)
                    : null,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: currentFrequency > 1 ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 14,
                    color: currentFrequency > 1 ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentFrequency.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: currentFrequency < 7
                    ? () => _updateFrequency(template, currentFrequency + 1)
                    : null,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: currentFrequency < 7 ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 14,
                    color: currentFrequency < 7 ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return Colors.green;
      case GoalType.total:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _toggleSelection(GoalTemplate template, bool selected) {
    final List<GoalTemplate> newSelection = List.from(selectedTemplates);
    final Map<String, int> newFrequencies = Map.from(customFrequencies);

    if (selected) {
      newSelection.add(template);
      newFrequencies[template.id] = template.defaultFrequency;
    } else {
      newSelection.removeWhere((t) => t.id == template.id);
      newFrequencies.remove(template.id);
    }

    onSelectionChanged(newSelection, newFrequencies);
  }

  void _updateFrequency(GoalTemplate template, int newFrequency) {
    final Map<String, int> newFrequencies = Map.from(customFrequencies);
    newFrequencies[template.id] = newFrequency;
    onSelectionChanged(selectedTemplates, newFrequencies);
  }
}