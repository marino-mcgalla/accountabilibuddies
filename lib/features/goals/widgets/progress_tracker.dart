import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import '../../time_machine/providers/time_machine_provider.dart';
import '../../common/utils/utils.dart';

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
    final keyString = '${goal.id}-${(goal.challenge ?? {}).hashCode}';
    final valueKey = ValueKey(keyString);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileScreen = screenWidth < 600;

    if (goal is TotalGoal) {
      return _buildTotalGoalTracker(context, isMobileScreen);
    } else if (goal is WeeklyGoal) {
      return _buildWeeklyGoalTracker(context, valueKey, isMobileScreen);
    }

    return const SizedBox.shrink(); // Fallback
  }

  /// Builds a tracker for total goals
// Update just _buildTotalGoalTracker:

  Widget _buildTotalGoalTracker(BuildContext context, bool isMobileScreen) {
    final totalGoal = goal as TotalGoal;

    // Get completed progress (green)
    final Map<String, dynamic> completions =
        (goal.challenge?['completions'] as Map<String, dynamic>?) ?? {};
    final int completed =
        completions.values.fold(0, (sum, val) => sum + (val as int? ?? 0));

    // Get pending proofs (yellow)
    int pendingCount = 0;
    final proofs = goal.challenge?['proofs'];
    if (proofs is List) {
      pendingCount =
          proofs.where((proof) => proof['status'] == 'pending').length;
    }

    // Calculate progress values
    final double completedProgress = totalGoal.goalFrequency > 0
        ? (completed / totalGoal.goalFrequency).clamp(0.0, 1.0)
        : 0.0;
    final double totalProgress = totalGoal.goalFrequency > 0
        ? ((completed + pendingCount) / totalGoal.goalFrequency).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompact)
          Text(goal.goalName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        // Use a Stack for layered progress indicators
        Stack(
          children: [
            // Bottom layer - pending + completed (yellow)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalProgress,
                backgroundColor: Colors.grey[300],
                color: Colors.amber,
                minHeight: 10,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completedProgress,
                backgroundColor: Colors.transparent,
                color: Colors.green,
                minHeight: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Progress: $completed / ${totalGoal.goalFrequency}'),
      ],
    );
  }

  /// Builds a tracker for weekly goals
  Widget _buildWeeklyGoalTracker(
      BuildContext context, Key key, bool isMobileScreen) {
    final weeklyGoal = goal as WeeklyGoal;
    final timeMachineProvider = Provider.of<TimeMachineProvider>(context);
    final daysOfWeek = Utils.getCurrentWeekDays(timeMachineProvider.now);

    // Count completed days
    final completedDays =
        (weeklyGoal.challenge?['completions'] as Map<String, dynamic>?)
                ?.values
                .where((status) => status == 'completed')
                .length ??
            0;

    return Container(
      key: key,
      margin: EdgeInsets.symmetric(vertical: isMobileScreen ? 8 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCompact)
            Text(
              goal.goalName,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobileScreen ? 16 : 16),
            ),
          const SizedBox(height: 8),
          Row(
            children: daysOfWeek.map((day) {
              final status = ((weeklyGoal.challenge?['completions']
                          as Map<String, dynamic>?) ??
                      {})[day] ??
                  'default';

              // Use shorter labels on mobile
              final dayAbbr = isMobileScreen
                  ? Utils.getShortDayAbbreviation(day)
                  : Utils.getDayAbbreviation(day);

              return Expanded(
                child: GestureDetector(
                  onTap: onDayTap != null
                      ? () => onDayTap!(weeklyGoal.id, day, status)
                      : null,
                  child: Container(
                    height: isMobileScreen ? 40 : 36,
                    margin: const EdgeInsets.symmetric(horizontal: 1.0),
                    decoration: BoxDecoration(
                      color: Utils.getStatusColor(status),
                      borderRadius:
                          BorderRadius.circular(isMobileScreen ? 4 : 4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayAbbr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobileScreen ? 12 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed: $completedDays / ${weeklyGoal.goalFrequency} days',
            style: TextStyle(
              fontSize: isMobileScreen ? 14 : 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
