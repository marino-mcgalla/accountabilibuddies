import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'goal_model.dart';
import 'party_members_service.dart';
import 'party_goals_service.dart';
import 'time_machine_provider.dart';

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
  List<String> _members = [];
  Map<String, Map<String, dynamic>> _memberDetails = {};
  Map<String, List<Goal>> _partyMemberGoals = {};
  bool _isLoading = true;

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
      if (userDoc.exists &&
          userDoc.data() != null &&
          (userDoc.data() as Map<String, dynamic>).containsKey('partyId')) {
        String partyId = (userDoc.data() as Map<String, dynamic>)['partyId'];
        _firestore
            .collection('parties')
            .doc(partyId)
            .snapshots()
            .listen((partyDoc) {
          if (partyDoc.exists) {
            batchUpdates(() {
              _partyId = partyId;
              _partyName = partyDoc['partyName'];

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

      batchUpdates(() {
        _partyId = partyId;
        _partyName = partyName;
        _members = [currentUserId];
        fetchMemberDetails();
      });
    } catch (e) {
      // Handle error
      print('Error creating party: $e');
    } finally {
      setLoading(false);
    }
  }

  // Leave a party
  Future<void> leaveParty() async {
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
      setLoading(false);
    }
  }

  // Close an entire party
  Future<void> closeParty() async {
    if (_partyId == null) return;

    setLoading(true);

    try {
      await _membersService.closeParty(_partyId!, _members);
      _resetState();
    } catch (e) {
      print('Error closing party: $e');
    } finally {
      setLoading(false);
    }
  }

  // Send an invite to join the party
  Future<void> sendInvite() async {
    if (_partyId == null || inviteController.text.isEmpty) return;

    try {
      bool success =
          await _membersService.sendInvite(inviteController.text, _partyId!);
      if (success) {
        inviteController.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error sending invite: $e');
    }
  }

  // Accept an invite to join a party
  Future<void> acceptInvite(String inviteId, String partyId) async {
    try {
      await _membersService.acceptInvite(inviteId, partyId);
      // The party subscription will handle state updates
    } catch (e) {
      print('Error accepting invite: $e');
    }
  }

  // Cancel a pending invite
  Future<void> cancelInvite(String inviteId) async {
    try {
      await _membersService.cancelInvite(inviteId);
      notifyListeners();
    } catch (e) {
      print('Error canceling invite: $e');
    }
  }

  // Fetch member details
  Future<void> fetchMemberDetails() async {
    try {
      Map<String, Map<String, dynamic>> newMemberDetails =
          await _membersService.fetchMemberDetails(_members);

      if (!_areMemberDetailsEqual(_memberDetails, newMemberDetails)) {
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
    if (_members.isEmpty) return;

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
    for (String memberId in _members) {
      var subscription = _firestore
          .collection('userGoals')
          .doc(memberId)
          .snapshots()
          .listen((doc) {
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
    _partySubscription?.cancel();
    _resetState();
  }

  // Set loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Batch updates to reduce UI rebuilds
  void batchUpdates(Function callback) {
    _isBatchingUpdates = true;
    callback();
    _isBatchingUpdates = false;

    if (_pendingNotification) {
      _pendingNotification = false;
      notifyListeners();
    }
  }

  // Override notifyListeners to support batching
  @override
  void notifyListeners() {
    if (_isBatchingUpdates) {
      _pendingNotification = true;
    } else {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _partySubscription?.cancel();
    _cancelGoalSubscriptions();
    partyNameController.dispose();
    inviteController.dispose();
    super.dispose();
  }
}
