import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';

class GoalsProvider with ChangeNotifier {
  List<Goal> _goals = [];
  bool _isLoading = false;
  StreamSubscription<DocumentSnapshot>? _goalsSubscription;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;

  GoalsProvider() {
    initializeGoalsListener();
  }

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
      final day = DateTime.now().toIso8601String().split('T').first;
      goal.currentWeekCompletions[day] =
          (goal.currentWeekCompletions[day] ?? 0) + 1;
      await _updateGoalsInFirestore();
      notifyListeners();
    }
  }

  // updates the completion status for weekly goals
  Future<void> toggleCompletion(
      String goalId, String day, String status) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is WeeklyGoal) {
      final goal = _goals[index] as WeeklyGoal;
      goal.currentWeekCompletions[day] = status;
      await _updateGoalsInFirestore();
      notifyListeners();
    }
  }

  Future<void> endWeek() async {
    print('howdy');
    _setLoading(true);

    // Store current week's progress in history
    await _storeWeeklyProgressInHistory();

    // Reset goals for the new week
    DateTime newWeekStartDate = DateTime.now();
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
        .doc(DateTime.now().toIso8601String())
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
