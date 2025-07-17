import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_instance.dart';
import '../services/goal_instance_service.dart';

/// Provider for managing goal instances within challenges
/// This is the new provider that works with the enhanced goal instance system
class GoalInstanceProvider with ChangeNotifier {
  final GoalInstanceService _service = GoalInstanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GoalInstance> _instances = [];
  bool _isLoading = false;
  String? _error;

  List<GoalInstance> get instances => _instances;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<GoalInstance> get activeInstances => _instances.where((instance) => !instance.isCompleted).toList();
  bool get hasActiveInstances => activeInstances.isNotEmpty;
  String? get currentUserId => _auth.currentUser?.uid;

  GoalInstanceProvider();

  /// Load goal instances for the current user from all their parties
  Future<void> loadInstances() async {
    final userId = currentUserId;
    if (userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // For now, we'll load from a specific party and challenge
      // In the future, this could load from multiple parties/challenges
      
      // This is a simplified version - in practice, you'd want to:
      // 1. Get all parties the user is in
      // 2. Load instances from both active and pending challenges
      // 3. Combine and deduplicate if needed
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error loading goal instances: $e');
      _setLoading(false);
    }
  }

  /// Load instances from a specific party and challenge
  Future<void> loadInstancesFromChallenge({
    required String partyId,
    required String challengeType, // 'activeChallenge' or 'pendingChallenge'
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      final instances = await _service.loadInstancesFromChallenge(
        partyId: partyId,
        challengeType: challengeType,
        userId: userId,
      );

      _instances = instances;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error loading goal instances: $e');
      _setLoading(false);
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
    try {
      _clearError();
      
      final success = await _service.submitProof(
        partyId: partyId,
        challengeType: challengeType,
        instanceId: instanceId,
        proofText: proofText,
        imageUrl: imageUrl,
        submissionDate: submissionDate,
      );

      if (success) {
        // Reload instances to get updated data
        await loadInstancesFromChallenge(
          partyId: partyId,
          challengeType: challengeType,
        );
        return true;
      } else {
        _setError('Failed to submit proof');
        return false;
      }
    } catch (e) {
      _setError('Error submitting proof: $e');
      return false;
    }
  }

  /// Approve a proof (for party members)
  Future<bool> approveProof({
    required String partyId,
    required String challengeType,
    required String instanceId,
    required String userId,
    required String proofId,
    String? date,
  }) async {
    try {
      _clearError();
      
      final success = await _service.approveProof(
        partyId: partyId,
        challengeType: challengeType,
        instanceId: instanceId,
        userId: userId,
        proofId: proofId,
        date: date,
      );

      if (success) {
        // Reload instances to get updated data
        await loadInstancesFromChallenge(
          partyId: partyId,
          challengeType: challengeType,
        );
        return true;
      } else {
        _setError('Failed to approve proof');
        return false;
      }
    } catch (e) {
      _setError('Error approving proof: $e');
      return false;
    }
  }

  /// Deny a proof (for party members)
  Future<bool> denyProof({
    required String partyId,
    required String challengeType,
    required String instanceId,
    required String userId,
    required String proofId,
    String? date,
  }) async {
    try {
      _clearError();
      
      final success = await _service.denyProof(
        partyId: partyId,
        challengeType: challengeType,
        instanceId: instanceId,
        userId: userId,
        proofId: proofId,
        date: date,
      );

      if (success) {
        // Reload instances to get updated data
        await loadInstancesFromChallenge(
          partyId: partyId,
          challengeType: challengeType,
        );
        return true;
      } else {
        _setError('Failed to deny proof');
        return false;
      }
    } catch (e) {
      _setError('Error denying proof: $e');
      return false;
    }
  }

  /// Get pending proofs for all instances in a party
  Future<List<Map<String, dynamic>>> getPendingProofsForParty({
    required String partyId,
    required String challengeType,
  }) async {
    try {
      return await _service.getPendingProofsForParty(
        partyId: partyId,
        challengeType: challengeType,
      );
    } catch (e) {
      _setError('Error getting pending proofs: $e');
      return [];
    }
  }

  /// Get a specific instance by ID
  GoalInstance? getInstanceById(String instanceId) {
    try {
      return _instances.firstWhere((instance) => instance.id == instanceId);
    } catch (e) {
      return null;
    }
  }

  /// Get instances by template ID
  List<GoalInstance> getInstancesByTemplateId(String templateId) {
    return _instances.where((instance) => instance.templateId == templateId).toList();
  }

  /// Get completion status for a specific date and instance
  String? getCompletionStatus(String instanceId, String date) {
    final instance = getInstanceById(instanceId);
    return instance?.getCompletionStatus(date);
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Force refresh instances
  Future<void> refresh({
    required String partyId,
    required String challengeType,
  }) async {
    await loadInstancesFromChallenge(
      partyId: partyId,
      challengeType: challengeType,
    );
  }

  /// Debug methods
  void debugInstances() {
    
    for (var instance in _instances) {
      
      
      
      
      
      }');
      
      
      
    }
  }
}