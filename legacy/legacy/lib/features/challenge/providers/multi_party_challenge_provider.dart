import 'package:flutter/material.dart';
import '../models/multi_party_challenge.dart';
import '../repositories/multi_party_challenge_repository.dart';
import '../../party/models/challenge_state.dart';

/// Provider for managing multi-party challenges
class MultiPartyChallengeProvider with ChangeNotifier {
  final MultiPartyChallengeRepository _repository = MultiPartyChallengeRepository();

  final Map<String, MultiPartyChallenge> _challenges = {};
  final Map<String, List<String>> _partyChallenges = {}; // partyId -> challengeIds
  List<MultiPartyChallenge> _pendingInvitations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, MultiPartyChallenge> get challenges => _challenges;
  List<MultiPartyChallenge> get pendingInvitations => _pendingInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get all challenges for a specific party
  List<MultiPartyChallenge> getPartyChallenges(String partyId) {
    final challengeIds = _partyChallenges[partyId] ?? [];
    return challengeIds
        .map((id) => _challenges[id])
        .where((challenge) => challenge != null)
        .cast<MultiPartyChallenge>()
        .toList();
  }

  /// Get a specific challenge by ID
  MultiPartyChallenge? getChallenge(String challengeId) {
    return _challenges[challengeId];
  }

  /// Get active challenge for a party
  MultiPartyChallenge? getActiveChallenge(String partyId) {
    final partyChallenges = getPartyChallenges(partyId);
    return partyChallenges
        .where((challenge) => challenge.isActive)
        .cast<MultiPartyChallenge?>()
        .firstOrNull;
  }

  /// Check if a party has an active challenge
  bool hasActiveChallenge(String partyId) {
    return getActiveChallenge(partyId) != null;
  }

  /// Check if a party has a pending challenge
  bool hasPendingChallenge(String partyId) {
    final partyChallenges = getPartyChallenges(partyId);
    return partyChallenges.any((challenge) => challenge.isSetup);
  }

  /// Initialize and load challenges for a party
  Future<void> loadPartyChallenges(String partyId) async {
    _setLoading(true);
    try {
      final challenges = await _repository.getPartyChallenges(partyId);
      
      // Update local cache
      for (final challenge in challenges) {
        _challenges[challenge.id] = challenge;
        _partyChallenges[partyId] = _partyChallenges[partyId] ?? [];
        if (!_partyChallenges[partyId]!.contains(challenge.id)) {
          _partyChallenges[partyId]!.add(challenge.id);
        }
      }
      
      _clearError();
    } catch (e) {
      _setError('Error loading party challenges: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load pending invitations for a party
  Future<void> loadPendingInvitations(String partyId) async {
    try {
      _pendingInvitations = await _repository.getPendingInvitations(partyId);
      notifyListeners();
    } catch (e) {
      _setError('Error loading pending invitations: $e');
    }
  }

  /// Create a new multi-party challenge
  Future<String?> createMultiPartyChallenge({
    required String creatorPartyId,
    required DateTime startDate,
    required DateTime endDate,
    List<String> invitedParties = const [],
    bool allowCrossPartyApproval = false,
  }) async {
    _setLoading(true);
    try {
      final challengeId = await _repository.createMultiPartyChallenge(
        creatorPartyId: creatorPartyId,
        startDate: startDate,
        endDate: endDate,
        invitedParties: invitedParties,
        allowCrossPartyApproval: allowCrossPartyApproval,
      );

      if (challengeId != null) {
        // Reload challenges for the creator party
        await loadPartyChallenges(creatorPartyId);
      }

      _clearError();
      return challengeId;
    } catch (e) {
      _setError('Error creating multi-party challenge: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Invite a party to join an existing challenge
  Future<bool> invitePartyToChallenge(String challengeId, String partyId) async {
    try {
      final success = await _repository.invitePartyToChallenge(challengeId, partyId);
      
      if (success) {
        // Refresh the challenge
        await _refreshChallenge(challengeId);
      }
      
      return success;
    } catch (e) {
      _setError('Error inviting party to challenge: $e');
      return false;
    }
  }

  /// Accept a challenge invitation
  Future<bool> acceptChallengeInvitation(String challengeId, String partyId) async {
    try {
      final success = await _repository.acceptChallengeInvitation(challengeId, partyId);
      
      if (success) {
        // Refresh the challenge and remove from pending invitations
        await _refreshChallenge(challengeId);
        await loadPendingInvitations(partyId);
        await loadPartyChallenges(partyId);
      }
      
      return success;
    } catch (e) {
      _setError('Error accepting challenge invitation: $e');
      return false;
    }
  }

  /// Decline a challenge invitation
  Future<bool> declineChallengeInvitation(String challengeId, String partyId) async {
    try {
      final success = await _repository.declineChallengeInvitation(challengeId, partyId);
      
      if (success) {
        // Refresh the challenge and remove from pending invitations
        await _refreshChallenge(challengeId);
        await loadPendingInvitations(partyId);
      }
      
      return success;
    } catch (e) {
      _setError('Error declining challenge invitation: $e');
      return false;
    }
  }

  /// Remove a party from a challenge
  Future<bool> removePartyFromChallenge(String challengeId, String partyId) async {
    try {
      final success = await _repository.removePartyFromChallenge(challengeId, partyId);
      
      if (success) {
        // Remove from local cache
        _partyChallenges[partyId]?.remove(challengeId);
        
        // Refresh the challenge
        await _refreshChallenge(challengeId);
      }
      
      return success;
    } catch (e) {
      _setError('Error removing party from challenge: $e');
      return false;
    }
  }

  /// Start a multi-party challenge
  Future<bool> startChallenge(String challengeId) async {
    try {
      final success = await _repository.startChallenge(challengeId);
      
      if (success) {
        await _refreshChallenge(challengeId);
      }
      
      return success;
    } catch (e) {
      _setError('Error starting challenge: $e');
      return false;
    }
  }

  /// Complete a multi-party challenge
  Future<bool> completeChallenge(String challengeId) async {
    try {
      final success = await _repository.completeChallenge(challengeId);
      
      if (success) {
        await _refreshChallenge(challengeId);
      }
      
      return success;
    } catch (e) {
      _setError('Error completing challenge: $e');
      return false;
    }
  }

  /// Delete a challenge
  Future<bool> deleteChallenge(String challengeId) async {
    try {
      final success = await _repository.deleteChallenge(challengeId);
      
      if (success) {
        // Remove from local cache
        _challenges.remove(challengeId);
        _partyChallenges.forEach((partyId, challengeIds) {
          challengeIds.remove(challengeId);
        });
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('Error deleting challenge: $e');
      return false;
    }
  }

  /// Convert a single-party challenge to multi-party
  Future<String?> convertToMultiParty(String partyId, ChallengeState singlePartyChallenge) async {
    try {
      final challengeId = await _repository.convertToMultiParty(partyId, singlePartyChallenge);
      
      if (challengeId != null) {
        await loadPartyChallenges(partyId);
      }
      
      return challengeId;
    } catch (e) {
      _setError('Error converting to multi-party challenge: $e');
      return null;
    }
  }

  /// Listen to real-time updates for a specific challenge
  void listenToChallenge(String challengeId) {
    _repository.streamChallenge(challengeId).listen(
      (challenge) {
        if (challenge != null) {
          _challenges[challenge.id] = challenge;
          notifyListeners();
        }
      },
      onError: (error) {
        _setError('Error streaming challenge: $error');
      },
    );
  }

  /// Listen to real-time updates for party challenges
  void listenToPartyChallenges(String partyId) {
    _repository.streamPartyChallenges(partyId).listen(
      (challenges) {
        // Update local cache
        final challengeIds = <String>[];
        for (final challenge in challenges) {
          _challenges[challenge.id] = challenge;
          challengeIds.add(challenge.id);
        }
        _partyChallenges[partyId] = challengeIds;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error streaming party challenges: $error');
      },
    );
  }

  /// Listen to real-time updates for pending invitations
  void listenToPendingInvitations(String partyId) {
    _repository.streamPendingInvitations(partyId).listen(
      (invitations) {
        _pendingInvitations = invitations;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error streaming pending invitations: $error');
      },
    );
  }

  /// Check if user can create challenges (is party leader)
  bool canCreateChallenge(String partyId, String userId) {
    // This would need to check party leadership
    // For now, returning true - would need party provider integration
    return true;
  }

  /// Get challenge statistics for a party
  Map<String, int> getChallengeStats(String partyId) {
    final challenges = getPartyChallenges(partyId);
    return {
      'total': challenges.length,
      'active': challenges.where((c) => c.isActive).length,
      'completed': challenges.where((c) => c.isCompleted).length,
      'setup': challenges.where((c) => c.isSetup).length,
    };
  }

  // Private helper methods

  Future<void> _refreshChallenge(String challengeId) async {
    try {
      final challenge = await _repository.getChallenge(challengeId);
      if (challenge != null) {
        _challenges[challenge.id] = challenge;
        notifyListeners();
      }
    } catch (e) {
      // Handle silently
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _challenges.clear();
    _partyChallenges.clear();
    _pendingInvitations.clear();
    super.dispose();
  }
}