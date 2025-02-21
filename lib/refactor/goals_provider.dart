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
  late StreamSubscription<DocumentSnapshot> _goalsSubscription;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;

  GoalsProvider() {
    _initializeGoalsListener();
  }

  void _initializeGoalsListener() {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
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

  @override
  void dispose() {
    _goalsSubscription.cancel();
    super.dispose();
  }

  Future<void> addGoal(Goal goal) async {
    _setLoading(true);
    _goals.add(goal);
    await _updateGoalsInFirestore();
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

  Future<void> incrementCompletions(String goalId) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is TotalGoal) {
      (_goals[index] as TotalGoal).completions++;
      await _updateGoalsInFirestore();
      notifyListeners();
    }
  }

  Future<void> toggleCompletion(
      String goalId, String day, bool isCompleted) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is WeeklyGoal) {
      (_goals[index] as WeeklyGoal).completions[day] = isCompleted;
      await _updateGoalsInFirestore();
      notifyListeners();
    }
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
