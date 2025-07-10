import 'package:flutter/material.dart';
import '../repositories/simple_party_repository.dart';
import '../models/challenge_state.dart';
import '../actions/challenge_actions.dart';

class SimplePartyProvider with ChangeNotifier {
  final SimplePartyRepository _repository = SimplePartyRepository();
  final ChallengeActions _challengeActions = ChallengeActions();

  List<Map<String, dynamic>> _parties = [];
  List<Map<String, dynamic>> _invitations = [];
  final Map<String, Map<String, dynamic>> _userCache = {};
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get parties => _parties;
  List<Map<String, dynamic>> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasParties => _parties.isNotEmpty;
  bool get hasInvitations => _invitations.isNotEmpty;
  String? get currentUserId => _repository.currentUserId;

  SimplePartyProvider() {
    _listenToParties();
    _listenToInvitations();
  }

  void _listenToParties() {
    _setLoading(true);
    _repository.getUserPartiesStream().listen(
      (parties) {
        _parties = parties;
        _setLoading(false);
        _clearError();
        
        // Load user data for all party members
        _loadPartyMemberUserData();
        
        notifyListeners();
      },
      onError: (error) {
        _setError('Error loading parties: $error');
        _setLoading(false);
      },
    );
  }

  void _loadPartyMemberUserData() {
    final allUserIds = <String>{};
    
    for (final party in _parties) {
      final members = party['members'] as List<dynamic>? ?? [];
      allUserIds.addAll(members.map((id) => id.toString()));
      
      // Also load user IDs from challenge data
      final challenge = party['activeChallenge'];
      if (challenge != null) {
        final lockedInMembers = challenge['lockedInMembers'] as List<dynamic>? ?? [];
        final optedOutMembers = challenge['optedOutMembers'] as List<dynamic>? ?? [];
        allUserIds.addAll(lockedInMembers.map((id) => id.toString()));
        allUserIds.addAll(optedOutMembers.map((id) => id.toString()));
      }
    }
    
    if (allUserIds.isNotEmpty) {
      loadUserData(allUserIds.toList());
    }
  }

  Future<bool> createParty(String name) async {
    try {
      _setLoading(true);
      final partyId = await _repository.createParty(name);
      _setLoading(false);
      
      if (partyId != null) {
        // Force refresh
        await _refreshParties();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error creating party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _refreshParties() async {
    try {
      final parties = await _repository.getUserParties();
      _parties = parties;
      notifyListeners();
    } catch (e) {
      _setError('Error refreshing parties: $e');
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

  void _listenToInvitations() {
    _repository.getReceivedInvitationsStream().listen(
      (invitations) {
        _invitations = invitations;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error loading invitations: $error');
      },
    );
  }

  Future<bool> sendInvitation(String partyId, String inviteeEmail) async {
    try {
      _setLoading(true);
      final success = await _repository.sendInvitation(partyId, inviteeEmail);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error sending invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> acceptInvitation(String invitationId, String partyId) async {
    try {
      _setLoading(true);
      final success = await _repository.acceptInvitation(invitationId, partyId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error accepting invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> declineInvitation(String invitationId) async {
    try {
      _setLoading(true);
      final success = await _repository.declineInvitation(invitationId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error declining invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> joinParty(String partyId) async {
    try {
      _setLoading(true);
      final success = await _repository.joinParty(partyId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error joining party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> leaveParty(String partyId) async {
    try {
      _setLoading(true);
      final success = await _repository.leaveParty(partyId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error leaving party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeMember(String partyId, String memberId) async {
    try {
      _setLoading(true);
      final success = await _repository.removeMember(partyId, memberId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error removing member: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteParty(String partyId) async {
    try {
      _setLoading(true);
      final success = await _repository.deleteParty(partyId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error deleting party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPartyById(String partyId) async {
    try {
      return await _repository.getPartyById(partyId);
    } catch (e) {
      _setError('Error getting party details: $e');
      return null;
    }
  }

  String getUserDisplayName(String userId) {
    final userData = _userCache[userId];
    if (userData != null) {
      if (userData['username']?.isNotEmpty == true) {
        return userData['username']!;
      } else if (userData['displayName']?.isNotEmpty == true) {
        return userData['displayName']!;
      } else {
        return userData['email'] ?? 'User';
      }
    }
    
    // If user data is not cached, trigger loading and return a friendly fallback
    loadUserData([userId]);
    return 'Loading...';
  }

  String getUserInitials(String userId) {
    final userData = _userCache[userId];
    if (userData != null) {
      final name = userData['username'] ?? userData['displayName'] ?? userData['email'];
      if (name?.isNotEmpty == true) {
        final parts = name.split(' ');
        if (parts.length >= 2) {
          return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
        } else {
          return parts[0][0].toUpperCase();
        }
      }
    }
    return userId.isNotEmpty ? userId[0].toUpperCase() : '?';
  }

  Future<void> loadUserData(List<String> userIds) async {
    final uncachedIds = userIds.where((id) => !_userCache.containsKey(id)).toList();
    if (uncachedIds.isEmpty) return;

    try {
      final users = await _repository.getUsersByIds(uncachedIds);
      for (final user in users) {
        _userCache[user['id']] = user;
      }
      notifyListeners();
    } catch (e) {
      // Silently fail user data loading
    }
  }

  // Challenge-related methods

  bool hasActiveChallenge(String partyId) {
    final party = _parties.firstWhere(
      (p) => p['id'] == partyId,
      orElse: () => <String, dynamic>{},
    );
    final challenge = party['activeChallenge'];
    return challenge != null && challenge['status'] == 'active';
  }

  bool hasPendingChallenge(String partyId) {
    final party = _parties.firstWhere(
      (p) => p['id'] == partyId,
      orElse: () => <String, dynamic>{},
    );
    final challenge = party['activeChallenge'];
    return challenge != null && challenge['status'] == 'setup';
  }

  ChallengeState? getActiveChallenge(String partyId) {
    final party = _parties.firstWhere(
      (p) => p['id'] == partyId,
      orElse: () => <String, dynamic>{},
    );
    final challengeData = party['activeChallenge'];
    if (challengeData != null) {
      return ChallengeState.fromMap(challengeData);
    }
    return null;
  }

  bool isPartyLeader(String partyId) {
    final party = _parties.firstWhere(
      (p) => p['id'] == partyId,
      orElse: () => <String, dynamic>{},
    );
    return party['leaderId'] == currentUserId;
  }

  bool hasUserLockedIn(String partyId) {
    if (currentUserId == null) return false;
    
    final party = _parties.firstWhere(
      (p) => p['id'] == partyId,
      orElse: () => <String, dynamic>{},
    );
    final challenge = party['activeChallenge'];
    if (challenge == null) return false;
    
    final lockedInMembers = List<String>.from(challenge['lockedInMembers'] ?? []);
    return lockedInMembers.contains(currentUserId);
  }

  Future<bool> setupChallenge(String partyId, DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      final success = await _challengeActions.setupChallenge(partyId, startDate, endDate);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error setting up challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> lockInForChallenge(String partyId, double wagerAmount) async {
    try {
      _setLoading(true);
      final success = await _challengeActions.lockInForChallenge(partyId, wagerAmount);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error locking in for challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> optOutOfChallenge(String partyId) async {
    try {
      _setLoading(true);
      final success = await _challengeActions.optOutOfChallenge(partyId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error opting out of challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> startChallenge(String partyId) async {
    try {
      _setLoading(true);
      final success = await _challengeActions.startChallenge(partyId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error starting challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> completeChallenge(String partyId, Map<String, bool> goalCompletions) async {
    try {
      _setLoading(true);
      final success = await _challengeActions.completeChallenge(partyId, goalCompletions);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error completing challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> lockInGoalsForChallenge(String partyId, List challengeGoals) async {
    try {
      _setLoading(true);
      final success = await _challengeActions.lockInGoalsForChallenge(partyId, challengeGoals);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error locking in goals for challenge: $e');
      _setLoading(false);
      return false;
    }
  }
}