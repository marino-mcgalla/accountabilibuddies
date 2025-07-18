// lib/features/goals/services/proof_service.dart
import '../models/goal_model.dart';
// import '../models/total_goal.dart';  // Removed - using unified Goal model
// import '../models/weekly_goal.dart';  // Removed - using unified Goal model
import '../repositories/goals_repository.dart';
import '../../time_machine/providers/time_machine_provider.dart';

class ProofService {
  final GoalsRepository _repository;
  final TimeMachineProvider _timeMachineProvider;

  ProofService(this._repository, this._timeMachineProvider);

  Future<void> submitProof(List<Goal> currentGoals, String goalId,
      String proofText, String? imageUrl, bool yesterday) async {
    String? userId =
        _repository.getCurrentUserId();
    if (userId == null) {
      
      return;
    }

    
    int index = currentGoals.indexWhere((goal) => goal.id == goalId);
    if (index == -1) {
      
      return;
    }

    // Create working copy
    final updatedGoals = List<Goal>.from(currentGoals);
    Goal goal = updatedGoals[index];

    // Calculate date
    DateTime submissionDate = yesterday
        ? _timeMachineProvider.now.subtract(Duration(days: 1))
        : _timeMachineProvider.now;

    
    // Let the goal handle its own proof logic - this returns a new goal instance
    updatedGoals[index] = goal.addProof(proofText, imageUrl, submissionDate);

    
    
    // Save to Firebase
    
    await _repository.saveGoals(userId, updatedGoals);
    
  }

  Future<void> denyProof(List<Goal> currentGoals, String goalId, String? proofDate) async {
    String? userId = _repository.getCurrentUserId();
    if (userId == null) {
      
      return;
    }

    
    int index = currentGoals.indexWhere((goal) => goal.id == goalId);
    if (index == -1) {
      
      return;
    }

    // Create working copy
    final updatedGoals = List<Goal>.from(currentGoals);
    Goal goal = updatedGoals[index];

    if (proofDate != null) {
      // For weekly goals, use the proofDate; for total goals, find the proof by date
      String proofId = '${goalId}_${proofDate}_*'; // Simplified proof ID pattern
      updatedGoals[index] = goal.denyProof(proofId, proofDate);
      
      // Save to Firebase
      
      await _repository.saveGoals(userId, updatedGoals);
      
    }
  }
}
