import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/goals/providers/simple_goals_provider.dart';
import '../../../features/goals/models/goal_model.dart';
import '../../../features/goals/models/proof_model.dart';

class SimpleProgressTracker extends StatelessWidget {
  final String goalId;
  
  const SimpleProgressTracker({
    required this.goalId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleGoalsProvider>(
      builder: (context, provider, child) {
        
        // Find the goal from provider
        Goal? goal;
        try {
          goal = provider.goals.firstWhere((g) => g.id == goalId);
        } catch (e) {
          goal = null;
        }
        
        if (goal == null) {
          return Container(
            height: 40,
            color: Colors.red,
            child: Center(
              child: Text(
                'GOAL NOT FOUND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
        
        
        if (goal.challengeData != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal name and progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    goal.goalName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${goal.completionsCount}/${goal.goalFrequency}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Show different progress based on goal type
              if (goal.goalType == GoalType.daily) ...[
                // Daily goals - show days of the week
                Row(
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                _buildDailyProgressBar(goal),
              ] else ...[
                // Total goals - show continuous progress bar
                _buildTotalProgressBar(goal),
              ],
            ],
          );
        }
        
        return Container(
          height: 40,
          color: Colors.grey[300],
          child: Center(
            child: Text(
              'NO PROGRESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyProgressBar(Goal goal) {
    final completions = goal.challengeData!.completions;
    final plannedDays = goal.challengeData!.plannedDays;
    
    // Generate days of the week (Mon-Sun)
    final now = DateTime.now();
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final daysOfWeek = List.generate(7, (index) {
      final date = mondayOfWeek.add(Duration(days: index));
      return date.toIso8601String().split('T')[0];
    });
    
    return Container(
      height: 8,
      child: Row(
        children: daysOfWeek.asMap().entries.map((entry) {
          final index = entry.key;
          final dateString = entry.value;
          final dayOfWeek = index + 1; // Convert 0-based index to 1-based day (Mon=1, Sun=7)
          final status = completions[dateString] ?? 'default';
          final isPlanned = plannedDays.contains(dayOfWeek);
          
          Color dayColor;
          
          // Prioritize actual completion status over planning
          switch (status) {
            case 'pending':
              dayColor = Colors.yellow[700]!;
              break;
            case 'completed':
              dayColor = Colors.green;
              break;
            case 'denied':
              dayColor = Colors.red;
              break;
            default:
              // If no actual status, check if it's planned
              dayColor = isPlanned ? Colors.blue : Colors.grey[300]!;
          }
          
          return Expanded(
            child: Container(
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: dayColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalProgressBar(Goal goal) {
    final challengeData = goal.challengeData;
    if (challengeData == null) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final totalProofs = challengeData.proofs;
    final frequency = goal.goalFrequency;
    
    if (frequency == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // Count proofs by status
    int approvedCount = 0;
    int pendingCount = 0;
    int deniedCount = 0;
    
    for (final proof in totalProofs) {
      switch (proof.status) {
        case ProofStatus.approved:
          approvedCount++;
          break;
        case ProofStatus.pending:
          pendingCount++;
          break;
        case ProofStatus.denied:
          deniedCount++;
          break;
      }
    }

    // Calculate the number of empty slots
    final totalSubmitted = approvedCount + pendingCount + deniedCount;
    final emptySlots = frequency - totalSubmitted;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Approved sections (green)
          ...List.generate(approvedCount, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
          // Pending sections (yellow)
          ...List.generate(pendingCount, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.yellow[700]!,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
          // Denied sections (red)
          ...List.generate(deniedCount, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
          // Empty sections (grey)
          ...List.generate(emptySlots, (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              decoration: BoxDecoration(
                color: Colors.grey[300]!,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
        ],
      ),
    );
  }
}