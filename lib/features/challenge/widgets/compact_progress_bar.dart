import 'package:flutter/material.dart';
import '../../common/utils/utils.dart';

class CompactProgressBar extends StatelessWidget {
  final String goalName;
  final bool isWeeklyGoal;
  final double progress; // 0.0 to 1.0 for total goals
  final List<String>? segmentStates; // For weekly goals: completion states [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final double? pendingProgress; // For total goals: pending proof progress
  final VoidCallback? onTap;

  const CompactProgressBar({
    super.key,
    required this.goalName,
    required this.isWeeklyGoal,
    this.progress = 0.0,
    this.segmentStates, // List of completion statuses: 'pending', 'completed', 'denied', 'skipped', 'planned'
    this.pendingProgress, // Additional progress for pending items
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal name
            Text(
              goalName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Progress bar
            if (isWeeklyGoal)
              _buildWeeklyProgressBar(context)
            else
              _buildTotalProgressBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressBar(BuildContext context) {
    final states = segmentStates ?? List.filled(7, 'default');
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Column(
      children: [
        // Day labels
        Row(
          children: dayLabels.map((label) {
            return Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        
        // Progress segments
        Container(
          height: 8,
          child: Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < 6 ? 2 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: _getSegmentColor(states[index]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalProgressBar(BuildContext context) {
    final totalProgress = pendingProgress != null 
        ? (progress + pendingProgress!).clamp(0.0, 1.0)
        : progress.clamp(0.0, 1.0);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Progress",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Stacked progress bar (pending + completed)
        Container(
          height: 8,
          child: Stack(
            children: [
              // Background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Total progress (pending + completed) - Yellow
              if (pendingProgress != null && totalProgress > 0)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: totalProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.amber, // Yellow for pending
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              // Completed progress - Green
              if (progress > 0)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green, // Green for completed
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getSegmentColor(String status) {
    return Utils.getStatusColor(status);
  }
}