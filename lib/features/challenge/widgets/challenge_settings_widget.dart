import 'package:flutter/material.dart';

/// Widget for configuring challenge settings like dates and options
class ChallengeSettingsWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool allowMemberFrequencyCustomization;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final Function(bool) onAllowCustomizationChanged;

  const ChallengeSettingsWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.allowMemberFrequencyCustomization,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onAllowCustomizationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final duration = endDate.difference(startDate).inDays;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration section
          _buildSection(
            context,
            'Challenge Duration',
            Column(
              children: [
                // Start date
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Start Date'),
                  subtitle: Text(_formatDate(startDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _selectStartDate(context),
                ),
                
                // End date
                ListTile(
                  leading: const Icon(Icons.stop),
                  title: const Text('End Date'),
                  subtitle: Text(_formatDate(endDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _selectEndDate(context),
                ),
                
                // Duration display
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Challenge Duration: $duration day${duration == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Member options section
          _buildSection(
            context,
            'Member Options',
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Allow Frequency Customization'),
                  subtitle: const Text(
                    'Let members adjust goal frequencies during lock-in phase',
                  ),
                  value: allowMemberFrequencyCustomization,
                  onChanged: onAllowCustomizationChanged,
                  secondary: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick duration presets
          _buildSection(
            context,
            'Quick Presets',
            Column(
              children: [
                Text(
                  'Set common challenge durations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip(context, '1 Week', 7),
                    _buildPresetChip(context, '2 Weeks', 14),
                    _buildPresetChip(context, '1 Month', 30),
                    _buildPresetChip(context, '3 Months', 90),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info section
          _buildSection(
            context,
            'Important Notes',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoItem(
                  context,
                  Icons.access_time,
                  'Lock-in Period',
                  'Members have until the start date to lock in their participation',
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  context,
                  Icons.group,
                  'All Members',
                  'All party members will receive the selected goals',
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  context,
                  Icons.edit,
                  'No Changes',
                  'Challenge settings cannot be changed once created',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
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
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, int days) {
    final isSelected = endDate.difference(startDate).inDays == days;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final newEndDate = startDate.add(Duration(days: days));
          onEndDateChanged(newEndDate);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Challenge Start Date',
    );
    
    if (date != null) {
      onStartDateChanged(date);
      
      // Ensure end date is after start date
      if (endDate.isBefore(date)) {
        onEndDateChanged(date.add(const Duration(days: 7)));
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate.add(const Duration(days: 1)),
      lastDate: startDate.add(const Duration(days: 365)),
      helpText: 'Select Challenge End Date',
    );
    
    if (date != null) {
      onEndDateChanged(date);
    }
  }
}