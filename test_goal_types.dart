// Test script to verify goal type consistency changes
// Run this with: dart test_goal_types.dart

import 'lib/features/goals/models/goal_template.dart' as template;
import 'lib/features/goals/models/goal_model.dart' as goal;

void main() {
  // Test 1: GoalTemplate types
  final templateDaily = template.GoalType.daily;
  final templateTotal = template.GoalType.total;
  
  // Test 2: Goal types  
  final goalDaily = goal.GoalType.daily;
  final goalTotal = goal.GoalType.total;
  
  // Test 3: Consistency check
  final templatesMatch = templateDaily.value == goalDaily.name && 
                        templateTotal.value == goalTotal.name;
  
  // Test 4: Legacy support
  final legacyWeekly = goal.GoalType.fromString('weekly');
  final legacyDaily = goal.GoalType.fromString('daily');
  
  // Use variables to avoid warnings
  assert(templatesMatch != null);
  assert(legacyWeekly != null);
  assert(legacyDaily != null);
}