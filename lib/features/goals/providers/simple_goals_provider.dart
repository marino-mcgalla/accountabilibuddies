import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';

class SimpleGoalsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Goal> get activeGoals => _goals.where((goal) => goal.active).toList();
  bool get hasActiveGoals => activeGoals.isNotEmpty;
  String? get currentUserId => _auth.currentUser?.uid;

  SimpleGoalsProvider() {
    _loadGoals();
  }

  // Force refresh for debugging
  Future<void> refreshGoals() async {
    print('DEBUG: Force refreshing goals...');
    await _loadGoals();
  }

  // Test method to validate data format
  void debugGoalData() {
    print('DEBUG: Current goals count: ${_goals.length}');
    for (var goal in _goals) {
      print('DEBUG: Goal ${goal.goalName}:');
      print('  - ID: ${goal.id}');
      print('  - Type: ${goal.goalType}');
      print('  - Challenge data: ${goal.challengeData?.toMap()}');
      print('  - Completions: ${goal.challengeData?.completions}');
      print('  - Daily proofs: ${goal.challengeData?.dailyProofs}');
    }
  }

  // Test method to simulate proof submission scenario
  void simulateProofSubmission() {
    print('DEBUG: SIMULATION: Simulating proof submission for 2025-07-09');
    
    // Create test goal data similar to what should be in Firebase
    final testGoalData = {
      'id': '1752093025471_0',
      'ownerId': 'swMvqZCvPvg1vUsAZLMEvNXtBWD2',
      'goalName': 'Cardio',
      'goalType': 'weekly',
      'goalCriteria': '30 minutes of ANY cardio',
      'goalFrequency': 6,
      'active': true,
      'challengeData': {
        'completions': {'2025-07-09': 'pending'},
        'dailyProofs': {
          '2025-07-09': {
            'id': '1752093025471_0_2025-07-09_1752098879859',
            'proofText': '607',
            'imageUrl': null,
            'status': 'pending',
            'submissionDate': '2025-07-09T18:07:59.859'
          }
        },
        'proofs': []
      },
      'createdAt': '2025-07-09T16:30:25.471',
      'updatedAt': '2025-07-09T18:07:59.860'
    };
    
    try {
      final goal = Goal.fromMap(testGoalData);
      print('DEBUG: SIMULATION: Created goal successfully');
      print('DEBUG: SIMULATION: Goal challenge data: ${goal.challengeData?.toMap()}');
      print('DEBUG: SIMULATION: Completions: ${goal.challengeData?.completions}');
      print('DEBUG: SIMULATION: Daily proofs: ${goal.challengeData?.dailyProofs}');
      
      // Check if the completion for 2025-07-09 is pending
      final status = goal.challengeData?.getCompletionStatus('2025-07-09');
      print('DEBUG: SIMULATION: Status for 2025-07-09: $status');
      
    } catch (e) {
      print('DEBUG: SIMULATION: Error creating goal: $e');
    }
  }

  Future<void> _loadGoals() async {
    final userId = currentUserId;
    if (userId == null) return;

    print('DEBUG: Loading goals for user: $userId');
    _isLoading = true;
    notifyListeners();

    try {
      // Load from party challenge
      final partiesSnapshot = await _firestore
          .collection('parties')
          .where('members', arrayContains: userId)
          .get();

      List<Goal> challengeGoals = [];
      
      for (var doc in partiesSnapshot.docs) {
        final data = doc.data();
        
        // Check pendingChallenge first
        final pendingChallenge = data['pendingChallenge'] as Map<String, dynamic>?;
        if (pendingChallenge != null) {
          final memberGoals = pendingChallenge['memberGoals'] as Map<String, dynamic>?;
          if (memberGoals != null && memberGoals.containsKey(userId)) {
            final userGoals = memberGoals[userId] as List? ?? [];
            print('DEBUG: Found ${userGoals.length} pending challenge goals');
            
            for (var goalData in userGoals) {
              try {
                final goal = Goal.fromMap(Map<String, dynamic>.from(goalData));
                challengeGoals.add(goal);
                print('DEBUG: Loaded goal: ${goal.goalName}');
                print('DEBUG: Goal challenge data: ${goal.challengeData?.toMap()}');
              } catch (e) {
                print('DEBUG: Error parsing goal: $e');
              }
            }
          }
        }
        
        // Check activeChallenge
        final activeChallenge = data['activeChallenge'] as Map<String, dynamic>?;
        if (activeChallenge != null) {
          final memberGoals = activeChallenge['memberGoals'] as Map<String, dynamic>?;
          if (memberGoals != null && memberGoals.containsKey(userId)) {
            final userGoals = memberGoals[userId] as List? ?? [];
            print('DEBUG: Found ${userGoals.length} active challenge goals');
            
            for (var goalData in userGoals) {
              try {
                final goal = Goal.fromMap(Map<String, dynamic>.from(goalData));
                challengeGoals.add(goal);
                print('DEBUG: Loaded goal: ${goal.goalName}');
                print('DEBUG: Goal challenge data: ${goal.challengeData?.toMap()}');
              } catch (e) {
                print('DEBUG: Error parsing goal: $e');
              }
            }
          }
        }
      }

      _goals = challengeGoals;
      print('DEBUG: Total goals loaded: ${_goals.length}');
      print('DEBUG: Active goals: ${activeGoals.length}');
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading goals: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGoalFromTemplate(dynamic template) async {
    // Stub implementation for now
    print('DEBUG: createGoalFromTemplate called');
    return false;
  }

  Future<bool> createGoal({
    required String goalName,
    required String goalType,
    required String goalCriteria,
    required int goalFrequency,
    String? templateId,
  }) async {
    // Stub implementation for now
    print('DEBUG: createGoal called');
    return false;
  }

  Future<bool> submitProof(String goalId, String proofText, String? imageUrl, DateTime date) async {
    final userId = currentUserId;
    if (userId == null) return false;

    print('DEBUG: SIMPLE SUBMIT: Submitting proof for goal $goalId');
    print('DEBUG: SIMPLE SUBMIT: Proof text: $proofText');
    print('DEBUG: SIMPLE SUBMIT: Date: ${date.toIso8601String().split('T')[0]}');

    try {
      // Find the goal
      final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex == -1) {
        print('DEBUG: SIMPLE SUBMIT: Goal not found');
        return false;
      }

      final goal = _goals[goalIndex];
      print('DEBUG: SIMPLE SUBMIT: Found goal: ${goal.goalName}');
      print('DEBUG: SIMPLE SUBMIT: Goal type: ${goal.goalType}');
      print('DEBUG: SIMPLE SUBMIT: Current challengeData: ${goal.challengeData?.toMap()}');

      // Add proof to goal
      final updatedGoal = goal.addProof(proofText, imageUrl, date);
      print('DEBUG: SIMPLE SUBMIT: Updated goal with proof');
      print('DEBUG: SIMPLE SUBMIT: Updated goal challenge data: ${updatedGoal.challengeData?.toMap()}');

      // Save to Firebase - find the party
      final partiesSnapshot = await _firestore
          .collection('parties')
          .where('members', arrayContains: userId)
          .get();

      for (var partyDoc in partiesSnapshot.docs) {
        final partyData = partyDoc.data();
        
        // Update pendingChallenge
        final pendingChallenge = partyData['pendingChallenge'] as Map<String, dynamic>?;
        if (pendingChallenge != null) {
          final memberGoals = pendingChallenge['memberGoals'] as Map<String, dynamic>?;
          if (memberGoals != null && memberGoals.containsKey(userId)) {
            final userGoals = List<Map<String, dynamic>>.from(memberGoals[userId] as List);
            final goalIndex = userGoals.indexWhere((g) => g['id'] == goalId);
            
            if (goalIndex != -1) {
              userGoals[goalIndex] = updatedGoal.toMap();
              
              print('DEBUG: SIMPLE SUBMIT: About to save to Firebase - pendingChallenge');
              print('DEBUG: SIMPLE SUBMIT: Updated goal map: ${updatedGoal.toMap()}');
              
              await _firestore.collection('parties').doc(partyDoc.id).update({
                'pendingChallenge.memberGoals.$userId': userGoals,
              });
              
              print('DEBUG: SIMPLE SUBMIT: Successfully saved to Firebase - pendingChallenge');
              
              // Update local state
              _goals[goalIndex] = updatedGoal;
              print('DEBUG: SIMPLE SUBMIT: Calling notifyListeners() - goals count: ${_goals.length}');
              notifyListeners();
              return true;
            }
          }
        }
        
        // Update activeChallenge
        final activeChallenge = partyData['activeChallenge'] as Map<String, dynamic>?;
        if (activeChallenge != null) {
          final memberGoals = activeChallenge['memberGoals'] as Map<String, dynamic>?;
          if (memberGoals != null && memberGoals.containsKey(userId)) {
            final userGoals = List<Map<String, dynamic>>.from(memberGoals[userId] as List);
            final goalIndex = userGoals.indexWhere((g) => g['id'] == goalId);
            
            if (goalIndex != -1) {
              userGoals[goalIndex] = updatedGoal.toMap();
              
              print('DEBUG: SIMPLE SUBMIT: About to save to Firebase - activeChallenge');
              print('DEBUG: SIMPLE SUBMIT: Updated goal map: ${updatedGoal.toMap()}');
              
              await _firestore.collection('parties').doc(partyDoc.id).update({
                'activeChallenge.memberGoals.$userId': userGoals,
              });
              
              print('DEBUG: SIMPLE SUBMIT: Successfully saved to Firebase - activeChallenge');
              
              // Update local state
              _goals[goalIndex] = updatedGoal;
              print('DEBUG: SIMPLE SUBMIT: Calling notifyListeners() - goals count: ${_goals.length}');
              notifyListeners();
              return true;
            }
          }
        }
      }

      print('DEBUG: SIMPLE SUBMIT: Goal not found in any party');
      return false;
    } catch (e) {
      print('DEBUG: SIMPLE SUBMIT: Error: $e');
      return false;
    }
  }
}