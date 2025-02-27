import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'time_machine_provider.dart';
import 'utils.dart';

/// A unified progress tracker that handles both weekly and total goals
class ProgressTracker extends StatelessWidget {
  final Goal goal;
  final bool isCompact;
  final Function(String, String, String)? onDayTap;

  const ProgressTracker({
    required this.goal,
    this.isCompact = false,
    this.onDayTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a unique key based on the goal ID and completions
    final keyString = '${goal.id}-${goal.currentWeekCompletions.hashCode}';
    final valueKey = ValueKey(keyString);

    if (goal is TotalGoal) {
      return _buildTotalGoalTracker(context, valueKey);
    } else if (goal is WeeklyGoal) {
      return _buildWeeklyGoalTracker(context, valueKey);
    }

    return const SizedBox.shrink(); // Fallback
  }

  /// Builds a tracker for total goals
  Widget _buildTotalGoalTracker(BuildContext context, Key key) {
    final totalGoal = goal as TotalGoal;

    // Calculate progress
    int approvedCompletions = totalGoal.currentWeekCompletions.values
        .fold(0, (sum, value) => sum + (value as int));
    int pendingCompletions = totalGoal.proofs.length;

    // Calculate progress percentage (capped at 100%)
    double approvedProgress = totalGoal.goalFrequency > 0
        ? (approvedCompletions / totalGoal.goalFrequency).clamp(0.0, 1.0)
        : 0;
    double pendingProgress = totalGoal.goalFrequency > 0
        ? ((approvedCompletions + pendingCompletions) / totalGoal.goalFrequency)
            .clamp(0.0, 1.0)
        : 0;

    return Container(
      key: key,
      margin: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCompact)
            Text(
              goal.goalName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          const SizedBox(height: 4),
          Stack(
            children: [
              // Background progress (includes pending)
              LinearProgressIndicator(
                value: pendingProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
                minHeight: isCompact ? 8 : 12,
              ),
              // Foreground progress (approved only)
              LinearProgressIndicator(
                value: approvedProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: isCompact ? 8 : 12,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Progress: $approvedCompletions / ${totalGoal.goalFrequency}',
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a tracker for weekly goals
  Widget _buildWeeklyGoalTracker(BuildContext context, Key key) {
    final weeklyGoal = goal as WeeklyGoal;
    final timeMachineProvider = Provider.of<TimeMachineProvider>(context);
    final daysOfWeek = Utils.getCurrentWeekDays(timeMachineProvider.now);

    // Count completed days
    final completedDays = weeklyGoal.currentWeekCompletions.values
        .where((status) => status == 'completed')
        .length;

    return Container(
      key: key,
      margin: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCompact)
            Text(
              goal.goalName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          const SizedBox(height: 4),
          Row(
            children: daysOfWeek.map((day) {
              final status =
                  weeklyGoal.currentWeekCompletions[day] ?? 'default';
              final dayAbbr = isCompact
                  ? Utils.getShortDayAbbreviation(day)
                  : Utils.getDayAbbreviation(day);

              return Expanded(
                child: GestureDetector(
                  onTap: onDayTap != null
                      ? () => onDayTap!(weeklyGoal.id, day, status)
                      : null,
                  child: Container(
                    height: isCompact ? 24 : 36,
                    margin: const EdgeInsets.symmetric(horizontal: 1.0),
                    decoration: BoxDecoration(
                      color: Utils.getStatusColor(status),
                      borderRadius: BorderRadius.circular(isCompact ? 2 : 4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayAbbr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed: $completedDays / ${weeklyGoal.goalFrequency} days',
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
