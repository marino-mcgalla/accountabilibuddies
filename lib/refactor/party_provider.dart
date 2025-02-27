import 'dart:async';
import 'package:auth_test/refactor/goals_provider.dart';
import 'package:auth_test/refactor/time_machine_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'party_actions.dart';

class PartyProvider with ChangeNotifier {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? partyId;
  String? partyName;
  List<String> members = [];
  Map<String, Map<String, dynamic>> memberDetails = {};
  // New field to store goals for all party members
  Map<String, List<Goal>> _partyMemberGoals = {};
  bool isLoading = true;
  bool _isBatchingUpdates = false;
  bool _pendingNotification = false;
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController inviteController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? partySubscription;
  // List of subscriptions for each party member's goals
  List<StreamSubscription<DocumentSnapshot>?> _goalSubscriptions = [];

  String? get getPartyId => partyId;
  String? get getPartyName => partyName;
  List<String> get getMembers => members;
  Map<String, Map<String, dynamic>> get getMemberDetails => memberDetails;
  bool get getIsLoading => isLoading;
  // Getter for party member goals
  Map<String, List<Goal>> get partyMemberGoals => _partyMemberGoals;

  PartyProvider() {
    initializePartyState();
  }

  // Batched notification system to reduce UI rebuilds
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

  void initializePartyState() {
    isLoading = true;
    notifyListeners();

    String? currentUserId = auth.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      isLoading = false;
      notifyListeners();
      return; // Exit if there is no valid user ID
    }

    partySubscription?.cancel(); // Cancel any existing subscription
    partySubscription = firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists &&
          userDoc.data() != null &&
          (userDoc.data() as Map<String, dynamic>).containsKey('partyId')) {
        String partyId = (userDoc.data() as Map<String, dynamic>)['partyId'];
        firestore
            .collection('parties')
            .doc(partyId)
            .snapshots()
            .listen((partyDoc) {
          if (partyDoc.exists) {
            batchUpdates(() {
              this.partyId = partyId;
              this.partyName = partyDoc['partyName'];

              final List<String> newMembers =
                  List<String>.from(partyDoc['members']);
              final bool membersChanged =
                  !_areListsEqual(this.members, newMembers);
              this.members = newMembers;

              // Only refresh subscriptions if members list changed
              if (membersChanged) {
                // Clear old subscriptions
                _cancelGoalSubscriptions();

                // Initialize member goals map
                _partyMemberGoals = {};

                // Fetch member details and goals
                fetchMemberDetails();
                _subscribeToPartyMemberGoals();
              }

              isLoading = false;
            });
          } else {
            batchUpdates(() {
              this.partyId = null;
              this.partyName = null;
              this.members = [];
              this.memberDetails = {};
              _partyMemberGoals = {};
              _cancelGoalSubscriptions();
              isLoading = false;
            });
          }
        });
      } else {
        batchUpdates(() {
          this.partyId = null;
          this.partyName = null;
          this.members = [];
          this.memberDetails = {};
          _partyMemberGoals = {};
          _cancelGoalSubscriptions();
          isLoading = false;
        });
      }
    });
  }

  // Helper to compare lists for equality
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // Cancel all goal subscriptions
  void _cancelGoalSubscriptions() {
    for (var subscription in _goalSubscriptions) {
      subscription?.cancel();
    }
    _goalSubscriptions = [];
  }

  // Subscribe to goals for all party members with debouncing
  void _subscribeToPartyMemberGoals() {
    // Cache to track changes before notifying
    Map<String, List<Goal>> tempGoalsCache = {};

    for (String memberId in members) {
      var subscription = firestore
          .collection('userGoals')
          .doc(memberId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          List<dynamic> goalsData = doc.data()?['goals'] ?? [];
          final List<Goal> newGoals =
              goalsData.map((data) => Goal.fromMap(data)).toList();

          // Compare with previous data to avoid unnecessary updates
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

  // Check if goals have changed to avoid unnecessary updates
  bool _haveGoalsChanged(List<Goal> oldGoals, List<Goal> newGoals) {
    if (oldGoals.length != newGoals.length) return true;

    // Simple comparison - for more precision, compare individual fields
    for (int i = 0; i < oldGoals.length; i++) {
      if (oldGoals[i].id != newGoals[i].id) return true;

      // Compare completions map (this is where most updates happen)
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

  Future<void> fetchMemberDetails() async {
    Map<String, Map<String, dynamic>> newMemberDetails = {};

    for (String memberId in members) {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        newMemberDetails[memberId] = userDoc.data() as Map<String, dynamic>;
      }
    }

    // Only update if there are actual changes
    if (!_areMemberDetailsEqual(memberDetails, newMemberDetails)) {
      memberDetails = newMemberDetails;
      notifyListeners();
    }
  }

  bool _areMemberDetailsEqual(Map<String, Map<String, dynamic>> oldDetails,
      Map<String, Map<String, dynamic>> newDetails) {
    if (oldDetails.length != newDetails.length) return false;

    for (final key in oldDetails.keys) {
      if (!newDetails.containsKey(key)) return false;

      // Simplified comparison - for more precision, compare individual fields
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

  // Find a goal by ID across all party members
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

  // Find user ID who owns a specific goal
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

  void triggerNotifyListeners() {
    notifyListeners();
  }

  Future<List<Goal>> fetchGoalsForUser(String userId) async {
    // First check if we already have the goals in our state
    if (_partyMemberGoals.containsKey(userId)) {
      return _partyMemberGoals[userId] ?? [];
    }

    // Otherwise fetch from Firestore
    DocumentSnapshot userGoalsDoc =
        await firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      final data = userGoalsDoc.data();
      if (data != null && data is Map<String, dynamic>) {
        List<dynamic> goalsData = data['goals'] ?? [];
        return goalsData.map((goalData) => Goal.fromMap(goalData)).toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchSubmittedGoalsForParty(
      [BuildContext? context]) async {
    List<Map<String, dynamic>> submittedGoals = [];

    // Use the party member goals from state instead of fetching
    for (String memberId in _partyMemberGoals.keys) {
      List<Goal> goals = _partyMemberGoals[memberId] ?? [];
      for (Goal goal in goals) {
        if (goal is WeeklyGoal) {
          goal.currentWeekCompletions.forEach((day, status) {
            if (status == 'submitted') {
              submittedGoals.add({
                'goal': goal,
                'userId': memberId,
                'date': day,
              });
            }
          });
        } else if (goal is TotalGoal) {
          List<Map<String, dynamic>> proofs = goal.proofs;
          for (var proof in proofs) {
            submittedGoals.add({
              'goal': goal,
              'userId': memberId,
              'proof': proof,
            });
          }
        }
      }
    }
    return submittedGoals;
  }

  // Updated approve proof function with lifecycle safety
  Future<void> approveProof(String goalId, String? proofDate) async {
    // Find the goal owner
    String? userId = findGoalOwner(goalId);
    if (userId == null) {
      throw Exception("Goal owner not found");
    }

    // Find the goal
    Goal? goal = findGoalById(goalId);
    if (goal == null) {
      throw Exception("Goal not found");
    }

    // Use batching to avoid multiple notifications
    batchUpdates(() {
      // Update the goal based on the goal type
      if (goal is WeeklyGoal && proofDate != null) {
        goal.currentWeekCompletions[proofDate] = 'completed';
      } else if (goal is TotalGoal) {
        // Update for total goal
        if (goal.proofs.isNotEmpty) {
          goal.proofs.removeAt(0); // Remove the first proof

          // Increment completion count for today
          final day = DateTime.now().toIso8601String().split('T').first;
          goal.currentWeekCompletions[day] =
              (goal.currentWeekCompletions[day] ?? 0) + 1;
          goal.totalCompletions += 1;
        }
      }

      // Force an immediate notification to update the UI before Firestore
      _pendingNotification = false; // Clear any pending notification
    });

    // Force a notification to update all listeners immediately
    notifyListeners();

    // Update Firestore with the modified goals
    List<Map<String, dynamic>> goalsData =
        _partyMemberGoals[userId]?.map((goal) => goal.toMap()).toList() ?? [];

    // Firestore update
    try {
      await firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': goalsData});
    } catch (e) {
      // If the update fails, don't crash the UI
      print('Error updating Firestore: $e');
      // We won't rethrow the exception so the UI can continue functioning
    }
  }

  // Similarly, update deny proof function
  Future<void> denyProof(String goalId, String? proofDate) async {
    String? userId = findGoalOwner(goalId);
    if (userId == null) {
      throw Exception("Goal owner not found");
    }

    Goal? goal = findGoalById(goalId);
    if (goal == null) {
      throw Exception("Goal not found");
    }

    // Use batching to avoid multiple notifications
    batchUpdates(() {
      if (goal is WeeklyGoal && proofDate != null) {
        goal.currentWeekCompletions[proofDate] = 'denied';
      } else if (goal is TotalGoal) {
        if (goal.proofs.isNotEmpty) {
          goal.proofs.removeAt(0); // Remove the first proof
        }
      }

      // Force an immediate notification to update the UI before Firestore
      _pendingNotification = false; // Clear any pending notification
    });

    // Force a notification to update all listeners immediately
    notifyListeners();

    // Update Firestore with safety
    try {
      List<Map<String, dynamic>> goalsData =
          _partyMemberGoals[userId]?.map((goal) => goal.toMap()).toList() ?? [];

      await firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': goalsData});
    } catch (e) {
      // If the update fails, don't crash the UI
      print('Error updating Firestore: $e');
      // We won't rethrow the exception so the UI can continue functioning
    }
  }

  Future<void> endWeekForAll(BuildContext context) async {
    final timeMachineProvider =
        Provider.of<TimeMachineProvider>(context, listen: false);
    DateTime newWeekStartDate = timeMachineProvider.now;

    // Use batching for Firestore operations
    WriteBatch batch = firestore.batch();

    try {
      for (String memberId in members) {
        List<Goal> goals = _partyMemberGoals[memberId] ?? [];

        if (goals.isNotEmpty) {
          // Store current week's progress in history
          List<Map<String, dynamic>> goalsData =
              goals.map((goal) => goal.toMap()).toList();

          DocumentReference historyRef = firestore
              .collection('userGoalsHistory')
              .doc(memberId)
              .collection('weeks')
              .doc(timeMachineProvider.now.toString());

          batch.set(historyRef, {'goals': goalsData});

          // Reset goals for the new week
          for (Goal goal in goals) {
            goal.weekStartDate = newWeekStartDate;
            goal.currentWeekCompletions = {}; // Reset completions
          }

          // Update goals in Firestore
          List<Map<String, dynamic>> updatedGoalsData =
              goals.map((goal) => goal.toMap()).toList();

          DocumentReference goalsRef =
              firestore.collection('userGoals').doc(memberId);

          batch.set(goalsRef, {'goals': updatedGoalsData});
        }
      }

      // Commit all operations at once
      await batch.commit();
      // The subscription will handle state updates
    } catch (e) {
      print('Error ending week: $e');
      // Notify listeners to update UI with the changes we did make
      notifyListeners();
    }
  }

  void resetState() {
    batchUpdates(() {
      partyId = null;
      partyName = null;
      members = [];
      memberDetails = {};
      _partyMemberGoals = {};
      isLoading = false;
      _cancelGoalSubscriptions();
    });
  }

  @override
  void dispose() {
    partySubscription?.cancel();
    _cancelGoalSubscriptions();
    super.dispose();
  }
}
