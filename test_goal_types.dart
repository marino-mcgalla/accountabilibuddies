// Test script to verify goal type consistency changes
// Run this with: dart test_goal_types.dart

import 'lib/features/goals/models/goal_template.dart' as template;
import 'lib/features/goals/models/goal_model.dart' as goal;

void main() {
  print('🧪 Testing Goal Type Consistency...\n');
  
  // Test 1: GoalTemplate types
  print('1. Testing GoalTemplate types:');
  final templateDaily = template.GoalType.daily;
  final templateTotal = template.GoalType.total;
  print('   ✅ GoalTemplate.daily: ${templateDaily.value}');
  print('   ✅ GoalTemplate.total: ${templateTotal.value}');
  
  // Test 2: Goal types  
  print('\n2. Testing Goal types:');
  final goalDaily = goal.GoalType.daily;
  final goalTotal = goal.GoalType.total;
  print('   ✅ Goal.daily: ${goalDaily.name}');
  print('   ✅ Goal.total: ${goalTotal.name}');
  
  // Test 3: Consistency check
  print('\n3. Consistency check:');
  final templatesMatch = templateDaily.value == goalDaily.name && 
                        templateTotal.value == goalTotal.name;
  print('   ${templatesMatch ? "✅" : "❌"} Types match: $templatesMatch');
  
  // Test 4: Legacy support
  print('\n4. Testing legacy support:');
  final legacyWeekly = goal.GoalType.fromString('weekly');
  final legacyDaily = goal.GoalType.fromString('daily');
  print('   ✅ Legacy "weekly" → ${legacyWeekly.name}');
  print('   ✅ Current "daily" → ${legacyDaily.name}');
  print('   ${legacyWeekly == legacyDaily ? "✅" : "❌"} Legacy mapping works');
  
  print('\n🎉 Goal type consistency test ${templatesMatch && legacyWeekly == legacyDaily ? "PASSED" : "FAILED"}!');
}