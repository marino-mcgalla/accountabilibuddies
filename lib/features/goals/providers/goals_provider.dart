import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import '../repositories/goals_repository.dart';
import '../services/goal_management_service.dart';
import '../services/proof_service.dart';
import '../../time_machine/providers/time_machine_provider.dart';

class GoalsProvider with ChangeNotifier {
  final GoalsRepository _repository = GoalsRepository();
  late GoalManagementService _goalService;
  late ProofService _proofService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TimeMachineProvider _timeMachineProvider;

  List<Goal> _goals = [];
  bool _isLoading = false;
  StreamSubscription<List<Goal>>? _goalsSubscription;

  GoalsProvider(this._timeMachineProvider) {
    _initializeServices();
    initializeGoalsListener();
  }

  void _initializeServices() {
    _goalService = GoalManagementService(_repository);
    _proofService = ProofService(_repository, _timeMachineProvider);
  }

  void updateTimeMachineProvider(TimeMachineProvider timeMachineProvider) {
    _timeMachineProvider = timeMachineProvider;
    _initializeServices();
  }

  // Getters
  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;

  void initializeGoalsListener() {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    _goalsSubscription?.cancel();
    _goalsSubscription = _repository.getGoalsStream(userId).listen((goals) {
      _goals = goals;
      notifyListeners();
    });
  }

  // Goal CRUD Operations
  Future<void> addGoal(Goal goal) async {
    _setLoading(true);
    await _goalService.addGoal(_goals, goal);
    _setLoading(false);
  }

  Future<void> editGoal(Goal updatedGoal) async {
    _setLoading(true);
    await _goalService.editGoal(_goals, updatedGoal);
    _setLoading(false);
  }

  Future<void> toggleGoalActive(String goalId) async {
    _setLoading(true);
    try {
      final index = _goals.indexWhere((goal) => goal.id == goalId);
      if (index != -1) {
        // Pass the goal and the desired state to a targeted method
        await _goalService.updateGoalActiveStatus(
            goalId, !_goals[index].active);
        // State will update via the stream listener
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeGoal(BuildContext context, String goalId) async {
    _setLoading(true);
    await _goalService.removeGoal(_goals, goalId);
    _setLoading(false);
  }

  // Goal Progress Operations
  Future<void> incrementCompletions(String goalId) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is TotalGoal) {
      final updatedGoals = List<Goal>.from(_goals);
      final goal = updatedGoals[index] as TotalGoal;
      final day = _timeMachineProvider.now.toIso8601String().split('T').first;
      goal.currentWeekCompletions[day] =
          (goal.currentWeekCompletions[day] ?? 0) + 1;
      goal.totalCompletions += 1;
      String? userId = _repository.getCurrentUserId();
      if (userId != null) {
        await _repository.saveGoals(userId, updatedGoals);
      }
    }
  }

  Future<void> toggleSkipPlan(String goalId, String day, String status) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is WeeklyGoal) {
      final updatedGoals = List<Goal>.from(_goals);
      final goal = updatedGoals[index] as WeeklyGoal;
      goal.currentWeekCompletions[day] = status;
      String? userId = _repository.getCurrentUserId();
      if (userId != null) {
        await _repository.saveGoals(userId, updatedGoals);
      }
    }
  }

  // Proof Management
  Future<void> submitProof(
      String goalId, String proofText, String? imageUrl, yesterday) async {
    await _proofService.submitProof(
        _goals, goalId, proofText, imageUrl, yesterday);
    notifyListeners();
  }

  Future<void> approveProof(
      String goalId, String userId, String? proofDate) async {
    await _proofService.approveProof(goalId, userId, proofDate);
  }

  Future<void> denyProof(
      String goalId, String userId, String? proofDate) async {
    await _proofService.denyProof(goalId, userId, proofDate);
  }

  Future<void> lockInActiveGoals() async {
    _setLoading(true);
    try {
      final activeGoals = _goals.where((goal) => goal.active).toList();
      if (activeGoals.isEmpty) return;

      String? userId = _repository.getCurrentUserId();
      if (userId != null) {
        // Create locked copies of active goals
        List<Map<String, dynamic>> lockedGoals = activeGoals.map((goal) {
          final goalMap = goal.toMap();
          goalMap['lockedInId'] = 'locked_${goalMap['id']}';
          goalMap['originalGoalId'] = goalMap['id'];
          goalMap['lockedInDate'] = _timeMachineProvider.now.toIso8601String();
          goalMap['lockedInVersion'] = true;
          goalMap['currentWeekCompletions'] = {};
          return goalMap;
        }).toList();

        await _firestore.collection('userGoals').doc(userId).update({
          'currentChallengeGoals': {
            'goals': lockedGoals,
            'lockedInDate': _timeMachineProvider.now.toIso8601String()
          }
        });
      }
    } finally {
      _setLoading(false);
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
