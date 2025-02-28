import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import '../models/proof_model.dart'; // Import our new Proof model
import '../../time_machine/providers/time_machine_provider.dart';

class GoalsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TimeMachineProvider _timeMachineProvider;

  GoalsProvider(this._timeMachineProvider) {
    initializeGoalsListener();
  }

  void updateTimeMachineProvider(TimeMachineProvider timeMachineProvider) {
    _timeMachineProvider = timeMachineProvider;
  }

  List<Goal> _goals = [];
  bool _isLoading = false;
  StreamSubscription<DocumentSnapshot>? _goalsSubscription;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;

  initializeGoalsListener() {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      return; // Exit if there is no valid user ID
    }

    _goalsSubscription?.cancel(); // Cancel any existing subscription
    _goalsSubscription = FirebaseFirestore.instance
        .collection('userGoals')
        .doc(currentUserId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        List<dynamic> goalsData = doc.data()?['goals'] ?? [];
        _goals = goalsData.map((data) => Goal.fromMap(data)).toList();
        notifyListeners();
      }
    });
  }

  Future<void> addGoal(Goal goal) async {
    _setLoading(true);
    _goals.add(goal);
    await _updateGoalsInFirestore();
    _setLoading(false);
    notifyListeners();
  }

  Future<void> editGoal(Goal updatedGoal) async {
    _setLoading(true);
    int index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      await _updateGoalsInFirestore();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> removeGoal(BuildContext context, String goalId) async {
    _setLoading(true);
    _goals.removeWhere((goal) => goal.id == goalId);
    await _updateGoalsInFirestore();
    _setLoading(false);
    notifyListeners();
  }

  // adds 1 for total goals
  Future<void> incrementCompletions(String goalId) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is TotalGoal) {
      final goal = _goals[index] as TotalGoal;
      final day = _timeMachineProvider.now.toIso8601String().split('T').first;
      goal.currentWeekCompletions[day] =
          (goal.currentWeekCompletions[day] ?? 0) + 1;
      goal.totalCompletions += 1;
      await _updateGoalsInFirestore();
      notifyListeners();
    }
  }

  // updates the completion status for weekly goals
  Future<void> toggleSkipPlan(String goalId, String day, String status) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is WeeklyGoal) {
      final goal = _goals[index] as WeeklyGoal;
      goal.currentWeekCompletions[day] = status;
      await _updateGoalsInFirestore();
      notifyListeners();
    }
  }

  Future<void> endWeek() async {
    _setLoading(true);

    // Store current week's progress in history
    await _storeWeeklyProgressInHistory();

    // Reset goals for the new week
    DateTime newWeekStartDate = _timeMachineProvider.now;
    for (Goal goal in _goals) {
      goal.weekStartDate = newWeekStartDate;

      if (goal is WeeklyGoal) {
        goal.currentWeekCompletions = {}; // Reset weekly completions
      } else if (goal is TotalGoal) {
        goal.currentWeekCompletions = {}; // Reset weekly counts
        // Note: we don't reset totalCompletions as it's a running total
      }
    }

    await _updateGoalsInFirestore();
    _setLoading(false);
    notifyListeners();
  }

  Future<void> _storeWeeklyProgressInHistory() async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    List<Map<String, dynamic>> goalsData =
        _goals.map((goal) => goal.toMap()).toList();
    await FirebaseFirestore.instance
        .collection('userGoalsHistory')
        .doc(currentUserId)
        .collection('weeks')
        .doc(_timeMachineProvider.now.toIso8601String())
        .set({'goals': goalsData});
  }

  Future<void> _updateGoalsInFirestore() async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    List<Map<String, dynamic>> goalsData =
        _goals.map((goal) => goal.toMap()).toList();
    await FirebaseFirestore.instance
        .collection('userGoals')
        .doc(currentUserId)
        .set({'goals': goalsData});
  }

  // Updated to use the new Proof model
  Future<void> submitProof(String goalId, String proofText) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Find goal in local state
    int goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) {
      throw Exception("Goal not found");
    }

    Goal goal = _goals[goalIndex];
    DateTime submissionDate = _timeMachineProvider.now;

    // Create the proof object
    Proof proof = Proof(
      proofText: proofText,
      submissionDate: submissionDate,
      status: 'pending',
    );

    // Update based on goal type
    if (goal is WeeklyGoal) {
      String currentDay = submissionDate.toIso8601String().split('T').first;
      goal.currentWeekCompletions[currentDay] = 'submitted';
    } else if (goal is TotalGoal) {
      goal.proofs.add(proof);
    }

    // Update in Firestore
    await _updateGoalsInFirestore();
    notifyListeners();
  }

  // Updated to use the new Proof model
  Future<void> approveProof(
      String goalId, String userId, String? proofDate) async {
    // Find the goal in local state first
    int goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) {
      // If not in local state, try to fetch from Firestore
      DocumentSnapshot userGoalsDoc =
          await _firestore.collection('userGoals').doc(userId).get();
      if (!userGoalsDoc.exists) {
        throw Exception("User goals document does not exist");
      }

      List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
      List<Goal> userGoals =
          goalsData.map((data) => Goal.fromMap(data)).toList();
      goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);

      if (goalIndex == -1) {
        throw Exception("Goal not found");
      }

      // Update the goal based on type
      Goal goal = userGoals[goalIndex];

      if (goal is WeeklyGoal && proofDate != null) {
        goal.currentWeekCompletions[proofDate] = 'completed';
      } else if (goal is TotalGoal) {
        final day = _timeMachineProvider.now.toIso8601String().split('T').first;
        goal.currentWeekCompletions[day] =
            (goal.currentWeekCompletions[day] ?? 0) + 1;
        goal.totalCompletions += 1;
        if (goal.proofs.isNotEmpty) {
          goal.proofs.removeAt(0); // Remove the first (oldest) proof
        }
      }

      // Update in Firestore
      List<Map<String, dynamic>> updatedGoalsData =
          userGoals.map((goal) => goal.toMap()).toList();
      await _firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': updatedGoalsData});

      // If we're approving our own goals, update local state
      if (userId == FirebaseAuth.instance.currentUser?.uid) {
        _goals = userGoals;
        notifyListeners();
      }
    } else {
      // Goal is in our local state
      Goal goal = _goals[goalIndex];

      if (goal is WeeklyGoal && proofDate != null) {
        goal.currentWeekCompletions[proofDate] = 'completed';
      } else if (goal is TotalGoal) {
        final day = _timeMachineProvider.now.toIso8601String().split('T').first;
        goal.currentWeekCompletions[day] =
            (goal.currentWeekCompletions[day] ?? 0) + 1;
        goal.totalCompletions += 1;
        if (goal.proofs.isNotEmpty) {
          goal.proofs.removeAt(0); // Remove the first proof
        }
      }

      // Update in Firestore
      await _updateGoalsInFirestore();
      notifyListeners();
    }
  }

  // Updated to use the new Proof model
  Future<void> denyProof(
      String goalId, String userId, String? proofDate) async {
    // Similar approach to approveProof, but marking as denied
    int goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) {
      // If not in local state, try to fetch from Firestore
      DocumentSnapshot userGoalsDoc =
          await _firestore.collection('userGoals').doc(userId).get();
      if (!userGoalsDoc.exists) {
        throw Exception("User goals document does not exist");
      }

      List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
      List<Goal> userGoals =
          goalsData.map((data) => Goal.fromMap(data)).toList();
      goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);

      if (goalIndex == -1) {
        throw Exception("Goal not found");
      }

      // Update the goal based on type
      Goal goal = userGoals[goalIndex];

      if (goal is WeeklyGoal && proofDate != null) {
        goal.currentWeekCompletions[proofDate] = 'denied';
      } else if (goal is TotalGoal) {
        if (goal.proofs.isNotEmpty) {
          goal.proofs
              .removeAt(0); // Remove the first proof without incrementing
        }
      }

      // Update in Firestore
      List<Map<String, dynamic>> updatedGoalsData =
          userGoals.map((goal) => goal.toMap()).toList();
      await _firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': updatedGoalsData});

      // If we're denying our own goals, update local state
      if (userId == FirebaseAuth.instance.currentUser?.uid) {
        _goals = userGoals;
        notifyListeners();
      }
    } else {
      // Goal is in our local state
      Goal goal = _goals[goalIndex];

      if (goal is WeeklyGoal && proofDate != null) {
        goal.currentWeekCompletions[proofDate] = 'denied';
      } else if (goal is TotalGoal) {
        if (goal.proofs.isNotEmpty) {
          goal.proofs.removeAt(0); // Remove the first proof
        }
      }

      // Update in Firestore
      await _updateGoalsInFirestore();
      notifyListeners();
    }
  }

  void resetState() {
    _goals = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
