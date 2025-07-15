import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_template.dart';
import '../models/goal_instance.dart';

/// Service for managing goal instances within challenges
class GoalInstanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Convert templates to goal instances for a challenge
  /// This is used when setting up a new challenge
  /// @param templateOwnerId - The user who owns the templates
  /// @param instanceOwnerId - The user who will own the instances
  Future<List<GoalInstance>> createInstancesFromTemplates({
    required List<String> templateIds,
    required String partyId,
    required String challengeId,
    required String templateOwnerId,
    required String instanceOwnerId,
    Map<String, int>? customFrequencies, // templateId -> custom frequency
  }) async {
    try {
      // Load templates from Firebase directly
      final instances = <GoalInstance>[];
      
      for (final templateId in templateIds) {
        // Fetch template from Firebase
        final templateDoc = await _firestore
            .collection('users')
            .doc(templateOwnerId)
            .collection('goalTemplates')
            .doc(templateId)
            .get();
            
        if (templateDoc.exists) {
          final template = GoalTemplate.fromFirestore(templateDoc);
          
          final customFrequency = customFrequencies?[templateId];
          
          final instance = GoalInstance.fromTemplate(
            template: template,
            partyId: partyId,
            challengeId: challengeId,
            ownerId: instanceOwnerId,
            customFrequency: customFrequency,
          );
          
          instances.add(instance);
        }
      }
      
      return instances;
    } catch (e) {
      print('Error creating goal instances from templates: $e');
      return [];
    }
  }

  /// Save goal instances to a challenge using subcollections
  Future<bool> saveInstancesToChallenge({
    required String partyId,
    required String challengeType, // 'activeChallenge' or 'pendingChallenge'
    required String userId,
    required List<GoalInstance> instances,
  }) async {
    try {
      print('DEBUG SAVE: Saving ${instances.length} instances for user $userId to $challengeType');
      
      // Get the challenge document
      final challengeDoc = await _firestore.collection('parties').doc(partyId).get();
      if (!challengeDoc.exists) {
        print('DEBUG SAVE: Party document does not exist');
        return false;
      }
      
      final challengeData = challengeDoc.data() as Map<String, dynamic>;
      final challenge = challengeData[challengeType] as Map<String, dynamic>?;
      if (challenge == null) {
        print('DEBUG SAVE: No $challengeType found in party data');
        return false;
      }
      
      final challengeId = challenge['id'] as String;
      
      // Use subcollection: challenges/{challengeId}/memberGoals/{userId}
      final memberGoalsRef = _firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('memberGoals')
          .doc(userId);
      
      // Convert instances to maps
      final instanceMaps = instances.map((instance) => instance.toMap()).toList();
      
      print('DEBUG SAVE: Saving to subcollection challenges/$challengeId/memberGoals/$userId');
      
      // Save all instances as an array in the user's document
      await memberGoalsRef.set({
        'goals': instanceMaps,
        'userId': userId,
        'challengeId': challengeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('DEBUG SAVE: Successfully saved to Firebase subcollection');
      
      return true;
    } catch (e) {
      print('Error saving goal instances to challenge: $e');
      return false;
    }
  }

  /// Load goal instances from a challenge using subcollections
  Future<List<GoalInstance>> loadInstancesFromChallenge({
    required String partyId,
    required String challengeType, // 'activeChallenge' or 'pendingChallenge'
    required String userId,
  }) async {
    try {
      print('DEBUG LOAD: Loading instances for party: $partyId, type: $challengeType, user: $userId');
      
      // Get the challenge document to find challengeId
      final partyDoc = await _firestore.collection('parties').doc(partyId).get();
      if (!partyDoc.exists) {
        print('DEBUG LOAD: Party document does not exist');
        return [];
      }
      
      final data = partyDoc.data() as Map<String, dynamic>;
      final challenge = data[challengeType] as Map<String, dynamic>?;
      if (challenge == null) {
        print('DEBUG LOAD: No $challengeType found in party data');
        return [];
      }
      
      final challengeId = challenge['id'] as String;
      
      print('DEBUG LOAD: Loading from subcollection challenges/$challengeId/memberGoals/$userId');
      
      // Load from subcollection: challenges/{challengeId}/memberGoals/{userId}
      final memberGoalsDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('memberGoals')
          .doc(userId)
          .get();
      
      if (!memberGoalsDoc.exists) {
        print('DEBUG LOAD: No goals found for user $userId in subcollection');
        return [];
      }
      
      final memberGoalsData = memberGoalsDoc.data() as Map<String, dynamic>;
      final userGoals = memberGoalsData['goals'] as List?;
      
      if (userGoals == null) {
        print('DEBUG LOAD: No goals array found in user document');
        return [];
      }
      
      print('DEBUG LOAD: Found ${userGoals.length} goals for user');
      
      final instances = <GoalInstance>[];
      for (final goalData in userGoals) {
        try {
          final instance = GoalInstance.fromMap(Map<String, dynamic>.from(goalData));
          instances.add(instance);
        } catch (e) {
          print('Error parsing goal instance: $e');
        }
      }
      
      return instances;
    } catch (e) {
      print('Error loading goal instances from challenge: $e');
      return [];
    }
  }

  /// Update a goal instance (e.g., after proof submission)
  Future<bool> updateInstance({
    required String partyId,
    required String challengeType,
    required GoalInstance instance,
  }) async {
    try {
      // Load all instances for the user
      final instances = await loadInstancesFromChallenge(
        partyId: partyId,
        challengeType: challengeType,
        userId: instance.ownerId,
      );
      
      // Find and update the specific instance
      final index = instances.indexWhere((inst) => inst.id == instance.id);
      if (index == -1) return false;
      
      instances[index] = instance;
      
      // Save back to Firestore
      return await saveInstancesToChallenge(
        partyId: partyId,
        challengeType: challengeType,
        userId: instance.ownerId,
        instances: instances,
      );
    } catch (e) {
      print('Error updating goal instance: $e');
      return false;
    }
  }

  /// Submit proof for a goal instance
  Future<bool> submitProof({
    required String partyId,
    required String challengeType,
    required String instanceId,
    required String proofText,
    String? imageUrl,
    DateTime? submissionDate,
  }) async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    try {
      // Load instances
      final instances = await loadInstancesFromChallenge(
        partyId: partyId,
        challengeType: challengeType,
        userId: userId,
      );
      
      // Find the specific instance
      final index = instances.indexWhere((inst) => inst.id == instanceId);
      if (index == -1) return false;
      
      // Add proof to the instance
      final updatedInstance = instances[index].addProof(
        proofText,
        imageUrl,
        submissionDate ?? DateTime.now(),
      );
      
      // Update and save
      return await updateInstance(
        partyId: partyId,
        challengeType: challengeType,
        instance: updatedInstance,
      );
    } catch (e) {
      print('Error submitting proof: $e');
      return false;
    }
  }

  /// Approve proof for a goal instance
  Future<bool> approveProof({
    required String partyId,
    required String challengeType,
    required String instanceId,
    required String userId,
    required String proofId,
    String? date,
  }) async {
    try {
      // Load instances for the user
      final instances = await loadInstancesFromChallenge(
        partyId: partyId,
        challengeType: challengeType,
        userId: userId,
      );
      
      // Find the specific instance
      final index = instances.indexWhere((inst) => inst.id == instanceId);
      if (index == -1) return false;
      
      // Approve the proof
      final updatedInstance = instances[index].approveProof(proofId, date);
      
      // Update and save
      return await updateInstance(
        partyId: partyId,
        challengeType: challengeType,
        instance: updatedInstance,
      );
    } catch (e) {
      print('Error approving proof: $e');
      return false;
    }
  }

  /// Deny proof for a goal instance
  Future<bool> denyProof({
    required String partyId,
    required String challengeType,
    required String instanceId,
    required String userId,
    required String proofId,
    String? date,
  }) async {
    try {
      // Load instances for the user
      final instances = await loadInstancesFromChallenge(
        partyId: partyId,
        challengeType: challengeType,
        userId: userId,
      );
      
      // Find the specific instance
      final index = instances.indexWhere((inst) => inst.id == instanceId);
      if (index == -1) return false;
      
      // Deny the proof
      final updatedInstance = instances[index].denyProof(proofId, date);
      
      // Update and save
      return await updateInstance(
        partyId: partyId,
        challengeType: challengeType,
        instance: updatedInstance,
      );
    } catch (e) {
      print('Error denying proof: $e');
      return false;
    }
  }

  /// Get all member goals for a challenge using collection group query
  Future<List<Map<String, dynamic>>> getAllMemberGoalsForChallenge({
    required String challengeId,
  }) async {
    try {
      // Use collection group query to get all member goals across all users
      final allMemberGoalsSnapshot = await _firestore
          .collectionGroup('memberGoals')
          .where('challengeId', isEqualTo: challengeId)
          .get();
      
      final allMemberGoals = <Map<String, dynamic>>[];
      
      for (final doc in allMemberGoalsSnapshot.docs) {
        final data = doc.data();
        final goals = data['goals'] as List? ?? [];
        
        for (final goalData in goals) {
          try {
            final instance = GoalInstance.fromMap(Map<String, dynamic>.from(goalData));
            allMemberGoals.add({
              'instance': instance,
              'userId': data['userId'],
              'challengeId': challengeId,
            });
          } catch (e) {
            print('Error parsing goal instance: $e');
          }
        }
      }
      
      return allMemberGoals;
    } catch (e) {
      print('Error getting all member goals for challenge: $e');
      return [];
    }
  }

  /// Listen to real-time updates for all member goals in a challenge
  Stream<List<Map<String, dynamic>>> listenToAllMemberGoalsForChallenge({
    required String challengeId,
  }) {
    return _firestore
        .collectionGroup('memberGoals')
        .where('challengeId', isEqualTo: challengeId)
        .snapshots()
        .map((snapshot) {
      final allMemberGoals = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final goals = data['goals'] as List? ?? [];
        
        for (final goalData in goals) {
          try {
            final instance = GoalInstance.fromMap(Map<String, dynamic>.from(goalData));
            allMemberGoals.add({
              'instance': instance,
              'userId': data['userId'],
              'challengeId': challengeId,
            });
          } catch (e) {
            print('Error parsing goal instance in listener: $e');
          }
        }
      }
      
      return allMemberGoals;
    });
  }

  /// Get all pending proofs across all goal instances in a party
  Future<List<Map<String, dynamic>>> getPendingProofsForParty({
    required String partyId,
    required String challengeType,
  }) async {
    try {
      print('DEBUG PENDING PROOFS SERVICE: Getting proofs for party $partyId, challenge type $challengeType');
      
      // Get the challenge document to find challengeId
      final partyDoc = await _firestore.collection('parties').doc(partyId).get();
      if (!partyDoc.exists) {
        print('DEBUG PENDING PROOFS SERVICE: Party document does not exist');
        return [];
      }
      
      final data = partyDoc.data() as Map<String, dynamic>;
      final challenge = data[challengeType] as Map<String, dynamic>?;
      if (challenge == null) {
        print('DEBUG PENDING PROOFS SERVICE: No $challengeType found in party data');
        return [];
      }
      
      final challengeId = challenge['id'] as String;
      print('DEBUG PENDING PROOFS SERVICE: Found challenge ID: $challengeId');
      
      // Query all member goals from the subcollection
      final memberGoalsSnapshot = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('memberGoals')
          .get();
      
      print('DEBUG PENDING PROOFS SERVICE: Found ${memberGoalsSnapshot.docs.length} member documents');
      
      final pendingProofs = <Map<String, dynamic>>[];
      
      // Iterate through all members' goals
      for (final memberDoc in memberGoalsSnapshot.docs) {
        final userId = memberDoc.id;
        final memberData = memberDoc.data();
        final userGoals = memberData['goals'] as List?;
        
        print('DEBUG PENDING PROOFS SERVICE: Processing user $userId with ${userGoals?.length ?? 0} goals');
        
        if (userGoals != null) {
          for (final goalData in userGoals) {
            try {
              final instance = GoalInstance.fromMap(Map<String, dynamic>.from(goalData));
              final instancePendingProofs = instance.pendingProofs;
              
              print('DEBUG PENDING PROOFS SERVICE: Goal ${instance.name} has ${instancePendingProofs.length} pending proofs');
              
              // Get pending proofs for this instance
              for (final proof in instancePendingProofs) {
                print('DEBUG PENDING PROOFS SERVICE: Adding pending proof ${proof.id} for user $userId');
                pendingProofs.add({
                  'proof': proof,
                  'instance': instance,
                  'userId': userId,
                  'partyId': partyId,
                  'challengeType': challengeType,
                });
              }
            } catch (e) {
              print('Error parsing goal instance for pending proofs: $e');
            }
          }
        }
      }
      
      print('DEBUG PENDING PROOFS SERVICE: Returning ${pendingProofs.length} total pending proofs');
      return pendingProofs;
    } catch (e) {
      print('Error getting pending proofs for party: $e');
      return [];
    }
  }
}