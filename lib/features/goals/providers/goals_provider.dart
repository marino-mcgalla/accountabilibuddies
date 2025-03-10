import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth;

  TimeMachineProvider _timeMachineProvider;

  List<Goal> _goals = [];
  bool _isLoading = false;
  StreamSubscription<List<Goal>>? _goalsSubscription;

  GoalsProvider(
    this._timeMachineProvider, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance {
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

  initializeGoalsListener() {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    _goalsSubscription?.cancel();
    _goalsSubscription = _repository.getGoalsStream(userId).listen((goals) {
      if (goals.isNotEmpty) {}
      _goals = goals;
      notifyListeners();
    }, onError: (error) {
      print('Stream error: $error');
    });
  }

  // Goal CRUD Operations
  Future<void> createGoal(Goal goal) async {
    _setLoading(true);
    try {
      // Only add to templates, not to active goals
      _goals.add(goal);
      String? userId = _repository.getCurrentUserId();
      if (userId != null) {
        await _repository.saveGoals(userId, _goals);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createWeek(Goal goal) async {
    _setLoading(true);
    await _goalService.createWeek(_goals, goal);
    _setLoading(false);
  }
// Replace the editGoal method with this simpler version:

  Future<void> editGoal(Goal updatedGoal) async {
    _setLoading(true);
    try {
      int index = _goals.indexWhere((g) => g.id == updatedGoal.id);
      if (index != -1) {
        Map<String, dynamic>? existingChallenge = _goals[index].challenge;

        _goals[index].goalName = updatedGoal.goalName;
        _goals[index].goalCriteria = updatedGoal.goalCriteria;
        _goals[index].goalFrequency = updatedGoal.goalFrequency;

        if (existingChallenge != null) {
          _goals[index].challenge = existingChallenge;
        }

        // Save to repository
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _repository.saveGoals(userId, _goals);
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleGoalActive(String goalId) async {
    _setLoading(true);
    try {
      final index = _goals.indexWhere((goal) => goal.id == goalId);
      if (index != -1) {
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
    try {
      await _goalService.removeGoal(_goals, goalId);

      // Update local state - important!
      _goals = _goals.where((goal) => goal.id != goalId).toList();

      // Ensure UI updates
      notifyListeners();
    } catch (e) {
      print("Error removing goal: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleSkipPlan(String goalId, String day, String status) async {
    int index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index != -1 && _goals[index] is WeeklyGoal) {
      final updatedGoals = List<Goal>.from(_goals);
      final goal = updatedGoals[index] as WeeklyGoal;

      Map<String, dynamic> completions =
          goal.challenge!['completions'] as Map<String, dynamic>? ?? {};
      completions[day] = status;
      goal.challenge!['completions'] = completions;

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

  Future<void> denyProof(
      String goalId, String userId, String? proofDate) async {
    await _proofService.denyProof(goalId, userId, proofDate);
  }

  // New method to lock in goals and update party status
  Future<void> lockInGoalsForChallenge(String partyId) async {
    _setLoading(true);
    try {
      // Lock in goals
      await lockInActiveGoals();

      // Update party document
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.lockedInMembers': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('Error locking in goals for challenge: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> lockInActiveGoals() async {
    _setLoading(true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get the current goals document from Firestore
      DocumentSnapshot doc =
          await _firestore.collection('userGoals').doc(userId).get();

      if (!doc.exists) {
        print('⚠️ No goals document exists for user');
        return;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      List<dynamic> goalsData = userData['goals'] ?? [];

      List<dynamic> updatedGoals = [];

      for (var goalData in goalsData) {
        if (goalData['active'] == true) {
          // Add challenge field to the goal object
          goalData['challenge'] = {
            'challengeFrequency': goalData['goalFrequency'], // copy from goal
            'challengeCriteria': goalData['goalCriteria'], // copy from goal
            'completions': {}, // empty for now
            'proofs': {} // empty for now
          };
        }
        updatedGoals.add(goalData);
      }

      // Update the goals array in Firestore
      await _firestore
          .collection('userGoals')
          .doc(userId)
          .update({'goals': updatedGoals});

      print('🎯 Challenge field added to goals');

      // We're not modifying the local goals list for this test
      notifyListeners();
    } catch (e) {
      print('❌ Error creating challenge fields: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGoals() async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) return;

    _goals = await _repository.getGoalsForUser(userId);
    notifyListeners();
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
