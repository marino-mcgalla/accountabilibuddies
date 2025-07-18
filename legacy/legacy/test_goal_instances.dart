// Test script to verify goal instance creation and functionality
// Run this with: dart test_goal_instances.dart

import 'lib/features/goals/models/goal_template.dart';
import 'lib/features/goals/models/goal_instance.dart';

void main() {
  
  
  // Test 1: Create a goal template
  final template = GoalTemplate.create(
    name: 'Test Cardio',
    description: '30 minutes of cardio exercise',
    type: GoalType.daily,
    defaultFrequency: 5,
    category: 'fitness',
  );
  
  // Test 2: Create goal instance from template
  final instance = GoalInstance.fromTemplate(
    template: template,
    partyId: 'test-party-123',
    challengeId: 'test-challenge-456',
    ownerId: 'test-user-789',
    customFrequency: 6, // Custom frequency for this party
  );
  
  // Test 3: Test proof submission
  final instanceWithProof = instance.addProof(
    'Ran 5K today!',
    null,
    DateTime.now(),
  );
  
  // Test 4: Test proof approval
  final today = DateTime.now().toIso8601String().split('T')[0];
  final instanceWithApproval = instanceWithProof.approveProof('dummy-proof-id', today);
  
  // Test 5: Test serialization
  final map = instanceWithApproval.toMap();
  final recreated = GoalInstance.fromMap(map);
  final serializationWorks = recreated.id == instanceWithApproval.id && 
                            recreated.name == instanceWithApproval.name &&
                            recreated.challengeData.totalCompletions == instanceWithApproval.challengeData.totalCompletions;
  
  // Use variables to avoid warnings
  assert(serializationWorks);
}