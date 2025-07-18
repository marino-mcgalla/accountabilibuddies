import 'package:flutter/material.dart';

/// Widget for selecting wager amount for a challenge
class WagerSelector extends StatelessWidget {
  final double currentWager;
  final Function(double) onWagerChanged;

  const WagerSelector({
    super.key,
    required this.currentWager,
    required this.onWagerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How Wagers Work',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• If you complete all your goals, you keep your wager\n'
                  '• If you fail, your wager goes into the winners\' pool\n'
                  '• Winners split the total pool from failed members\n'
                  '• Higher wagers = higher stakes and potential rewards',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Current wager display
          Center(
            child: Column(
              children: [
                Text(
                  'Your Wager',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '\$${currentWager.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Preset options
          Text(
            'Quick Select',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [5, 10, 25, 50, 100].map((amount) {
              final isSelected = currentWager == amount.toDouble();
              return _buildPresetChip(context, amount.toDouble(), isSelected);
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Custom amount slider
          Text(
            'Custom Amount',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Slider(
                  value: currentWager,
                  min: 5,
                  max: 500,
                  divisions: 99, // 5, 10, 15, ... 500
                  label: '\$${currentWager.toStringAsFixed(0)}',
                  onChanged: (value) {
                    // Round to nearest 5
                    final roundedValue = (value / 5).round() * 5.0;
                    onWagerChanged(roundedValue);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$5',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '\$500',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Risk level indicator
          _buildRiskIndicator(context),

          const SizedBox(height: 24),

          // Example scenarios
          _buildExampleScenarios(context),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, double amount, bool isSelected) {
    return InkWell(
      onTap: () => onWagerChanged(amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(BuildContext context) {
    String level;
    Color color;
    IconData icon;

    if (currentWager <= 10) {
      level = 'Low Risk';
      color = Colors.green;
      icon = Icons.trending_down;
    } else if (currentWager <= 50) {
      level = 'Medium Risk';
      color = Colors.orange;
      icon = Icons.trending_flat;
    } else {
      level = 'High Risk';
      color = Colors.red;
      icon = Icons.trending_up;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  _getRiskDescription(currentWager),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleScenarios(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example Scenarios',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildScenarioRow(
            context,
            '✅ You complete all goals',
            'Keep your \$${currentWager.toStringAsFixed(0)} + potential winnings',
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildScenarioRow(
            context,
            '❌ You fail to complete goals',
            'Lose your \$${currentWager.toStringAsFixed(0)} wager',
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildScenarioRow(
            context,
            '🏆 You win with others failing',
            'Keep \$${currentWager.toStringAsFixed(0)} + share of failed wagers',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioRow(BuildContext context, String scenario, String outcome, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scenario,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                outcome,
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

  String _getRiskDescription(double wager) {
    if (wager <= 10) {
      return 'Good for trying out challenges with minimal financial commitment.';
    } else if (wager <= 50) {
      return 'Balanced risk that provides motivation without major financial stress.';
    } else {
      return 'High stakes for serious commitment. Make sure you\'re confident!';
    }
  }
}