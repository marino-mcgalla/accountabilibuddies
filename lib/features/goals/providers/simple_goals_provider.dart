import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';
import '../models/goal_instance.dart';
import '../services/goal_instance_service.dart';
import 'dart:async';

class SimpleGoalsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoalInstanceService _goalInstanceService = GoalInstanceService();

  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _challengeGoalsSubscription;
  StreamSubscription<DocumentSnapshot>? _memberGoalsSubscription;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Goal> get activeGoals => _goals.where((goal) => goal.active).toList();
  bool get hasActiveGoals => activeGoals.isNotEmpty;
  String? get currentUserId => _auth.currentUser?.uid;

  SimpleGoalsProvider() {
    _loadGoals();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Find the user's challenge
      final partiesSnapshot = await _firestore
          .collection('parties')
          .where('members', arrayContains: userId)
          .get();

      for (var doc in partiesSnapshot.docs) {
        final data = doc.data();
        
        // Check activeChallenge first (most common)
        final activeChallenge = data['activeChallenge'] as Map<String, dynamic>?;
        final pendingChallenge = data['pendingChallenge'] as Map<String, dynamic>?;
        
        String? challengeId;
        if (activeChallenge != null) {
          challengeId = activeChallenge['id'] as String;
        } else if (pendingChallenge != null) {
          challengeId = pendingChallenge['id'] as String;
        }
        
        if (challengeId != null) {
          print('GOALS PROVIDER: Setting up real-time listener for challenge $challengeId');
          
          // Listen to the user's memberGoals document
          _memberGoalsSubscription = _firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('memberGoals')
              .doc(userId)
              .snapshots()
              .listen((doc) {
            print('GOALS PROVIDER: Received real-time update for user goals');
            _processRealtimeGoalsUpdate(doc);
          });
          
          break; // Only set up one listener
        }
      }
    } catch (e) {
      print('GOALS PROVIDER: Error setting up real-time listener: $e');
    }
  }

  void _processRealtimeGoalsUpdate(DocumentSnapshot doc) {
    if (!doc.exists) return;

    try {
      final memberGoalsData = doc.data() as Map<String, dynamic>;
      final userGoals = memberGoalsData['goals'] as List? ?? [];
      
      List<Goal> updatedGoals = [];
      for (var goalData in userGoals) {
        try {
          final goal = Goal.fromMap(Map<String, dynamic>.from(goalData));
          updatedGoals.add(goal);
        } catch (e) {
          print('GOALS PROVIDER: Error parsing goal in real-time update: $e');
        }
      }
      
      _goals = updatedGoals;
      print('GOALS PROVIDER: Updated ${_goals.length} goals from real-time listener');
      notifyListeners();
    } catch (e) {
      print('GOALS PROVIDER: Error processing real-time update: $e');
    }
  }

  // Force refresh for debugging
  Future<void> refreshGoals() async {
    print('DEBUG: Force refreshing goals...');
    await _loadGoals();
  }

  // Set up real-time listeners for challenge goals
  void setupChallengeGoalsListener(String challengeId) {
    _challengeGoalsSubscription?.cancel();
    
    _challengeGoalsSubscription = _goalInstanceService
        .listenToAllMemberGoalsForChallenge(challengeId: challengeId)
        .listen((allMemberGoals) {
      print('DEBUG: Received real-time update for challenge $challengeId');
      
      // Find current user's goals from the real-time data
      final userId = currentUserId;
      if (userId != null) {
        final userGoalInstances = allMemberGoals
            .where((goalData) => goalData['userId'] == userId)
            .map((goalData) => goalData['instance'] as GoalInstance)
            .toList();
        
        // Convert goal instances to goals by using their toMap method and Goal.fromMap
        final convertedGoals = userGoalInstances.map((instance) {
          return Goal.fromMap(instance.toMap());
        }).toList();
        
        if (convertedGoals.isNotEmpty) {
          _goals = convertedGoals;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _challengeGoalsSubscription?.cancel();
    _memberGoalsSubscription?.cancel();
    super.dispose();
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
      'goalType': 'daily',
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
          final challengeId = pendingChallenge['id'] as String;
          
          // Load from subcollection: challenges/{challengeId}/memberGoals/{userId}
          final memberGoalsDoc = await _firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('memberGoals')
              .doc(userId)
              .get();
          
          if (memberGoalsDoc.exists) {
            final memberGoalsData = memberGoalsDoc.data() as Map<String, dynamic>;
            final userGoals = memberGoalsData['goals'] as List? ?? [];
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
          final challengeId = activeChallenge['id'] as String;
          
          // Load from subcollection: challenges/{challengeId}/memberGoals/{userId}
          final memberGoalsDoc = await _firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('memberGoals')
              .doc(userId)
              .get();
          
          if (memberGoalsDoc.exists) {
            final memberGoalsData = memberGoalsDoc.data() as Map<String, dynamic>;
            final userGoals = memberGoalsData['goals'] as List? ?? [];
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

  Future<bool> submitProof(String goalId, String proofText, String? imageUrl, DateTime date, {bool isOverwrite = false}) async {
    final userId = currentUserId;
    if (userId == null) return false;

    print('DEBUG: SIMPLE SUBMIT: Submitting proof for goal $goalId (overwrite: $isOverwrite)');
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

      // Use overwriteProof or addProof based on the flag
      final updatedGoal = isOverwrite 
          ? goal.overwriteProof(proofText, imageUrl, date)
          : goal.addProof(proofText, imageUrl, date);
      print('DEBUG: SIMPLE SUBMIT: Updated goal with proof (using ${isOverwrite ? "overwrite" : "add"})');
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
          final challengeId = pendingChallenge['id'] as String;
          
          // Load from subcollection
          final memberGoalsDoc = await _firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('memberGoals')
              .doc(userId)
              .get();
          
          if (memberGoalsDoc.exists) {
            final memberGoalsData = memberGoalsDoc.data() as Map<String, dynamic>;
            final userGoals = List<Map<String, dynamic>>.from(memberGoalsData['goals'] as List);
            final goalIndex = userGoals.indexWhere((g) => g['id'] == goalId);
            
            if (goalIndex != -1) {
              userGoals[goalIndex] = updatedGoal.toMap();
              
              print('DEBUG: SIMPLE SUBMIT: About to save to Firebase - pendingChallenge');
              print('DEBUG: SIMPLE SUBMIT: Updated goal map: ${updatedGoal.toMap()}');
              
              await _firestore
                  .collection('challenges')
                  .doc(challengeId)
                  .collection('memberGoals')
                  .doc(userId)
                  .update({
                    'goals': userGoals,
                    'updatedAt': FieldValue.serverTimestamp(),
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
          final challengeId = activeChallenge['id'] as String;
          
          // Load from subcollection
          final memberGoalsDoc = await _firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('memberGoals')
              .doc(userId)
              .get();
          
          if (memberGoalsDoc.exists) {
            final memberGoalsData = memberGoalsDoc.data() as Map<String, dynamic>;
            final userGoals = List<Map<String, dynamic>>.from(memberGoalsData['goals'] as List);
            final goalIndex = userGoals.indexWhere((g) => g['id'] == goalId);
            
            if (goalIndex != -1) {
              userGoals[goalIndex] = updatedGoal.toMap();
              
              print('DEBUG: SIMPLE SUBMIT: About to save to Firebase - activeChallenge');
              print('DEBUG: SIMPLE SUBMIT: Updated goal map: ${updatedGoal.toMap()}');
              
              await _firestore
                  .collection('challenges')
                  .doc(challengeId)
                  .collection('memberGoals')
                  .doc(userId)
                  .update({
                    'goals': userGoals,
                    'updatedAt': FieldValue.serverTimestamp(),
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

  Future<bool> updatePlannedDays(String goalId, Set<int> plannedDays) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Find the goal
      final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex == -1) {
        print('DEBUG: UPDATE PLANNED DAYS: Goal not found');
        return false;
      }

      final goal = _goals[goalIndex];
      if (goal.goalType != GoalType.daily) {
        print('DEBUG: UPDATE PLANNED DAYS: Goal is not a daily goal');
        return false;
      }

      print('DEBUG: UPDATE PLANNED DAYS: Updating planned days for ${goal.goalName}: $plannedDays');

      // Update the goal with new planned days
      final updatedGoal = goal.updatePlannedDays(plannedDays);

      // Save to Firebase - find the party
      final partiesSnapshot = await _firestore
          .collection('parties')
          .where('members', arrayContains: userId)
          .get();

      for (var partyDoc in partiesSnapshot.docs) {
        final partyData = partyDoc.data();
        
        // Update both pendingChallenge and activeChallenge
        for (final challengeType in ['pendingChallenge', 'activeChallenge']) {
          final challenge = partyData[challengeType] as Map<String, dynamic>?;
          if (challenge != null) {
            final challengeId = challenge['id'] as String;
            
            // Load from subcollection
            final memberGoalsDoc = await _firestore
                .collection('challenges')
                .doc(challengeId)
                .collection('memberGoals')
                .doc(userId)
                .get();
            
            if (memberGoalsDoc.exists) {
              final memberGoalsData = memberGoalsDoc.data() as Map<String, dynamic>;
              final userGoals = List<Map<String, dynamic>>.from(memberGoalsData['goals'] as List);
              final goalIndex = userGoals.indexWhere((g) => g['id'] == goalId);
              
              if (goalIndex != -1) {
                userGoals[goalIndex] = updatedGoal.toMap();
                
                print('DEBUG: UPDATE PLANNED DAYS: Saving to Firebase - $challengeType');
                
                await _firestore
                    .collection('challenges')
                    .doc(challengeId)
                    .collection('memberGoals')
                    .doc(userId)
                    .update({
                      'goals': userGoals,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                
                print('DEBUG: UPDATE PLANNED DAYS: Successfully saved to Firebase');
                
                // Update local state
                _goals[goalIndex] = updatedGoal;
                notifyListeners();
                return true;
              }
            }
          }
        }
      }

      print('DEBUG: UPDATE PLANNED DAYS: Goal not found in any party');
      return false;
    } catch (e) {
      print('DEBUG: UPDATE PLANNED DAYS: Error: $e');
      return false;
    }
  }
}