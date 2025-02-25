import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'time_machine_provider.dart';

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

  void initializeGoalsListener() {
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
      print("firestore read: goals updated");
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
      goal.currentWeekCompletions = {}; // Reset completions
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

  Future<void> submitProof(String goalId, String proofText) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(currentUserId).get();

    if (userGoalsDoc.exists) {
      List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
      for (var goalData in goalsData) {
        if (goalData['id'] == goalId) {
          if (goalData['goalType'] == 'weekly') {
            String currentDay =
                _timeMachineProvider.now.toIso8601String().split('T').first;
            goalData['currentWeekCompletions'][currentDay] = 'submitted';
          } else {
            goalData['proofText'] = proofText;
            goalData['proofStatus'] = 'submitted';
            goalData['proofSubmissionDate'] =
                _timeMachineProvider.now.toIso8601String();
          }
          break;
        }
      }
      await _firestore
          .collection('userGoals')
          .doc(currentUserId)
          .update({'goals': goalsData});

      // Update local goals list
      Goal goal = _goals.firstWhere((goal) => goal.id == goalId);
      if (goal is WeeklyGoal) {
        String currentDay =
            _timeMachineProvider.now.toIso8601String().split('T').first;
        goal.currentWeekCompletions[currentDay] = 'submitted';
      } else {
        goal.proofText = proofText;
        goal.proofStatus = 'submitted';
        goal.proofSubmissionDate = _timeMachineProvider.now;
      }

      notifyListeners();
    } else {
      throw Exception("User goals document does not exist");
    }
  }

  Future<void> approveProof(
      String goalId, String userId, String? proofDate) async {
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
      for (var goalData in goalsData) {
        if (goalData['id'] == goalId) {
          if (goalData['goalType'] == 'weekly') {
            if (proofDate != null) {
              goalData['currentWeekCompletions'][proofDate] = 'completed';
            }
          } else if (goalData['goalType'] == 'total') {
            goalData['proofStatus'] = 'completed';
            print("Before increment:");
            print("goalData: $goalData");
            print(
                "currentWeekCompletions: ${goalData['currentWeekCompletions']}");
            print("totalCompletions: ${goalData['totalCompletions']}");
            final day =
                _timeMachineProvider.now.toIso8601String().split('T').first;
            goalData['currentWeekCompletions'][day] =
                (goalData['currentWeekCompletions'][day] ?? 0) + 1;
            goalData['totalCompletions'] =
                (goalData['totalCompletions'] ?? 0) + 1;
            print("After increment:");
            print("goalData: $goalData");
            print(
                "currentWeekCompletions: ${goalData['currentWeekCompletions']}");
            print("totalCompletions: ${goalData['totalCompletions']}");
          }
          break;
        }
      }
      await _firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': goalsData});

      // Update local goals list
      try {
        Goal goal = _goals.firstWhere((goal) => goal.id == goalId);
        if (goal is WeeklyGoal) {
          if (proofDate != null) {
            goal.currentWeekCompletions[proofDate] = 'completed';
          }
        } else if (goal is TotalGoal) {
          goal.proofStatus = 'completed'; //not necessary
          final day =
              _timeMachineProvider.now.toIso8601String().split('T').first;
          goal.currentWeekCompletions[day] =
              (goal.currentWeekCompletions[day] ?? 0) + 1;
          goal.totalCompletions += 1;
        }
      } catch (e) {
        // Goal not found, do nothing
      }

      notifyListeners();
    } else {
      throw Exception("User goals document does not exist");
    }
  }

  Future<void> denyProof(
      String goalId, String userId, String? proofDate) async {
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
      for (var goalData in goalsData) {
        if (goalData['id'] == goalId) {
          if (goalData['goalType'] == 'weekly') {
            if (proofDate != null) {
              goalData['currentWeekCompletions'][proofDate] = 'denied';
            }
          } else if (goalData['goalType'] == 'total') {
            goalData['proofStatus'] = 'denied';
          }
          break;
        }
      }
      await _firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': goalsData});

      // Update local goals list
      try {
        Goal goal = _goals.firstWhere((goal) => goal.id == goalId);
        if (goal is WeeklyGoal) {
          if (proofDate != null) {
            goal.currentWeekCompletions[proofDate] = 'denied';
          }
        } else if (goal is TotalGoal) {
          goal.proofStatus = 'denied';
        }
      } catch (e) {
        // Goal not found, do nothing
      }

      notifyListeners();
    } else {
      throw Exception("User goals document does not exist");
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
