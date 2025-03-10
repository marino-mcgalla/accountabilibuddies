import 'package:flutter/material.dart';
import '../../goals/models/goal_model.dart';
import 'package:provider/provider.dart';
import '../../time_machine/providers/time_machine_provider.dart';

class CompactProgressTracker extends StatelessWidget {
  final Goal goal;

  const CompactProgressTracker({
    required this.goal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a unique key based on challenge data
    final keyString = '${goal.id}-${(goal.challenge ?? {}).hashCode}';
    final valueKey = ValueKey(keyString);

    return Container(
      key: valueKey,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.goalName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Different progress displays based on goal type
          if (goal.goalType == 'total')
            _buildTotalGoalProgress(context)
          else
            _buildWeeklyGoalProgress(context),
        ],
      ),
    );
  }

  Widget _buildTotalGoalProgress(BuildContext context) {
    // Get completed progress (green)
    final completions =
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
    final double completedProgress = goal.goalFrequency > 0
        ? (completed / goal.goalFrequency).clamp(0.0, 1.0)
        : 0.0;
    final double totalProgress = goal.goalFrequency > 0
        ? ((completed + pendingCount) / goal.goalFrequency).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            LinearProgressIndicator(
              value: totalProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            LinearProgressIndicator(
              value: completedProgress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
        Text(
          'Progress: $completed / ${goal.goalFrequency}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWeeklyGoalProgress(BuildContext context) {
    final timeMachineProvider =
        Provider.of<TimeMachineProvider>(context, listen: false);
    final daysOfWeek = List.generate(7, (index) {
      final date = timeMachineProvider.now.subtract(
          Duration(days: timeMachineProvider.now.weekday - 1 - index));
      return date.toIso8601String().split('T').first;
    });

    // Get completed count
    final completions =
        (goal.challenge?['completions'] as Map<String, dynamic>?) ?? {};
    final completedCount =
        completions.values.where((status) => status == 'completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: daysOfWeek.map((day) {
            final status = (completions[day] ?? 'default');

            // Get day abbreviation
            final dayOfWeek = DateTime.parse(day).weekday;
            final dayAbbr = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][dayOfWeek];

            return Expanded(
              child: Container(
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayAbbr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        Text(
          'Target: ${goal.goalFrequency} days/week',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // Simple status color helper
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'skipped':
        return Colors.red;
      case 'planned':
        return Colors.blue;
      default:
        return Colors.grey[300]!;
    }
  }
}
