import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/goals/providers/simple_goals_provider.dart';
import '../../../features/goals/models/goal_model.dart';

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
        print('DEBUG: SIMPLE PROGRESS: Building for goal $goalId');
        
        // Find the goal from provider
        Goal? goal;
        try {
          goal = provider.goals.firstWhere((g) => g.id == goalId);
        } catch (e) {
          goal = null;
        }
        
        if (goal == null) {
          print('DEBUG: SIMPLE PROGRESS: Goal not found');
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
        
        print('DEBUG: SIMPLE PROGRESS: Found goal: ${goal.goalName}');
        print('DEBUG: SIMPLE PROGRESS: Challenge data exists: ${goal.challengeData != null}');
        
        if (goal.challengeData != null) {
          final completions = goal.challengeData!.completions;
          print('DEBUG: SIMPLE PROGRESS: Completions: $completions');
          
          // Generate days of the week (Mon-Sun)
          final now = DateTime.now();
          final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final daysOfWeek = List.generate(7, (index) {
            final date = mondayOfWeek.add(Duration(days: index));
            return date.toIso8601String().split('T')[0];
          });
          
          print('DEBUG: SIMPLE PROGRESS: Days of week: $daysOfWeek');
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Days labels
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
              // Progress bars for each day
              Container(
                height: 8,
                child: Row(
                  children: daysOfWeek.map((dateString) {
                    final status = completions[dateString] ?? 'default';
                    Color dayColor;
                    
                    switch (status) {
                      case 'pending':
                        dayColor = Colors.yellow;
                        break;
                      case 'completed':
                        dayColor = Colors.green;
                        break;
                      case 'denied':
                        dayColor = Colors.red;
                        break;
                      default:
                        dayColor = Colors.grey[300]!;
                    }
                    
                    print('DEBUG: SIMPLE PROGRESS: Date $dateString has status: $status (color: $dayColor)');
                    
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
              ),
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
}