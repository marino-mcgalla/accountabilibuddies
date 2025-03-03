import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../goals/models/goal_model.dart';
import '../services/party_members_service.dart';
import '../services/party_goals_service.dart';
import '../../time_machine/providers/time_machine_provider.dart';

class PartyProvider with ChangeNotifier {
  // Services
  final PartyMembersService _membersService;
  final PartyGoalsService _goalsService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

  // Subscription management
  StreamSubscription<DocumentSnapshot>? _partySubscription;
  List<StreamSubscription<DocumentSnapshot>?> _goalSubscriptions = [];

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

  PartyProvider({
    PartyMembersService? membersService,
    PartyGoalsService? goalsService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _membersService = membersService ?? PartyMembersService(),
        _goalsService = goalsService ?? PartyGoalsService(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    initializePartyState();
  }

  // Initialize party state
  void initializePartyState() {
    if (_isDisposed) return; // Skip if already disposed

    setLoading(true);

    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      setLoading(false);
      return;
    }

    _partySubscription?.cancel();
    _partySubscription = _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((userDoc) {
      if (_isDisposed) return; // Skip processing if disposed

      if (userDoc.exists &&
          userDoc.data() != null &&
          (userDoc.data() as Map<String, dynamic>).containsKey('partyId')) {
        String partyId = (userDoc.data() as Map<String, dynamic>)['partyId'];
        _firestore
            .collection('parties')
            .doc(partyId)
            .snapshots()
            .listen((partyDoc) {
          if (_isDisposed) return; // Skip processing if disposed

          if (partyDoc.exists) {
            batchUpdates(() {
              _partyId = partyId;
              _partyName = partyDoc['partyName'];
              _partyLeaderId = partyDoc['partyOwner'];

              final List<String> newMembers =
                  List<String>.from(partyDoc['members']);
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
          } else {
            _resetState();
          }
        });
      } else {
        _resetState();
      }
    });
  }

  // Create a new party
  Future<void> createParty(String partyName) async {
    if (_isDisposed) return; // Skip if already disposed
    if (partyName.isEmpty) return;

    setLoading(true);

    try {
      String currentUserId = _auth.currentUser?.uid ?? "";

      DocumentReference partyRef = await _firestore.collection('parties').add({
        'createdBy': currentUserId,
        'partyOwner': currentUserId,
        'members': [currentUserId],
        'partyName': partyName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      String partyId = partyRef.id;

      await _firestore.collection('users').doc(currentUserId).update({
        'partyId': partyId,
      });

      if (!_isDisposed) {
        batchUpdates(() {
          _partyId = partyId;
          _partyName = partyName;
          _members = [currentUserId];
          fetchMemberDetails();
        });
      }
    } catch (e) {
      // Handle error
      print('Error creating party: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
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
      // Update the party document
      await _firestore.collection('parties').doc(_partyId).update({
        'partyOwner': newLeaderId,
      });

      // Local state will be updated through the stream listener
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
      // Remove from party members list
      List<String> updatedMembers = List<String>.from(_members);
      updatedMembers.remove(memberId);

      await _firestore.collection('parties').doc(_partyId).update({
        'members': updatedMembers,
      });

      // Remove party ID from user's document
      await _firestore.collection('users').doc(memberId).update({
        'partyId': FieldValue.delete(),
      });

      // Local state will be updated through stream listeners
    } catch (e) {
      print('Error removing member: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  // Leave a party
  Future<void> leaveParty() async {
    if (_isDisposed) return; // Skip if already disposed
    if (_partyId == null) return;

    setLoading(true);

    try {
      if (_members.length <= 1) {
        await closeParty();
      } else {
        await _membersService.leaveParty(_partyId!);
        _resetState();
      }
    } catch (e) {
      print('Error leaving party: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  // Close an entire party
  Future<void> closeParty() async {
    if (_isDisposed) return; // Skip if already disposed
    if (_partyId == null) return;
    if (!isCurrentUserPartyLeader) return; // Only leader can close party

    setLoading(true);

    try {
      await _membersService.closeParty(_partyId!, _members);
      _resetState();
    } catch (e) {
      print('Error closing party: $e');
    } finally {
      if (!_isDisposed) {
        setLoading(false);
      }
    }
  }

  // Send an invite to join the party
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

  // Fetch submitted goals for party
  Future<List<Map<String, dynamic>>> fetchSubmittedGoalsForParty(
      [BuildContext? context]) async {
    if (_isDisposed) return []; // Skip if already disposed

    try {
      return await _goalsService.fetchSubmittedGoalsForParty(_members);
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

  // Approve proof
  Future<void> approveProof(String goalId, String? proofDate) async {
    if (_isDisposed) return; // Skip if already disposed

    String? userId = findGoalOwner(goalId);
    if (userId == null) {
      throw Exception("Goal owner not found");
    }

    try {
      await _goalsService.approveProof(goalId, userId, proofDate);
    } catch (e) {
      print('Error approving proof: $e');
      rethrow;
    }
  }

  // Deny proof
  Future<void> denyProof(String goalId, String? proofDate) async {
    if (_isDisposed) return; // Skip if already disposed

    String? userId = findGoalOwner(goalId);
    if (userId == null) {
      throw Exception("Goal owner not found");
    }

    try {
      await _goalsService.denyProof(goalId, userId, proofDate);
    } catch (e) {
      print('Error denying proof: $e');
      rethrow;
    }
  }

  // End week for all members
  Future<void> endWeekForAll(BuildContext context) async {
    if (_isDisposed) return; // Skip if already disposed
    if (_members.isEmpty) return;
    if (!isCurrentUserPartyLeader) return; // Only leader can end week

    try {
      final timeMachineProvider =
          Provider.of<TimeMachineProvider>(context, listen: false);
      await _goalsService.endWeekForParty(_members, timeMachineProvider.now);
    } catch (e) {
      print('Error ending week: $e');
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

  // Subscribe to party member goals
  void _subscribeToPartyMemberGoals() {
    if (_isDisposed) return; // Skip if already disposed

    for (String memberId in _members) {
      var subscription = _firestore
          .collection('userGoals')
          .doc(memberId)
          .snapshots()
          .listen((doc) {
        if (_isDisposed) return; // Skip processing if disposed

        if (doc.exists) {
          List<dynamic> goalsData = doc.data()?['goals'] ?? [];
          final List<Goal> newGoals =
              goalsData.map((data) => Goal.fromMap(data)).toList();

          final List<Goal> previousGoals = _partyMemberGoals[memberId] ?? [];
          final bool hasChanges = _haveGoalsChanged(previousGoals, newGoals);

          if (hasChanges) {
            batchUpdates(() {
              _partyMemberGoals[memberId] = newGoals;
            });
          }
        } else {
          if (_partyMemberGoals[memberId]?.isNotEmpty ?? false) {
            batchUpdates(() {
              _partyMemberGoals[memberId] = [];
            });
          }
        }
      });
      _goalSubscriptions.add(subscription);
    }
  }

  // Check if goals have changed
  bool _haveGoalsChanged(List<Goal> oldGoals, List<Goal> newGoals) {
    if (oldGoals.length != newGoals.length) return true;

    for (int i = 0; i < oldGoals.length; i++) {
      if (oldGoals[i].id != newGoals[i].id) return true;

      final oldCompletions = oldGoals[i].currentWeekCompletions;
      final newCompletions = newGoals[i].currentWeekCompletions;

      if (oldCompletions.length != newCompletions.length) return true;

      for (final key in oldCompletions.keys) {
        if (!newCompletions.containsKey(key) ||
            oldCompletions[key].toString() != newCompletions[key].toString()) {
          return true;
        }
      }
    }
    return false;
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
}
