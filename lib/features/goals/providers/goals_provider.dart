import 'dart:async';
import 'package:auth_test/features/common/utils/utils.dart';
import 'package:auth_test/features/party/providers/party_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Future<void> denyProof(String goalId, String userId, String? proofDate,
      {List<Goal>? existingGoals}) async {
    _setLoading(true);
    try {
      // Use provided goals or fetch them if needed
      //TODO: why in the wet fuck do we always have to do this shit? IF WE ARE AT THIS POINT IN THE CODE THEN IT'S NOT GOING TO BE FUCKING NULL
      //TLDR: figure out null shit, way too many unnecessary checks
      List<Goal> userGoals =
          existingGoals ?? await _repository.getGoalsForUser(userId);

      int goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex == -1) return;

      Goal goal = userGoals[goalIndex];

      if (goal.goalType == 'weekly' && proofDate != null) {
        Map<String, dynamic> completions =
            goal.challenge!['completions'] as Map<String, dynamic>? ?? {};
        completions[proofDate] = 'denied';
        goal.challenge!['completions'] = completions;

        if (goal.challenge!['proofs'] is Map) {
          (goal.challenge!['proofs'] as Map).remove(proofDate);
        }
      } else if (goal.goalType == 'total') {
        if (goal.challenge!['proofs'] is List) {
          List proofs = goal.challenge!['proofs'] as List;
          int pendingIndex = proofs.indexWhere((p) => p['status'] == 'pending');
          if (pendingIndex != -1) {
            proofs.removeAt(pendingIndex);
          }
        }
      }

      await _repository.updateUserGoals(userId, userGoals);

      // Update local goals if needed
      if (userId == _auth.currentUser?.uid) {
        _goals = userGoals;
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> lockInGoalsForChallenge(String partyId,
      {double wagerAmount = 0}) async {
    _setLoading(true);
    try {
      await lockInActiveGoals();

      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('parties').doc(partyId).update({
        'activeChallenge.lockedInMembers': FieldValue.arrayUnion([userId]),
        'activeChallenge.wagers.$userId': wagerAmount
      });
    } catch (e) {
      print('Error locking in goals for challenge: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> showLockInDialogAndLockGoals(BuildContext context,
      [String? partyId]) async {
    final activeGoals = _goals.where((goal) => goal.active).toList();

    if (activeGoals.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Goals to Lock In'),
          content: const Text(
              'You need at least one active goal to participate in the challenge.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final wagerController = TextEditingController();

    final partyProvider = Provider.of<PartyProvider>(context, listen: false);
    final isPendingChallenge = partyProvider.hasPendingChallenge;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock In Goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isPendingChallenge
                ? 'This will lock in your goals for the upcoming challenge.'
                : 'Are you sure you want to lock in these goals?'),
            const SizedBox(height: 16),
            Text(
              'Active goals that will be included:\n${activeGoals.map((g) => '• ${g.goalName}').join('\n')}',
            ),
            const SizedBox(height: 24),
            const Text('Set your wager amount:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              'This is what you\'ll pay if you don\'t complete your goals.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: wagerController,
              decoration: const InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text('\$', style: TextStyle(fontSize: 16)),
                ),
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double wager = 0;
              try {
                wager = double.parse(wagerController.text);
              } catch (_) {}
              Navigator.pop(context, {'lockIn': true, 'wager': wager});
            },
            child: const Text('Lock In'),
          ),
        ],
      ),
    );

    if (result == null || result['lockIn'] != true) return;

    double wagerAmount = result['wager'] ?? 0;

    Utils.showFeedback(context, 'Locking in goals...');

    try {
      if (isPendingChallenge && partyId != null) {
        await lockInGoalsForChallenge(partyId, wagerAmount: wagerAmount);
      } else {
        await lockInActiveGoals();
      }
      Utils.showFeedback(context, 'Goals locked in successfully');
    } catch (e) {
      Utils.showFeedback(context, 'Error locking in goals: $e', isError: true);
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

      // We're not modifying the local goals list for this test
      notifyListeners();
    } catch (e) {
      print('❌ Error creating challenge fields: $e');
    } finally {
      _setLoading(false);
    }
  }

// Add to GoalsProvider
  Future<void> updateUserGoals(String userId, List<Goal> goals) async {
    _setLoading(true);
    try {
      await _repository.updateUserGoals(userId, goals);

      // Update local state if it's for current user
      if (userId == _auth.currentUser?.uid) {
        _goals = goals;
        notifyListeners();
      }
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
