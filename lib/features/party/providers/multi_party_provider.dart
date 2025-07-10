import 'dart:async';
import 'package:flutter/material.dart';
import '../models/party_model_multi.dart';
import '../models/party_membership.dart';
import '../repositories/multi_party_repository.dart';
import '../../auth/models/user_model.dart';

class MultiPartyProvider with ChangeNotifier {
  final MultiPartyRepository _repository;
  
  // State
  List<MultiParty> _userParties = [];
  String? _currentPartyId;
  MultiParty? _currentParty;
  UserModel? _currentUser;
  List<Map<String, dynamic>> _pendingInvitations = [];
  Map<String, List<Map<String, dynamic>>> _sentInvitations = {};
  final Map<String, UserModel> _userCache = {}; // Cache user data by userId
  bool _isLoading = false;
  String? _error;
  
  // Subscriptions
  StreamSubscription<List<MultiParty>>? _partiesSubscription;
  StreamSubscription<MultiParty?>? _currentPartySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _invitationsSubscription;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _sentInvitationSubscriptions = {};
  bool _isDisposed = false;

  MultiPartyProvider({MultiPartyRepository? repository})
      : _repository = repository ?? MultiPartyRepository() {
    _initializeStreams();
  }

  // Getters
  List<MultiParty> get userParties => _userParties;
  String? get currentPartyId => _currentPartyId;
  MultiParty? get currentParty => _currentParty;
  UserModel? get currentUser => _currentUser;
  String? get currentUserId => _repository.currentUserId;
  List<Map<String, dynamic>> get pendingInvitations => _pendingInvitations;
  Map<String, List<Map<String, dynamic>>> get sentInvitations => _sentInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get hasParties => _userParties.isNotEmpty;
  bool get hasMultipleParties => _userParties.length > 1;
  bool get hasCurrentParty => _currentParty != null;
  bool get hasPendingInvitations => _pendingInvitations.isNotEmpty;
  
  // Current party convenience getters
  bool get isCurrentUserPartyLeader => 
      _currentParty?.isLeader(_repository.currentUserId ?? '') ?? false;
  List<String> get currentPartyMembers => _currentParty?.members ?? [];
  int get currentPartyMemberCount => _currentParty?.memberCount ?? 0;
  bool get currentPartyCanAddMembers => _currentParty?.canAddMembers ?? false;

  // Party filtering
  List<MultiParty> get activeParties => _userParties;
  List<MultiParty> get leaderParties => 
      _userParties.where((party) => party.isLeader(_repository.currentUserId ?? '')).toList();
  List<MultiParty> get memberParties => 
      _userParties.where((party) => !party.isLeader(_repository.currentUserId ?? '')).toList();

  void _initializeStreams() {
    if (_isDisposed) return;

    _setLoading(true);
    
    // Stream user's parties
    _partiesSubscription = _repository.streamUserParties().listen(
      (parties) {
        if (_isDisposed) return;
        
        _userParties = parties;
        
        // Pre-load user data for all party members
        for (final party in parties) {
          loadPartyMemberData(party.members);
        }
        
        // If no current party is set and we have parties, set the first one
        if (_currentPartyId == null && parties.isNotEmpty) {
          setCurrentParty(parties.first.id);
        }
        
        // If current party was deleted, clear it
        if (_currentPartyId != null && 
            !parties.any((party) => party.id == _currentPartyId)) {
          _currentPartyId = null;
          _currentParty = null;
          _currentPartySubscription?.cancel();
        }
        
        _setLoading(false);
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        if (_isDisposed) return;
        _setError('Failed to load parties: $error');
        _setLoading(false);
      },
    );
    
    // Stream pending invitations
    _invitationsSubscription = _repository.streamPendingInvitations().listen(
      (invitations) {
        if (_isDisposed) return;
        _pendingInvitations = invitations;
        notifyListeners();
      },
      onError: (error) {
        if (_isDisposed) return;
        debugPrint('Error loading invitations: $error');
      },
    );
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
    notifyListeners();
  }

  // Party Management
  Future<bool> createParty({
    required String name,
    String challengeDuration = 'weekly',
    String startDay = 'monday',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final party = MultiParty.create(
        leaderId: _repository.currentUserId!,
        name: name.trim(),
        challengeDuration: challengeDuration,
        startDay: startDay,
      );

      final partyId = await _repository.createParty(party);
      
      if (partyId != null) {
        _setLoading(false);
        
        // Force refresh the parties stream to ensure immediate update
        await _forceRefreshParties();
        
        // Set as current party after refresh
        setCurrentParty(partyId);
        
        return true;
      } else {
        _setError('Failed to create party');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error creating party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateParty(MultiParty party) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.updateParty(party);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update party');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteParty(String partyId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.deleteParty(partyId);
      
      if (success) {
        // If deleted party was current party, clear it
        if (_currentPartyId == partyId) {
          _currentPartyId = null;
          _currentParty = null;
          _currentPartySubscription?.cancel();
        }
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to delete party');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error deleting party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> leaveParty(String partyId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.leaveParty(partyId, _repository.currentUserId!);
      
      if (success) {
        // If left party was current party, clear it
        if (_currentPartyId == partyId) {
          _currentPartyId = null;
          _currentParty = null;
          _currentPartySubscription?.cancel();
        }
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to leave party');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error leaving party: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> transferLeadership(String partyId, String newLeaderId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.transferLeadership(partyId, newLeaderId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to transfer leadership');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error transferring leadership: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeMember(String partyId, String memberId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.removeMember(partyId, memberId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to remove member');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error removing member: $e');
      _setLoading(false);
      return false;
    }
  }

  // Invitation Management
  Future<bool> sendInvitation(String partyId, String inviteeEmail) async {
    try {
      _setLoading(true);
      _clearError();

      final inviteId = await _repository.createInvitation(partyId, inviteeEmail);
      
      if (inviteId != null) {
        // Start streaming sent invitations for this party if not already
        _streamSentInvitationsForParty(partyId);
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to send invitation');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error sending invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> acceptInvitation(String inviteId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.acceptInvitation(inviteId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to accept invitation');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error accepting invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> declineInvitation(String inviteId) async {
    try {
      final success = await _repository.declineInvitation(inviteId);
      
      if (!success) {
        _setError('Failed to decline invitation');
      }
      
      return success;
    } catch (e) {
      _setError('Error declining invitation: $e');
      return false;
    }
  }

  // Current Party Management
  void setCurrentParty(String? partyId) {
    if (_currentPartyId == partyId) return;
    
    // Cancel previous subscription
    _currentPartySubscription?.cancel();
    
    _currentPartyId = partyId;
    
    if (partyId != null) {
      // Start streaming the current party
      _currentPartySubscription = _repository.streamParty(partyId).listen(
        (party) {
          if (_isDisposed) return;
          _currentParty = party;
          
          // Pre-load user data for party members
          if (party != null) {
            loadPartyMemberData(party.members);
          }
          
          // Start streaming sent invitations for this party
          _streamSentInvitationsForParty(partyId);
          
          notifyListeners();
        },
        onError: (error) {
          if (_isDisposed) return;
          debugPrint('Error loading current party: $error');
        },
      );
    } else {
      _currentParty = null;
      notifyListeners();
    }
  }

  void _streamSentInvitationsForParty(String partyId) {
    // Cancel existing subscription for this party
    _sentInvitationSubscriptions[partyId]?.cancel();
    
    // Start new subscription
    _sentInvitationSubscriptions[partyId] = 
        _repository.streamSentInvitations(partyId).listen(
      (invitations) {
        if (_isDisposed) return;
        _sentInvitations[partyId] = invitations;
        notifyListeners();
      },
      onError: (error) {
        if (_isDisposed) return;
        debugPrint('Error loading sent invitations for party $partyId: $error');
      },
    );
  }

  List<Map<String, dynamic>> getSentInvitationsForParty(String partyId) {
    return _sentInvitations[partyId] ?? [];
  }

  // User Data Methods
  
  /// Get cached user data or fetch if not available
  UserModel? getUserData(String userId) {
    return _userCache[userId];
  }

  /// Fetch user data and cache it
  Future<UserModel?> fetchUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final userData = await _repository.getUserModel(userId);
      if (userData != null) {
        _userCache[userId] = userData;
        notifyListeners();
      }
      return userData;
    } catch (e) {
      debugPrint('Error fetching user data for $userId: $e');
      return null;
    }
  }

  /// Get display name for a user (with fallback)
  String getUserDisplayName(String userId) {
    final userData = _userCache[userId];
    if (userData != null) {
      // Prioritize username, then displayName, then email
      if (userData.username?.isNotEmpty == true) {
        return userData.username!;
      } else if (userData.displayName?.isNotEmpty == true) {
        return userData.displayName!;
      } else {
        return userData.email;
      }
    }
    
    // Fallback to truncated ID while loading
    return userId.length > 10 ? '${userId.substring(0, 10)}...' : userId;
  }

  /// Get initials for a user (with fallback)
  String getUserInitials(String userId) {
    final userData = _userCache[userId];
    if (userData != null) {
      // Prioritize username, then displayName, then email for initials
      final name = userData.username?.isNotEmpty == true 
          ? userData.username!
          : userData.displayName?.isNotEmpty == true 
              ? userData.displayName!
              : userData.email;
      
      if (name.isNotEmpty) {
        final parts = name.split(' ');
        if (parts.length >= 2) {
          return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else {
          return name.substring(0, 1).toUpperCase();
        }
      }
    }
    
    // Fallback to user ID initials
    return userId.length >= 2 ? userId.substring(0, 2).toUpperCase() : 'U';
  }

  /// Pre-fetch user data for all party members
  Future<void> loadPartyMemberData(List<String> memberIds) async {
    for (String memberId in memberIds) {
      if (!_userCache.containsKey(memberId)) {
        fetchUserData(memberId); // Fire and forget for performance
      }
    }
  }

  // Utility Methods
  MultiParty? getPartyById(String partyId) {
    try {
      return _userParties.firstWhere((party) => party.id == partyId);
    } catch (e) {
      return null;
    }
  }

  bool isUserPartyMember(String partyId, String userId) {
    final party = getPartyById(partyId);
    return party?.isMember(userId) ?? false;
  }

  bool isUserPartyLeader(String partyId, String userId) {
    final party = getPartyById(partyId);
    return party?.isLeader(userId) ?? false;
  }

  // Challenge Management Methods
  
  /// Party leader sets up a new challenge
  Future<bool> setupChallenge(String partyId, DateTime startDate, DateTime endDate) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.setupChallenge(partyId, startDate, endDate);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to setup challenge');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error setting up challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  /// User locks in their goals and wager for the challenge
  Future<bool> lockInForChallenge(String partyId, double wagerAmount) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.lockInForChallenge(partyId, wagerAmount);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to lock in for challenge');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error locking in for challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  /// User opts out of the challenge
  Future<bool> optOutOfChallenge(String partyId) async {
    try {
      final success = await _repository.optOutOfChallenge(partyId);
      
      if (!success) {
        _setError('Failed to opt out of challenge');
      }
      
      return success;
    } catch (e) {
      _setError('Error opting out of challenge: $e');
      return false;
    }
  }

  /// Party leader starts the challenge
  Future<bool> startChallenge(String partyId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.startChallenge(partyId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to start challenge');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error starting challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Party leader cancels the challenge
  Future<bool> cancelChallenge(String partyId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.cancelChallenge(partyId);
      
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to cancel challenge');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error canceling challenge: $e');
      _setLoading(false);
      return false;
    }
  }

  // Refresh methods
  Future<void> refresh() async {
    _initializeStreams();
  }

  Future<void> refreshInvitations() async {
    // Invitations are already being streamed, no need for manual refresh
  }

  /// Force refresh the parties list by manually fetching user parties
  Future<void> _forceRefreshParties() async {
    try {
      // Get the latest user parties directly from repository
      final parties = await _repository.getUserParties();
      _userParties = parties;
      notifyListeners();
    } catch (e) {
      debugPrint('Error force refreshing parties: $e');
    }
  }

  /// Restart the streams to clear any cache issues
  void _restartStreams() {
    // Cancel existing streams
    _partiesSubscription?.cancel();
    _currentPartySubscription?.cancel();
    _invitationsSubscription?.cancel();
    
    // Clear sent invitation subscriptions
    for (final subscription in _sentInvitationSubscriptions.values) {
      subscription.cancel();
    }
    _sentInvitationSubscriptions.clear();
    
    // Restart streams
    _initializeStreams();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _partiesSubscription?.cancel();
    _currentPartySubscription?.cancel();
    _invitationsSubscription?.cancel();
    
    for (final subscription in _sentInvitationSubscriptions.values) {
      subscription.cancel();
    }
    _sentInvitationSubscriptions.clear();
    
    super.dispose();
  }
}