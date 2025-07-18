import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';
import '../repositories/goals_repository.dart';

class ProofActions {
  final GoalsRepository _repository;
  final FirebaseAuth _auth;

  ProofActions({
    GoalsRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? GoalsRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  Future<bool> submitProof(List<Goal> currentGoals, String goalId, String proofText, String? imageUrl, DateTime submissionDate) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final goals = List<Goal>.from(currentGoals);
      final index = goals.indexWhere((goal) => goal.id == goalId);
      
      if (index == -1) return false;

      final goal = goals[index];
      goals[index] = goal.addProof(proofText, imageUrl, submissionDate);

      await _repository.saveGoals(userId, goals);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> approveProof(String userId, String goalId, String? proofDate, {List<Goal>? existingGoals}) async {
    try {
      List<Goal> userGoals = existingGoals ?? await _repository.getGoalsForUser(userId);
      
      final goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex == -1) return false;

      final goal = userGoals[goalIndex];

      if (goal.goalType == GoalType.daily && proofDate != null) {
        userGoals[goalIndex] = goal.approveProof('', proofDate);
      } else if (goal.goalType == GoalType.total) {
        // For total goals, find the first pending proof and approve it
        final pendingProof = goal.pendingProofs.isNotEmpty ? goal.pendingProofs.first : null;
        if (pendingProof != null) {
          userGoals[goalIndex] = goal.approveProof(pendingProof.id, '');
        }
      }

      await _repository.updateUserGoals(userId, userGoals);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> denyProof(String userId, String goalId, String? proofDate, {List<Goal>? existingGoals}) async {
    try {
      List<Goal> userGoals = existingGoals ?? await _repository.getGoalsForUser(userId);
      
      final goalIndex = userGoals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex == -1) return false;

      final goal = userGoals[goalIndex];

      if (goal.goalType == GoalType.daily && proofDate != null) {
        userGoals[goalIndex] = goal.denyProof('', proofDate);
      } else if (goal.goalType == GoalType.total) {
        // For total goals, find the first pending proof and deny it
        final pendingProof = goal.pendingProofs.isNotEmpty ? goal.pendingProofs.first : null;
        if (pendingProof != null) {
          userGoals[goalIndex] = goal.denyProof(pendingProof.id, '');
        }
      }

      await _repository.updateUserGoals(userId, userGoals);
      return true;
    } catch (e) {
      return false;
    }
  }

}