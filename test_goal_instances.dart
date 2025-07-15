// Test script to verify goal instance creation and functionality
// Run this with: dart test_goal_instances.dart

import 'lib/features/goals/models/goal_template.dart';
import 'lib/features/goals/models/goal_instance.dart';

void main() {
  print('🧪 Testing Goal Instance System...\n');
  
  // Test 1: Create a goal template
  print('1. Creating goal template:');
  final template = GoalTemplate.create(
    name: 'Test Cardio',
    description: '30 minutes of cardio exercise',
    type: GoalType.daily,
    defaultFrequency: 5,
    category: 'fitness',
  );
  print('   ✅ Template created: ${template.name} (${template.type.value})');
  
  // Test 2: Create goal instance from template
  print('\n2. Creating goal instance from template:');
  final instance = GoalInstance.fromTemplate(
    template: template,
    partyId: 'test-party-123',
    challengeId: 'test-challenge-456',
    ownerId: 'test-user-789',
    customFrequency: 6, // Custom frequency for this party
  );
  print('   ✅ Instance created: ${instance.name}');
  print('   ✅ Template ID: ${instance.templateId}');
  print('   ✅ Party ID: ${instance.partyId}');
  print('   ✅ Custom frequency: ${instance.frequency} (template default: ${template.defaultFrequency})');
  
  // Test 3: Test proof submission
  print('\n3. Testing proof submission:');
  final instanceWithProof = instance.addProof(
    'Ran 5K today!',
    null,
    DateTime.now(),
  );
  print('   ✅ Proof added');
  print('   ✅ Pending proofs: ${instanceWithProof.pendingProofs.length}');
  print('   ✅ Completion status today: ${instanceWithProof.getCompletionStatus(DateTime.now().toIso8601String().split('T')[0])}');
  
  // Test 4: Test proof approval
  print('\n4. Testing proof approval:');
  final today = DateTime.now().toIso8601String().split('T')[0];
  final instanceWithApproval = instanceWithProof.approveProof('dummy-proof-id', today);
  print('   ✅ Proof approved');
  print('   ✅ Total completions: ${instanceWithApproval.challengeData.totalCompletions}');
  print('   ✅ Is completed: ${instanceWithApproval.isCompleted}');
  print('   ✅ Progress: ${(instanceWithApproval.completionProgress * 100).toStringAsFixed(1)}%');
  
  // Test 5: Test serialization
  print('\n5. Testing serialization:');
  final map = instanceWithApproval.toMap();
  final recreated = GoalInstance.fromMap(map);
  final serializationWorks = recreated.id == instanceWithApproval.id && 
                            recreated.name == instanceWithApproval.name &&
                            recreated.challengeData.totalCompletions == instanceWithApproval.challengeData.totalCompletions;
  print('   ${serializationWorks ? "✅" : "❌"} Serialization works: $serializationWorks');
  
  print('\n🎉 Goal instance test ${serializationWorks ? "PASSED" : "FAILED"}!');
}