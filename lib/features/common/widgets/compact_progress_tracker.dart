import 'package:auth_test/features/common/utils/utils.dart';
import 'package:flutter/material.dart';
import '../../goals/models/goal_model.dart';
import '../../goals/models/challenge_data.dart';
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
    final keyString = '${goal.id}-${(goal.challengeData ?? const ChallengeData()).hashCode}';
    final valueKey = ValueKey(keyString);

    return Container(
      key: valueKey,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${goal.goalName} (x${goal.goalFrequency})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (goal.goalType == GoalType.total)
            _buildTotalGoalProgress(context)
          else
            _buildWeeklyGoalProgress(context),
        ],
      ),
    );
  }

  Widget _buildTotalGoalProgress(BuildContext context) {
    final challengeData = goal.challengeData ?? const ChallengeData();
    final int completed = challengeData.proofs.where((proof) => proof.status.name == 'approved').length;
    final int pendingCount = challengeData.proofs.where((proof) => proof.status.name == 'pending').length;

    final double completedProgress = goal.goalFrequency > 0
        ? (completed / goal.goalFrequency).clamp(0.0, 1.0)
        : 0.0;
    final double totalProgress = goal.goalFrequency > 0
        ? ((completed + pendingCount) / goal.goalFrequency).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          child: Stack(
            children: [
              LinearProgressIndicator(
                value: totalProgress,
                backgroundColor: Colors.grey[300],
                minHeight: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              LinearProgressIndicator(
                value: completedProgress,
                backgroundColor: Colors.transparent,
                minHeight: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
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
    
    // Calculate days of week (Monday to Sunday)
    final now = timeMachineProvider.now;
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final daysOfWeek = List.generate(7, (index) {
      final date = mondayOfWeek.add(Duration(days: index));
      return date.toIso8601String().split('T').first;
    });
    
    // Also calculate today's date for comparison
    final todayDateString = now.toIso8601String().split('T').first;

    // Get completed count
    final challengeData = goal.challengeData ?? const ChallengeData();
    final completions = challengeData.completions;
    final completedCount = completions.values.where((status) => status == 'completed').length;
    
    // Debug logging
    
    }');
    
    }');
    
    }');
    

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          child: Row(
            children: daysOfWeek.map((day) {
              final status = (completions[day] ?? 'default');
              })');
              return Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Utils.getStatusColor(status),
                    // Add tiny separators between days
                    border: Border(
                      right: BorderSide(
                        color: Colors.white,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // const SizedBox(height: 4),
        // Text(
        //   'Progress: $completedCount / ${goal.goalFrequency} days',
        //   style: const TextStyle(fontSize: 12),
        // ),
      ],
    );
  }
}
