import 'dart:async';
import 'package:auth_test/features/goals/providers/goals_provider.dart';
import 'package:auth_test/features/party/models/party_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../goals/models/goal_model.dart';
import '../services/party_members_service.dart';
import '../services/party_goals_service.dart';
import '../../time_machine/providers/time_machine_provider.dart';
import '../repositories/party_repository.dart';

class PartyProvider with ChangeNotifier {
  // Services
  final PartyMembersService _membersService;
  late final PartyGoalsService _goalsService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PartyRepository _repository;
  final GoalsProvider _goalsProvider;

  // Controllers
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController inviteController = TextEditingController();

  // State variables
  String? _partyId;
  String? _partyName;
  String? _partyLeaderId;
  List<String> _members = [];
  Map<String, Map<String, dynamic>> _memberDetails = {};
  Map<String, List<Goal>> _partyMemberGoals = {};
  bool _isLoading = true;
  bool _isDisposed = false; // Track if provider has been disposed
  int _challengeStartDay = 1; // Default to Monday
  Map<String, dynamic>? _activeChallenge;
  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  // Subscription management
  StreamSubscription<Map<String, dynamic>?>? _partySubscription;
  List<StreamSubscription<dynamic>?> _goalSubscriptions = [];

  // Batching updates
  bool _isBatchingUpdates = false;
  bool _pendingNotification = false;

  // Getters
  String? get partyId => _partyId;
  String? get partyName => _partyName;
  List<String> get members => _members;
  Map<String, Map<String, dynamic>> get memberDetails => _memberDetails;
  Map<String, List<Goal>> get partyMemberGoals => _partyMemberGoals;
  bool get isLoading => _isLoading;
  String? get partyLeaderId => _partyLeaderId;
  bool get isCurrentUserPartyLeader => _partyLeaderId == _auth.currentUser?.uid;
  int get challengeStartDay => _challengeStartDay;
  String get challengeStartDayName => dayNames[_challengeStartDay];
  bool get hasActiveChallenge => _activeChallenge != null;
  DateTime? get challengeStartDate => _activeChallenge != null
      ? (_activeChallenge!['startDate'] as Timestamp).toDate()
      : null;
  DateTime? get challengeEndDate {
    if (_activeChallenge == null ||
        !_activeChallenge!.containsKey('endDate') ||
        _activeChallenge!['endDate'] == null) {
      return null;
    }

    try {
      final endDateTimestamp = _activeChallenge!['endDate'] as Timestamp;
      return endDateTimestamp.toDate();
    } catch (e) {
      print('Error converting challenge end date: $e');
      return null;
    }
  }

  String? get challengeId => _activeChallenge?['id'];
  bool get hasPendingChallenge =>
      hasActiveChallenge && _activeChallenge?['state'] == 'pending';

  List<String> get lockedInMembers => hasPendingChallenge
      ? List<String>.from(_activeChallenge?['lockedInMembers'] ?? [])
      : [];

  bool get isCurrentUserLockedIn =>
      lockedInMembers.contains(_auth.currentUser?.uid);
  Map<String, dynamic> get memberWagers => _activeChallenge != null
      ? (_activeChallenge!['wagers'] as Map<String, dynamic>? ?? {})
      : {};

  PartyProvider({
    PartyMembersService? membersService,
    PartyGoalsService? goalsService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    PartyRepository? repository,
    required GoalsProvider goalsProvider,
  })  : _membersService = membersService ?? PartyMembersService(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _repository = repository ?? PartyRepository(),
        _goalsProvider = goalsProvider {
    // Initialize PartyGoalsService with this provider instance
    _goalsService = goalsService ?? PartyGoalsService(partyProvider: this);
    initializePartyState();
  }

  void initializePartyState() {
    if (_isDisposed) return;
    setLoading(true);

    _partySubscription?.cancel();

    _partySubscription = _repository.getUserPartyStream().listen((partyData) {
      if (_isDisposed) return;

      if (partyData == null) {
        _resetState();
        return;
      }

      batchUpdates(() {
        _partyId = partyData['partyId'];
        _partyName = partyData['partyName'];
        _partyLeaderId = partyData['partyOwner'];

        // Challenge configuration
        _challengeStartDay = partyData['challengeStartDay'] ?? 1;
        _activeChallenge = partyData['activeChallenge'];

        // Handle members
        final List<String> newMembers = List<String>.from(partyData['members']);
        final bool membersChanged = !_areListsEqual(_members, newMembers);
        _members = newMembers;

        if (membersChanged) {
          _cancelGoalSubscriptions();
          _partyMemberGoals = {};
          fetchMemberDetails();
          _subscribeToPartyMemberGoals();
        }

        setLoading(false);
      });
    });
  }
// DOING STUFF HERE ------------------------------------------------------------------------------------------------------------------------------------------------------------

  double getCurrentUserWager() {
    if (!hasActiveChallenge) return 0;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    return memberWagers[userId]?.toDouble() ?? 0;
  }

  double getMemberWager(String userId) {
    if (!hasActiveChallenge) return 0;
    return memberWagers[userId]?.toDouble() ?? 0;
  }

  double getTotalWagerPool() {
    if (!hasActiveChallenge) return 0;

    double total = 0;
    memberWagers.forEach((userId, amount) {
      total += (amount is num) ? amount.toDouble() : 0;
    });
    return total;
  }

  void _subscribeToPartyMemberGoals() {
    for (String memberId in _members) {
      var subscription =
          _repository.getMemberGoalsStream(memberId).listen((goals) {
        _partyMemberGoals[memberId] = goals;
        notifyListeners();
      });
      _goalSubscriptions.add(subscription);
    }
  }

// PARTY MANAGEMENT SECTION ------------------------------------------------------------------------------------------------------------------------------------
  Future<bool> createParty(String partyName) async {
    if (_isDisposed || partyName.trim().isEmpty) return false;
    setLoading(true);

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      Party party = Party.create(currentUserId, partyName);

      final String partyId = await _repository.createParty(party);
      await _repository.updateUserPartyReference(currentUserId, partyId);

      if (!_isDisposed) {
        batchUpdates(() {
          _partyId = partyId;
          _partyName = partyName;
          _members = [currentUserId];
          fetchMemberDetails();
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error creating party: $e');
      return false;
    } finally {
      if (!_isDisposed) setLoading(false);
    }
  }

  Future<void> transferLeadership(String newLeaderId) async {
    if (_isDisposed) return;
    if (_partyId == null) return;
    if (!isCurrentUserPartyLeader)
      return; // Only current leader can transfer leadership
    if (!_members.contains(newLeaderId)) return; // New leader must be a member

    setLoading(true);

    try {
      await _firestore.collection('parties').doc(_partyId).update({
        'partyOwner': newLeaderId,
      });
    } catch (e) {
      print('Error transferring leadership: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  Future<void> removeMember(String memberId) async {
    if (_isDisposed) return;
    if (_partyId == null) return;
    if (!isCurrentUserPartyLeader) return; // Only leader can remove members
    if (!_members.contains(memberId)) return; // Member must exist
    if (memberId == _auth.currentUser?.uid)
      return; // Can't remove self (use leaveParty instead)

    setLoading(true);

    try {
      List<String> updatedMembers = List<String>.from(_members);
      updatedMembers.remove(memberId);

      await _firestore.collection('parties').doc(_partyId).update({
        'members': updatedMembers,
      });

      await _firestore.collection('users').doc(memberId).update({
        'partyId': FieldValue.delete(),
      });
    } catch (e) {
      print('Error removing member: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  Future<void> leaveParty() async {
    if (_isDisposed) return;
    if (_partyId == null) return;

    setLoading(true);

    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('users').doc(currentUserId).update({
        'partyId': FieldValue.delete(),
      });

      await _firestore.collection('parties').doc(_partyId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });

      _resetState();
    } catch (e) {
      print('Error leaving party: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  Future<void> closeParty() async {
    if (_isDisposed || _partyId == null || !isCurrentUserPartyLeader) return;
    setLoading(true);

    try {
      await _repository.closeParty(_partyId!, _members);
      _resetState();
    } catch (e) {
      print('Error closing party: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  // INVITES SECTION ------------------------------------------------------------------------------------------------------------------------------------
  Future<void> sendInvite() async {
    if (_isDisposed) return; // Skip if already disposed
    if (_partyId == null || inviteController.text.isEmpty) return;

    try {
      bool success =
          await _membersService.sendInvite(inviteController.text, _partyId!);
      if (success && !_isDisposed) {
        inviteController.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error sending invite: $e');
    }
  }

  // Accept an invite to join a party
  Future<void> acceptInvite(String inviteId, String partyId) async {
    if (_isDisposed) return; // Skip if already disposed

    try {
      await _membersService.acceptInvite(inviteId, partyId);
      // The party subscription will handle state updates
    } catch (e) {
      print('Error accepting invite: $e');
    }
  }

  // Cancel a pending invite
  Future<void> cancelInvite(String inviteId) async {
    if (_isDisposed) return; // Skip if already disposed

    try {
      await _membersService.cancelInvite(inviteId);
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      print('Error canceling invite: $e');
    }
  }

// CHALLENGE SECTION ------------------------------------------------------------------------------------------------------------------------------------

  Future<void> initiateChallengePreparation() async {
    if (_isDisposed || _partyId == null || !isCurrentUserPartyLeader) return;
    if (hasActiveChallenge) {
      // Handle existing challenge case - either cancel or show error
      return;
    }

    setLoading(true);
    try {
      final now = DateTime.now();
      final challengeId = 'challenge_${now.millisecondsSinceEpoch}';

      final pendingChallenge = {
        'id': challengeId,
        'state': 'pending',
        'startDate': null, // Will be set when actually started
        'endDate': null, // Will be set when actually started
        'lockedInMembers': [], // Initially empty
        'initiatedAt': Timestamp.fromDate(now),
        'wagers': {}
      };

      await _firestore
          .collection('parties')
          .doc(_partyId)
          .update({'activeChallenge': pendingChallenge});
    } catch (e) {
      print('Error initiating challenge preparation: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> confirmChallengeStart(BuildContext context) async {
    if (_isDisposed || _partyId == null || !isCurrentUserPartyLeader) return;
    if (!hasActiveChallenge || _activeChallenge?['state'] != 'pending') return;

    setLoading(true);
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: 7));
      final challengeId = _activeChallenge!['id'];

      final activeChallenge = {
        'id': challengeId,
        'state': 'active',
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'lockedInMembers': _activeChallenge!['lockedInMembers'],
        'initiatedAt': _activeChallenge!['initiatedAt'],
        'wagers': _activeChallenge!['wagers'] ?? {}
      };

      await _firestore
          .collection('parties')
          .doc(_partyId)
          .update({'activeChallenge': activeChallenge});
    } catch (e) {
      print('Error confirming challenge: $e');
    } finally {
      setLoading(false);
    }
  }

// New method to cancel challenge preparation
  Future<void> cancelChallengePreparation() async {
    if (_isDisposed || _partyId == null || !isCurrentUserPartyLeader) return;
    if (!hasActiveChallenge || _activeChallenge?['state'] != 'pending') return;

    setLoading(true);
    try {
      await _firestore
          .collection('parties')
          .doc(_partyId)
          .update({'activeChallenge': null});
    } catch (e) {
      print('Error canceling challenge preparation: $e');
    } finally {
      setLoading(false);
    }
  }

  // Fetch member details
  Future<void> fetchMemberDetails() async {
    if (_isDisposed) return; // Skip if already disposed

    try {
      Map<String, Map<String, dynamic>> newMemberDetails =
          await _membersService.fetchMemberDetails(_members);

      if (!_isDisposed &&
          !_areMemberDetailsEqual(_memberDetails, newMemberDetails)) {
        _memberDetails = newMemberDetails;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching member details: $e');
    }
  }

  // Get streams for invites
  Stream<QuerySnapshot> fetchIncomingPendingInvites() {
    return _membersService.fetchIncomingPendingInvites();
  }

  Stream<QuerySnapshot> fetchOutgoingPendingInvites() {
    if (_partyId == null) {
      // Create a StreamController to return an empty stream
      final controller = StreamController<QuerySnapshot>.broadcast();
      // Close the controller immediately to avoid memory leaks
      controller.close();
      return controller.stream;
    }
    return _membersService.fetchOutgoingPendingInvites(_partyId!);
  }

// Update this method to pass partyId instead of members list:
  Future<List<Map<String, dynamic>>> fetchSubmittedProofs(
      [BuildContext? context]) async {
    if (_isDisposed) return []; // Skip if already disposed
    if (_partyId == null) return []; // Can't fetch without a party ID

    try {
      return await _goalsService.fetchSubmittedProofs(_partyId!);
    } catch (e) {
      print('Error fetching submitted goals: $e');
      return [];
    }
  }

  // Find a goal by ID
  Goal? findGoalById(String goalId) {
    for (var userId in _partyMemberGoals.keys) {
      final userGoals = _partyMemberGoals[userId] ?? [];
      for (var goal in userGoals) {
        if (goal.id == goalId) {
          return goal;
        }
      }
    }
    return null;
  }

  // Find the owner of a goal
  String? findGoalOwner(String goalId) {
    for (var userId in _partyMemberGoals.keys) {
      final userGoals = _partyMemberGoals[userId] ?? [];
      for (var goal in userGoals) {
        if (goal.id == goalId) {
          return userId;
        }
      }
    }
    return null;
  }

  Stream<List<Map<String, dynamic>>> streamSubmittedProofs() {
    if (_partyId == null) return Stream.value([]);

    return _firestore
        .collection('parties')
        .doc(_partyId)
        .snapshots()
        .asyncMap((_) async {
      try {
        return await fetchSubmittedProofs();
      } catch (e) {
        print('Error fetching submitted proofs: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  Future<void> approveProof(
      String userId, String goalId, String? proofDate) async {
    if (_isDisposed) return; // Skip if already disposed

    try {
      await _goalsService.approveProof(userId, goalId, proofDate);
    } catch (e) {
      print('Error approving proof: $e');
      rethrow;
    }
  }

  Future<void> denyProof(
      String userId, String goalId, String? proofDate) async {
    if (_isDisposed) return;

    try {
      await _goalsProvider.denyProof(goalId, userId, proofDate,
          existingGoals: partyMemberGoals[userId] ?? []);

      await fetchSubmittedProofs();
    } catch (e) {
      print('Error denying proof: $e');
      rethrow;
    }
  }

  // Helper methods
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  bool _areMemberDetailsEqual(Map<String, Map<String, dynamic>> oldDetails,
      Map<String, Map<String, dynamic>> newDetails) {
    if (oldDetails.length != newDetails.length) return false;

    for (final key in oldDetails.keys) {
      if (!newDetails.containsKey(key)) return false;

      final oldDetail = oldDetails[key]!;
      final newDetail = newDetails[key]!;

      if (oldDetail.length != newDetail.length) return false;

      for (final detailKey in oldDetail.keys) {
        if (!newDetail.containsKey(detailKey) ||
            oldDetail[detailKey].toString() !=
                newDetail[detailKey].toString()) {
          return false;
        }
      }
    }
    return true;
  }

  // Cancel goal subscriptions
  void _cancelGoalSubscriptions() {
    for (var subscription in _goalSubscriptions) {
      subscription?.cancel();
    }
    _goalSubscriptions = [];
  }

  // Reset state
  void _resetState() {
    if (_isDisposed) return; // Skip if already disposed

    batchUpdates(() {
      _partyId = null;
      _partyName = null;
      _members = [];
      _memberDetails = {};
      _partyMemberGoals = {};
      _cancelGoalSubscriptions();
      setLoading(false);
    });
  }

  // Public method to reset state (for auth changes)
  void resetState() {
    if (_isDisposed) return; // Skip if already disposed

    _partySubscription?.cancel();
    _resetState();
  }

  // Set loading state
  void setLoading(bool value) {
    if (_isDisposed) return; // Skip if already disposed

    _isLoading = value;
    notifyListeners();
  }

  // Batch updates to reduce UI rebuilds
  void batchUpdates(Function callback) {
    if (_isDisposed) return; // Skip if already disposed

    _isBatchingUpdates = true;
    callback();
    _isBatchingUpdates = false;

    if (_pendingNotification) {
      _pendingNotification = false;
      notifyListeners();
    }
  }

  // Override notifyListeners to support batching and check for disposed state
  @override
  void notifyListeners() {
    if (_isDisposed) {
      // Skip notification if already disposed
      return;
    }

    if (_isBatchingUpdates) {
      _pendingNotification = true;
    } else {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    // Set the disposed flag before canceling subscriptions
    _isDisposed = true;

    // Cancel all subscriptions
    _partySubscription?.cancel();
    _cancelGoalSubscriptions();
    partyNameController.dispose();
    inviteController.dispose();

    super.dispose();
  }

  //challenge stuff:
  // Add these methods to PartyProvider

  // Set which day of the week challenges will start on
  Future<void> setChallengeStartDay(int dayOfWeek) async {
    if (_isDisposed) return;
    if (_partyId == null) return;
    if (!isCurrentUserPartyLeader) return; // Only leader can configure
    if (dayOfWeek < 0 || dayOfWeek > 6) return; // Valid range check

    try {
      await _firestore.collection('parties').doc(_partyId).update({
        'challengeStartDay': dayOfWeek,
      });
      // State will update via stream listener
    } catch (e) {
      print('Error setting challenge start day: $e');
    }
  }

  Future<void> startNewChallenge() async {
    if (_isDisposed) return;
    if (_partyId == null) return;
    if (!isCurrentUserPartyLeader) return;
    if (hasActiveChallenge) return;

    setLoading(true);

    try {
      // Create challenge metadata
      final now = DateTime.now();
      final challengeId = 'challenge_${now.millisecondsSinceEpoch}';
      final endDate = now.add(Duration(days: 7));

      final challenge = {
        'id': challengeId,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active',
      };

      // Update party with challenge info - that's all the leader needs to do
      await _firestore
          .collection('parties')
          .doc(_partyId)
          .update({'activeChallenge': challenge});

      print('Challenge started successfully');
    } catch (e) {
      print('Error starting challenge: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  Future<void> endCurrentChallenge() async {
    if (_isDisposed ||
        _partyId == null ||
        !isCurrentUserPartyLeader ||
        !hasActiveChallenge) return;

    setLoading(true);

    try {
      // 1. Archive current challenge in history
      await _repository.archiveChallengeHistory(_partyId!, {
        ..._activeChallenge!,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'status': 'completed'
      });

      // 2. Clear all challenge data from member goals
      for (String memberId in _members) {
        List<Goal> memberGoals = _partyMemberGoals[memberId] ?? [];
        if (memberGoals.isEmpty) continue;

        // Clear challenge data from each goal
        for (var goal in memberGoals) {
          goal.challenge = null;
        }

        // Update goals in database through GoalsProvider
        await _goalsProvider.updateUserGoals(memberId, memberGoals);
      }

      // 3. Remove active challenge from party
      await _repository.clearActiveChallenge(_partyId!);
    } catch (e) {
      print('Error ending challenge: $e');
    } finally {
      setLoading(false);
    }
  }
}
