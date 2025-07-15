import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/simple_goals_provider.dart';
import '../providers/goal_template_provider.dart';
import '../models/goal_model.dart';

class MyGoalsScreen extends StatelessWidget {
  const MyGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        elevation: 0,
      ),
      body: Consumer2<SimpleGoalsProvider, GoalTemplateProvider>(
        builder: (context, goalsProvider, templateProvider, child) {
          if (goalsProvider.isLoading || templateProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Goals Section
                _buildActiveGoalsSection(context, goalsProvider),
                
                const SizedBox(height: 24),
                
                // Goal Templates Section  
                _buildTemplatesSection(context, templateProvider),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveGoalsSection(BuildContext context, SimpleGoalsProvider goalsProvider) {
    final activeGoals = goalsProvider.activeGoals;
    
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
                  'Active Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${activeGoals.length} active',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (activeGoals.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Goals Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create goals from your templates to start tracking progress!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/'),  // Go to dashboard to create goals
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Goal'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...activeGoals.map((goal) => _buildGoalCard(context, goal)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    int completionsCount = 0;
    if (goal.challengeData != null) {
      if (goal.goalType == GoalType.daily) {
        completionsCount = goal.challengeData!.totalCompletions;
      } else {
        completionsCount = goal.challengeData!.proofs
            .where((proof) => proof.status == 'approved')
            .length;
      }
    }
    
    final progress = goal.goalFrequency > 0 ? completionsCount / goal.goalFrequency : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.goalName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: goal.isCompleted 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.goalType == GoalType.daily ? 'Daily' : 'Total',
                  style: TextStyle(
                    color: goal.isCompleted ? Colors.green[700] : Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goal.goalCriteria,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$completionsCount / ${goal.goalFrequency}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          
          // Add planning interface for daily goals
          if (goal.goalType == GoalType.daily) ...[
            const SizedBox(height: 16),
            _buildPlanningSection(context, goal),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplatesSection(BuildContext context, GoalTemplateProvider templateProvider) {
    final templates = templateProvider.activeTemplates;
    
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
                  'Goal Templates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/goal-templates'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Templates are blueprints for creating goals. Create goals from templates to start tracking.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            if (templates.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Templates Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create templates to make goal creation easier.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/goal-templates'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Template'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                '${templates.length} template${templates.length == 1 ? '' : 's'} available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ...templates.take(3).map((template) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_books,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            template.displayType,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              if (templates.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  'And ${templates.length - 3} more...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
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
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.add,
                    label: 'Create Goal',
                    subtitle: 'From templates',
                    onTap: () => context.go('/'),  // Go to dashboard
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.library_books,
                    label: 'Templates',
                    subtitle: 'Manage blueprints',
                    onTap: () => context.go('/goal-templates'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningSection(BuildContext context, Goal goal) {
    final plannedDays = goal.challengeData?.plannedDays ?? <int>{};
    final maxPlanned = goal.goalFrequency;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Plan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${plannedDays.length}/$maxPlanned planned',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap days to plan when you\'ll complete this goal',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        
        // Day selector row
        Row(
          children: [
            for (int day = 1; day <= 7; day++) ...[
              Expanded(
                child: _buildDaySelector(context, goal, day, plannedDays, maxPlanned),
              ),
              if (day < 7) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDaySelector(BuildContext context, Goal goal, int dayOfWeek, Set<int> plannedDays, int maxPlanned) {
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dayName = dayNames[dayOfWeek - 1];
    final isPlanned = plannedDays.contains(dayOfWeek);
    
    // Get current status for this day
    final now = DateTime.now();
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dateForDay = mondayOfWeek.add(Duration(days: dayOfWeek - 1));
    final dateString = dateForDay.toIso8601String().split('T')[0];
    final completionStatus = goal.challengeData?.getCompletionStatus(dateString) ?? 'not_attempted';
    
    // Check if there's an actual proof for this day
    final hasProof = goal.challengeData?.dailyProofs.containsKey(dateString) ?? false;
    
    // Determine if user can interact with this day
    bool canToggle = true;
    if (completionStatus == 'completed') {
      canToggle = false; // Can't change completed days
    } else if (completionStatus == 'pending' || completionStatus == 'denied') {
      canToggle = true; // Can change, but will show warning
    } else {
      canToggle = isPlanned || plannedDays.length < maxPlanned; // Normal planning rules
    }
    
    // Determine color based on status and planning (prioritize actual status over planning)
    Color backgroundColor;
    Color textColor;
    
    if (completionStatus == 'completed') {
      backgroundColor = Colors.green;
      textColor = Colors.white;
    } else if (completionStatus == 'pending') {
      backgroundColor = Colors.yellow[700]!;
      textColor = Colors.black;
    } else if (completionStatus == 'denied') {
      backgroundColor = Colors.red;
      textColor = Colors.white;
    } else if (isPlanned) {
      backgroundColor = Colors.blue;
      textColor = Colors.white;
    } else {
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    
    return GestureDetector(
      onTap: canToggle ? () => _handleDayTap(context, goal, dayOfWeek, plannedDays, completionStatus, hasProof, dateString) : null,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isPlanned && completionStatus == 'not_attempted' 
              ? Border.all(color: Colors.blue[300]!, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (completionStatus != 'not_attempted') ...[
              const SizedBox(height: 2),
              Icon(
                completionStatus == 'completed' ? Icons.check 
                    : completionStatus == 'pending' ? Icons.hourglass_empty
                    : Icons.close,
                size: 12,
                color: textColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleDayTap(BuildContext context, Goal goal, int dayOfWeek, Set<int> currentPlanned, String completionStatus, bool hasProof, String dateString) async {
    final provider = Provider.of<SimpleGoalsProvider>(context, listen: false);
    
    // If there's a pending or denied proof, show warning dialog
    if (completionStatus == 'pending' || completionStatus == 'denied') {
      final shouldProceed = await _showProofWarningDialog(context, completionStatus, dateString);
      if (!shouldProceed) return;
      
      // User wants to remove proof and mark as planned - need to implement proof removal
      // For now, just show a message that this functionality is coming
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proof removal coming soon. Day has ${completionStatus} proof.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Normal planning toggle
    final isPlanned = currentPlanned.contains(dayOfWeek);
    Set<int> newPlanned = Set<int>.from(currentPlanned);
    
    if (isPlanned) {
      newPlanned.remove(dayOfWeek);
    } else {
      if (newPlanned.length < goal.goalFrequency) {
        newPlanned.add(dayOfWeek);
      } else {
        // Already at max capacity
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only plan ${goal.goalFrequency} days per week for this goal.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }
    
    final success = await provider.updatePlannedDays(goal.id, newPlanned);
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update planned days'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showProofWarningDialog(BuildContext context, String status, String dateString) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Proof Already Exists'),
          content: Text(
            'You already have a ${status} proof for $dateString. '
            'Do you want to delete the proof and mark this day as planned instead?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Proof'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
}