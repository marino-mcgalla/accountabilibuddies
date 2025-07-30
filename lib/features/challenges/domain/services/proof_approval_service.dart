import '../../../../core/core.dart';
import '../entities/challenge_goal.dart';
import '../entities/proof_submission.dart';
import '../repositories/challenge_repository.dart';
import '../repositories/proof_repository.dart';

/// Service that handles the business logic of proof approvals and goal completion tracking
class ProofApprovalService {
  const ProofApprovalService({
    required this.proofRepository,
    required this.challengeRepository,
  });

  final ProofRepository proofRepository;
  final ChallengeRepository challengeRepository;

  /// Approve a proof and update goal completion if approved
  Future<Result<ProofSubmission>> approveProof(
    String proofId,
    ProofApproval approval,
  ) async {
    try {
      // Add the approval to the proof
      final proofResult = await proofRepository.addProofApproval(proofId, approval);
      if (proofResult.isFailure) {
        return proofResult;
      }

      final updatedProof = proofResult.valueOrNull!;

      // If the proof was approved, update the goal completion
      if (updatedProof.isApproved && approval.approved) {
        final goalUpdateResult = await _updateGoalCompletion(updatedProof);
        if (goalUpdateResult.isFailure) {
          logger.warning(
            'ProofApprovalService: Failed to update goal completion for approved proof ${updatedProof.id}',
            error: goalUpdateResult.failureOrNull,
          );
          // Note: We don't fail the approval if goal update fails
          // The proof is still approved, we just log the warning
        }
      }

      return Result.success(updatedProof);
    } catch (e, stackTrace) {
      logger.error('ProofApprovalService: Error approving proof', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to approve proof',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Update goal completion when a proof is approved
  Future<Result<void>> _updateGoalCompletion(ProofSubmission approvedProof) async {
    try {
      // Get the user's participation
      final participationResult = await challengeRepository.getUserParticipation(
        approvedProof.challengeId,
        approvedProof.userId,
      );

      if (participationResult.isFailure) {
        return Result.failure(participationResult.failureOrNull!);
      }

      final participation = participationResult.valueOrNull;
      if (participation == null) {
        return Result.failure(const NotFoundFailure(
          message: 'User participation not found',
        ));
      }

      // Find the goal that matches the proof
      final goalMap = Map<String, ChallengeGoal>.from(participation.goals);
      final challengeGoal = goalMap[approvedProof.goalTemplateId];
      
      if (challengeGoal == null) {
        return Result.failure(NotFoundFailure(
          message: 'Goal not found in participation: ${approvedProof.goalTemplateId}',
        ));
      }

      // Format the submission date as YYYY-MM-DD for completion tracking
      final completionDate = _formatDateForCompletion(approvedProof.submissionDate);
      
      // Add the completion date to the goal
      final updatedGoal = challengeGoal.addCompletion(completionDate);
      
      // Update the goal map
      goalMap[approvedProof.goalTemplateId] = updatedGoal;
      
      // Save the updated participation
      final updatedParticipation = participation.copyWith(goals: goalMap);
      final saveResult = await challengeRepository.saveParticipation(updatedParticipation);
      
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failureOrNull!);
      }

      logger.debug(
        'ProofApprovalService: Updated goal completion for user ${approvedProof.userId}, '
        'goal ${approvedProof.goalTemplateId}, date $completionDate',
      );

      return Result.success(null);
    } catch (e, stackTrace) {
      logger.error('ProofApprovalService: Error updating goal completion', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to update goal completion',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Format a DateTime as YYYY-MM-DD string for goal completion tracking
  String _formatDateForCompletion(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// Remove goal completion when a proof approval is reversed (for disputed proofs)
  Future<Result<void>> removeGoalCompletion(ProofSubmission proof) async {
    try {
      // Get the user's participation
      final participationResult = await challengeRepository.getUserParticipation(
        proof.challengeId,
        proof.userId,
      );

      if (participationResult.isFailure) {
        return Result.failure(participationResult.failureOrNull!);
      }

      final participation = participationResult.valueOrNull;
      if (participation == null) {
        return Result.failure(const NotFoundFailure(
          message: 'User participation not found',
        ));
      }

      // Find the goal that matches the proof
      final goalMap = Map<String, ChallengeGoal>.from(participation.goals);
      final challengeGoal = goalMap[proof.goalTemplateId];
      
      if (challengeGoal == null) {
        return Result.failure(NotFoundFailure(
          message: 'Goal not found in participation: ${proof.goalTemplateId}',
        ));
      }

      // Format the submission date as YYYY-MM-DD
      final completionDate = _formatDateForCompletion(proof.submissionDate);
      
      // Remove the completion date from the goal
      final updatedGoal = challengeGoal.removeCompletion(completionDate);
      
      // Update the goal map
      goalMap[proof.goalTemplateId] = updatedGoal;
      
      // Save the updated participation
      final updatedParticipation = participation.copyWith(goals: goalMap);
      final saveResult = await challengeRepository.saveParticipation(updatedParticipation);
      
      if (saveResult.isFailure) {
        return Result.failure(saveResult.failureOrNull!);
      }

      logger.debug(
        'ProofApprovalService: Removed goal completion for user ${proof.userId}, '
        'goal ${proof.goalTemplateId}, date $completionDate',
      );

      return Result.success(null);
    } catch (e, stackTrace) {
      logger.error('ProofApprovalService: Error removing goal completion', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to remove goal completion',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}