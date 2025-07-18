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
          
          // Listen to the user's memberGoals document
          _memberGoalsSubscription = _firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('memberGoals')
              .doc(userId)
              .snapshots()
              .listen((doc) {
            _processRealtimeGoalsUpdate(doc);
          });
          
          break; // Only set up one listener
        }
      }
    } catch (e) {
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
        }
      }
      
      _goals = updatedGoals;
      notifyListeners();
    } catch (e) {
    }
  }

  // Force refresh for debugging
  Future<void> refreshGoals() async {
    await _loadGoals();
  }

  // Set up real-time listeners for challenge goals
  void setupChallengeGoalsListener(String challengeId) {
    _challengeGoalsSubscription?.cancel();
    
    _challengeGoalsSubscription = _goalInstanceService
        .listenToAllMemberGoalsForChallenge(challengeId: challengeId)
        .listen((allMemberGoals) {
      
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
    for (var goal in _goals) {
    }
  }

  // Test method to simulate proof submission scenario
  void simulateProofSubmission() {
    
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
      
      // Check if the completion for 2025-07-09 is pending
      final status = goal.challengeData?.getCompletionStatus('2025-07-09');
      
    } catch (e) {
    }
  }

  Future<void> _loadGoals() async {
    final userId = currentUserId;
    if (userId == null) return;

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
            
            for (var goalData in userGoals) {
              try {
                final goal = Goal.fromMap(Map<String, dynamic>.from(goalData));
                challengeGoals.add(goal);
              } catch (e) {
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
            
            for (var goalData in userGoals) {
              try {
                final goal = Goal.fromMap(Map<String, dynamic>.from(goalData));
                challengeGoals.add(goal);
              } catch (e) {
              }
            }
          }
        }
      }

      _goals = challengeGoals;
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGoalFromTemplate(dynamic template) async {
    // Stub implementation for now
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
    return false;
  }

  Future<bool> submitProof(String goalId, String proofText, String? imageUrl, DateTime date, {bool isOverwrite = false}) async {
    final userId = currentUserId;
    if (userId == null) return false;


    try {
      // Find the goal
      final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex == -1) {
        return false;
      }

      final goal = _goals[goalIndex];

      // Use overwriteProof or addProof based on the flag
      final updatedGoal = isOverwrite 
          ? goal.overwriteProof(proofText, imageUrl, date)
          : goal.addProof(proofText, imageUrl, date);

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
              
              
              await _firestore
                  .collection('challenges')
                  .doc(challengeId)
                  .collection('memberGoals')
                  .doc(userId)
                  .update({
                    'goals': userGoals,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              
              
              // Update local state
              _goals[goalIndex] = updatedGoal;
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
              
              
              await _firestore
                  .collection('challenges')
                  .doc(challengeId)
                  .collection('memberGoals')
                  .doc(userId)
                  .update({
                    'goals': userGoals,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              
              
              // Update local state
              _goals[goalIndex] = updatedGoal;
              notifyListeners();
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
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
        return false;
      }

      final goal = _goals[goalIndex];
      if (goal.goalType != GoalType.daily) {
        return false;
      }


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
                
                
                await _firestore
                    .collection('challenges')
                    .doc(challengeId)
                    .collection('memberGoals')
                    .doc(userId)
                    .update({
                      'goals': userGoals,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                
                
                // Update local state
                _goals[goalIndex] = updatedGoal;
                notifyListeners();
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}