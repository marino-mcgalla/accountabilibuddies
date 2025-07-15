import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../goals/models/goal_model.dart';
import '../actions/party_actions.dart';
import '../services/party_members_service.dart';
import '../state/party_state.dart';
import '../streams/party_stream_manager.dart';
import '../../proof_submission/streams/proof_stream_manager.dart';

class PartyProvider with ChangeNotifier {
  // Dependencies
  final PartyActions _actions;
  final PartyStreamManager _streamManager;
  final PartyMembersService _membersService;
  final ProofStreamManager _proofStreamManager;
  final FirebaseAuth _auth;

  // Controllers
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController inviteController = TextEditingController();

  // State
  PartyState _state = const PartyState();
  Map<String, List<Goal>> _partyMemberGoals = {};
  bool _isDisposed = false;

  // Subscriptions
  StreamSubscription<PartyState>? _partySubscription;
  StreamSubscription<Map<String, List<Goal>>>? _goalSubscription;

  PartyProvider({
    PartyActions? actions,
    PartyStreamManager? streamManager,
    PartyMembersService? membersService,
    ProofStreamManager? proofStreamManager,
    FirebaseAuth? auth,
  })  : _actions = actions ?? PartyActions(),
        _streamManager = streamManager ?? PartyStreamManager(),
        _membersService = membersService ?? PartyMembersService(),
        _proofStreamManager = proofStreamManager ?? ProofStreamManager(),
        _auth = auth ?? FirebaseAuth.instance {
    _initializeStreams();
  }

  // Getters
  PartyState get state => _state;
  Map<String, List<Goal>> get partyMemberGoals => _partyMemberGoals;
  bool get isCurrentUserPartyLeader => _state.partyLeaderId == _auth.currentUser?.uid;
  String? get currentUserId => _auth.currentUser?.uid;

  // Convenience getters
  String? get partyId => _state.partyId;
  String? get partyName => _state.partyName;
  List<String> get members => _state.members;
  Map<String, Map<String, dynamic>> get memberDetails => _state.memberDetails;
  bool get isLoading => _state.isLoading;
  bool get hasActiveChallenge => _state.hasActiveChallenge;
  bool get hasPendingChallenge => _state.hasPendingChallenge;
  List<String> get lockedInMembers => _state.lockedInMembers;
  Map<String, dynamic> get memberWagers => _state.memberWagers;
  
  bool get isCurrentUserLockedIn => _state.lockedInMembers.contains(currentUserId);
  bool get isCurrentUserOptedOut => _state.optedOutMembers.contains(currentUserId);

  double getCurrentUserWager() => _state.getMemberWager(currentUserId ?? '');
  double getMemberWager(String userId) => _state.getMemberWager(userId);
  double getTotalWagerPool() => _state.getTotalWagerPool();

  // Essential missing getters for compatibility
  List<String> get optedOutMembers => _state.optedOutMembers;
  int get challengeStartDay => _state.challengeStartDay;
  String get challengeStartDayName {
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return dayNames[challengeStartDay];
  }
  String? get partyLeaderId => _state.partyLeaderId;
  DateTime? get challengeStartDate => _state.activeChallenge != null ? DateTime.now() : null; // Stub
  DateTime? get challengeEndDate => _state.activeChallenge != null ? DateTime.now().add(Duration(days: 7)) : null; // Stub
  bool get areAllMembersReady => true; // Stub - implement properly later
  static const List<String> dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  // Challenge Management Methods
  Future<bool> startChallengePreparation() async {
    if (_isDisposed || _state.partyId == null || !isCurrentUserPartyLeader) {
      return false;
    }
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    final success = await _actions.startChallengePrep(_state.partyId!);
    
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
    
    return success;
  }

  Future<bool> lockInForChallenge(double wager) async {
    if (_isDisposed || _state.partyId == null) return false;
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    final success = await _actions.lockInMember(_state.partyId!, wager);
    
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
    
    return success;
  }

  Future<bool> optOutOfChallenge() async {
    if (_isDisposed || _state.partyId == null) return false;
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    final success = await _actions.optOutMember(_state.partyId!);
    
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
    
    return success;
  }

  Future<bool> cancelChallengePreparation() async {
    if (_isDisposed || _state.partyId == null || !isCurrentUserPartyLeader) {
      return false;
    }
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    final success = await _actions.cancelChallengePrep(_state.partyId!);
    
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
    
    return success;
  }

  Future<bool> endCurrentChallenge() async {
    if (_isDisposed || _state.partyId == null || !isCurrentUserPartyLeader) {
      return false;
    }
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    final success = await _actions.endChallenge(_state.partyId!);
    
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
    
    return success;
  }

  // Legacy compatibility methods
  Function() get closeParty => () async {
    await leaveParty();
  };
  Future<bool> initializeGoalsListener() async => true;
  Future<void> optOutMember() async => await optOutOfChallenge();
  Future<void> confirmChallengeStart(BuildContext context) async {}
  Future<void> setChallengeStartDay(int day) async {}
  Future<void> initiateChallengePreparation() async => await startChallengePreparation();
  Future<void> undoOptOutMember() async {}
  Future<void> undoLockInMember() async {}
  Stream<List<Map<String, dynamic>>> streamSubmittedProofs() {
    if (_state.partyId == null || _state.members.isEmpty) {
      return Stream.value([]);
    }
    return _proofStreamManager.getPendingProofsStream(_state.partyId!, _state.members);
  }
  Future<void> approveProof(String userId, String goalId, String? date) async {
    if (_state.partyId == null) return;
    
    try {
      // Update the actual goal completion status in Firestore
      final firestore = FirebaseFirestore.instance;
      final userGoalsRef = firestore.collection('userGoals').doc(userId);
      
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userGoalsRef);
        if (!snapshot.exists) return;
        
        final data = snapshot.data()!;
        final goals = List<Map<String, dynamic>>.from(data['goals'] ?? []);
        
        // Find the goal to update
        for (int i = 0; i < goals.length; i++) {
          final goal = goals[i];
          if (goal['id'] == goalId) {
            // Initialize challenge structure if needed
            if (goal['challenge'] == null) {
              goal['challenge'] = {'completions': {}, 'proofs': goal['goalType'] == 'total' ? [] : {}};
            }
            
            if (goal['goalType'] == 'weekly' && date != null) {
              // Update weekly goal completion
              final challengeCompletions = goal['challenge']['completions'];
              final completions = challengeCompletions != null 
                  ? Map<String, dynamic>.from(challengeCompletions as Map)
                  : <String, dynamic>{};
              completions[date] = 'completed';
              goal['challenge']['completions'] = completions;
              
              // CRITICAL: Also update legacy currentWeekCompletions - this is what the dashboard reads!
              final currentCompletions = goal['currentWeekCompletions'];
              final currentWeekCompletions = currentCompletions != null
                  ? Map<String, dynamic>.from(currentCompletions as Map)
                  : <String, dynamic>{};
              currentWeekCompletions[date] = 'completed';  // WeeklyGoal expects String values
              goal['currentWeekCompletions'] = currentWeekCompletions;
              
              // Keep the proof but mark it as approved
              final challengeProofs = goal['challenge']['proofs'];
              if (challengeProofs is Map && challengeProofs[date] != null) {
                final proof = Map<String, dynamic>.from(challengeProofs[date] as Map);
                proof['status'] = 'approved';
                proof['approvedBy'] = currentUserId;
                proof['approvedAt'] = DateTime.now().toIso8601String();
                challengeProofs[date] = proof;
              }
            } else if (goal['goalType'] == 'total') {
              // Update total goal - find the pending proof and approve it
              final challengeProofs = goal['challenge']['proofs'];
              if (challengeProofs is List) {
                final proofs = List<Map<String, dynamic>>.from(
                    challengeProofs.map((p) => Map<String, dynamic>.from(p as Map))
                );
                for (int j = 0; j < proofs.length; j++) {
                  if (proofs[j]['status'] == 'pending') {
                    proofs[j]['status'] = 'approved';
                    proofs[j]['approvedBy'] = currentUserId;
                    proofs[j]['approvedAt'] = DateTime.now().toIso8601String();
                    break; // Only approve the first pending proof
                  }
                }
                goal['challenge']['proofs'] = proofs;
              }
            }
            
            goals[i] = goal;
            break;
          }
        }
        
        // Update the document
        transaction.update(userGoalsRef, {'goals': goals});
      });
      
      // Emit approval event for real-time updates
      await _proofStreamManager.emitProofEvent(
        _state.partyId!,
        ProofEvent(
          type: 'approved',
          userId: userId,
          goalId: goalId,
          proofDate: date,
          data: {
            'approvedBy': currentUserId,
          },
          timestamp: DateTime.now(),
        ),
      );
      
      // Trigger a refresh of party member goals to update the UI
      notifyListeners();
    } catch (e) {
      print('ERROR: Failed to approve proof: $e');
      rethrow;
    }
  }

  Future<void> denyProof(String userId, String goalId, String? date) async {
    if (_state.partyId == null) return;
    
    try {
      // Update the actual goal completion status in Firestore
      final firestore = FirebaseFirestore.instance;
      final userGoalsRef = firestore.collection('userGoals').doc(userId);
      
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userGoalsRef);
        if (!snapshot.exists) return;
        
        final data = snapshot.data()!;
        final goals = List<Map<String, dynamic>>.from(data['goals'] ?? []);
        
        // Find the goal to update
        for (int i = 0; i < goals.length; i++) {
          final goal = goals[i];
          if (goal['id'] == goalId) {
            // Initialize challenge structure if needed
            if (goal['challenge'] == null) {
              goal['challenge'] = {'completions': {}, 'proofs': goal['goalType'] == 'total' ? [] : {}};
            }
            
            if (goal['goalType'] == 'weekly' && date != null) {
              // Update weekly goal completion
              final challengeCompletions = goal['challenge']['completions'];
              final completions = challengeCompletions != null 
                  ? Map<String, dynamic>.from(challengeCompletions as Map)
                  : <String, dynamic>{};
              completions[date] = 'denied';
              goal['challenge']['completions'] = completions;
              
              // Remove the proof
              final challengeProofs = goal['challenge']['proofs'];
              if (challengeProofs is Map) {
                challengeProofs.remove(date);
              }
            } else if (goal['goalType'] == 'total') {
              // Update total goal - remove the first pending proof
              final challengeProofs = goal['challenge']['proofs'];
              if (challengeProofs is List) {
                final proofs = List<Map<String, dynamic>>.from(
                    challengeProofs.map((p) => Map<String, dynamic>.from(p as Map))
                );
                proofs.removeWhere((proof) => proof['status'] == 'pending');
                goal['challenge']['proofs'] = proofs;
              }
            }
            
            goals[i] = goal;
            break;
          }
        }
        
        // Update the document
        transaction.update(userGoalsRef, {'goals': goals});
      });
      
      // Emit denial event for real-time updates
      await _proofStreamManager.emitProofEvent(
        _state.partyId!,
        ProofEvent(
          type: 'denied',
          userId: userId,
          goalId: goalId,
          proofDate: date,
          data: {
            'deniedBy': currentUserId,
          },
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('ERROR: Failed to deny proof: $e');
      rethrow;
    }
  }
  
  // Compatible sendInvite method for button onPressed (no parameters)
  void sendInviteFromController() async {
    if (inviteController.text.isNotEmpty) {
      await sendInvite(inviteController.text);
      inviteController.clear();
    }
  }

  void _initializeStreams() {
    if (_isDisposed) return;

    // Listen to party state changes
    _partySubscription = _streamManager.getPartyStateStream().listen((newState) {
      if (_isDisposed) return;
      
      final membersChanged = !_areListsEqual(_state.members, newState.members);
      
      // Preserve existing memberDetails when updating state
      _state = newState.copyWith(memberDetails: _state.memberDetails);
      
      if (membersChanged) {
        _subscribeToMemberGoals();
        _fetchMemberDetails();
      } else if (_state.members.isNotEmpty && _state.memberDetails.isEmpty) {
        // Initial load case - we have members but no details yet
        _fetchMemberDetails();
      }
      
      notifyListeners();
    });
  }

  void _subscribeToMemberGoals() {
    if (_state.members.isEmpty) return;
    
    _goalSubscription?.cancel();
    _goalSubscription = _streamManager.getMemberGoalsStream(_state.members).listen((goals) {
      if (_isDisposed) return;
      _partyMemberGoals = goals;
      notifyListeners();
    });
  }

  void _fetchMemberDetails() async {
    if (_state.members.isEmpty) return;
    
    final details = await _membersService.fetchMemberDetails(_state.members);
    _state = _state.copyWith(memberDetails: details);
    notifyListeners();
  }

  // Actions
  Future<bool> createParty(String partyName) async {
    if (_isDisposed) return false;
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    final partyId = await _actions.createParty(partyName);
    
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
    
    return partyId != null;
  }

  Future<bool> leaveParty() async {
    if (_isDisposed || _state.partyId == null) return false;
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    final success = await _actions.leaveParty(_state.partyId!);
    
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
    
    return success;
  }

  Future<bool> transferLeadership(String newLeaderId) async {
    if (_isDisposed || _state.partyId == null || !isCurrentUserPartyLeader) {
      return false;
    }
    
    return await _actions.transferLeadership(_state.partyId!, newLeaderId, _state.members);
  }

  Future<bool> removeMember(String memberId) async {
    if (_isDisposed || _state.partyId == null || !isCurrentUserPartyLeader) {
      return false;
    }
    
    return await _actions.removeMember(_state.partyId!, memberId, _state.members);
  }

  Future<bool> sendInvite(String inviteeEmail) async {
    if (_isDisposed || _state.partyId == null) return false;
    return await _membersService.sendInvite(inviteeEmail, _state.partyId!);
  }

  Future<bool> acceptInvite(String inviteId, String partyId) async {
    if (_isDisposed) return false;
    
    try {
      await _membersService.acceptInvite(inviteId, partyId);
      // The party subscription will handle state updates automatically
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelInvite(String inviteId) async {
    if (_isDisposed) return false;
    
    try {
      await _membersService.cancelInvite(inviteId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> fetchIncomingPendingInvites() {
    return _membersService.fetchIncomingPendingInvites();
  }

  Stream<QuerySnapshot> fetchOutgoingPendingInvites() {
    if (_state.partyId == null) {
      // Return empty stream if no party
      final controller = StreamController<QuerySnapshot>.broadcast();
      controller.close();
      return controller.stream;
    }
    return _membersService.fetchOutgoingPendingInvites(_state.partyId!);
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _partySubscription?.cancel();
    _goalSubscription?.cancel();
    _streamManager.dispose();
    partyNameController.dispose();
    inviteController.dispose();
    super.dispose();
  }
}