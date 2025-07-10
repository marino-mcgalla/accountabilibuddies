import 'dart:async';
import 'package:flutter/material.dart';
import '../actions/goals_actions.dart';
import '../actions/proof_actions.dart';
import '../models/goal_model.dart';
import '../state/goals_state.dart';
import '../streams/goals_stream_manager.dart';

class GoalsProvider with ChangeNotifier {
  // Dependencies
  final GoalsActions _actions;
  final ProofActions _proofActions;
  final GoalsStreamManager _streamManager;

  // State
  GoalsState _state = const GoalsState();
  bool _isDisposed = false;

  // Subscriptions
  StreamSubscription<GoalsState>? _goalsSubscription;

  GoalsProvider({
    GoalsActions? actions,
    ProofActions? proofActions,
    GoalsStreamManager? streamManager,
  })  : _actions = actions ?? GoalsActions(),
        _proofActions = proofActions ?? ProofActions(),
        _streamManager = streamManager ?? GoalsStreamManager() {
    _initializeStreams();
  }

  // Getters
  GoalsState get state => _state;
  List<Goal> get goals => _state.goals;
  bool get isLoading => _state.isLoading;
  List<Goal> get activeGoals => _state.activeGoals;
  bool get hasActiveGoals => _state.hasActiveGoals;
  int get totalActiveGoals => _state.totalActiveGoals;

  Goal? getGoalById(String id) => _state.getGoalById(id);
  List<Goal> getGoalsByType(String type) => _state.getGoalsByType(type);

  void _initializeStreams() {
    if (_isDisposed) return;

    _goalsSubscription = _streamManager.getGoalsStateStream().listen((newState) {
      if (_isDisposed) return;
      _state = newState;
      notifyListeners();
    });
  }

  // Goal CRUD Actions
  Future<bool> createGoal(Goal goal) async {
    if (_isDisposed) return false;
    
    _setLoading(true);
    final success = await _actions.createGoal(_state.goals, goal);
    _setLoading(false);
    
    return success;
  }

  Future<bool> editGoal(Goal updatedGoal) async {
    if (_isDisposed) return false;
    
    _setLoading(true);
    final success = await _actions.editGoal(_state.goals, updatedGoal);
    _setLoading(false);
    
    return success;
  }

  Future<bool> removeGoal(String goalId) async {
    if (_isDisposed) return false;
    
    _setLoading(true);
    final success = await _actions.removeGoal(_state.goals, goalId);
    _setLoading(false);
    
    return success;
  }

  Future<bool> toggleGoalActive(String goalId) async {
    if (_isDisposed) return false;
    
    _setLoading(true);
    final success = await _actions.toggleGoalActive(_state.goals, goalId);
    _setLoading(false);
    
    return success;
  }

  Future<bool> toggleSkipPlan(String goalId, String day, String status) async {
    if (_isDisposed) return false;
    
    return await _actions.toggleSkipPlan(_state.goals, goalId, day, status);
  }

  // Proof Actions
  Future<bool> submitProof(String goalId, String proofText, String? imageUrl, dynamic submissionDate) async {
    if (_isDisposed) return false;
    
    // Handle both DateTime and bool parameters for backward compatibility
    DateTime date;
    if (submissionDate is bool) {
      // Convert bool to DateTime (true = yesterday, false = today)
      date = submissionDate 
          ? DateTime.now().subtract(Duration(days: 1))
          : DateTime.now();
    } else if (submissionDate is DateTime) {
      date = submissionDate;
    } else {
      date = DateTime.now(); // Default to today
    }
    
    return await _proofActions.submitProof(_state.goals, goalId, proofText, imageUrl, date);
  }

  Future<bool> approveProof(String userId, String goalId, String? proofDate, {List<Goal>? existingGoals}) async {
    if (_isDisposed) return false;
    
    _setLoading(true);
    final success = await _proofActions.approveProof(userId, goalId, proofDate, existingGoals: existingGoals);
    _setLoading(false);
    
    return success;
  }

  Future<bool> denyProof(String userId, String goalId, String? proofDate, {List<Goal>? existingGoals}) async {
    if (_isDisposed) return false;
    
    _setLoading(true);
    final success = await _proofActions.denyProof(userId, goalId, proofDate, existingGoals: existingGoals);
    _setLoading(false);
    
    return success;
  }

  // Essential missing methods for compatibility  
  Future<void> initializeGoalsListener() async {} // Stub - streams auto-initialize
  Future<void> showLockInDialogAndLockGoals(BuildContext context, String? partyId) async {} // Stub
  
  // Note: Goals auto-refresh via Firestore streams
  // This method is kept for compatibility but does nothing
  Future<void> refreshGoals() async {
    // Firestore streams automatically update - no manual refresh needed
    return;
  }
  
  // Override removeGoal to handle the old signature with BuildContext
  Future<void> removeGoalWithContext(BuildContext context, String goalId) async {
    await removeGoal(goalId);
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _state = _state.copyWith(isLoading: loading);
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _goalsSubscription?.cancel();
    _streamManager.dispose();
    super.dispose();
  }
}