import '../../../../core/core.dart';
import '../entities/proof_submission.dart';

/// Repository interface for proof submission management
abstract class ProofRepository {
  /// Submit a new proof
  Future<Result<ProofSubmission>> submitProof(ProofSubmission proof);

  /// Get a specific proof by ID
  Future<Result<ProofSubmission>> getProof(String proofId);

  /// Get all proofs for a challenge
  Future<Result<List<ProofSubmission>>> getProofsForChallenge(String challengeId);

  /// Get all proofs for a specific participant  
  Future<Result<List<ProofSubmission>>> getProofsForParticipant(String participationId);

  /// Get all proofs for a user across challenges
  Future<Result<List<ProofSubmission>>> getProofsForUser(String userId);

  /// Get pending proofs for a challenge (for approval)
  Future<Result<List<ProofSubmission>>> getPendingProofs(String challengeId);

  /// Get pending proofs by user (for story viewer)
  Future<Result<Map<String, List<ProofSubmission>>>> getPendingProofsByUser(String challengeId);

  /// Update proof status for a specific challenge/goal combination
  Future<Result<ProofSubmission>> updateProofStatusFor(String proofId, String challengeId, String goalTemplateId, ProofStatus status);

  /// Add approval/rejection to a proof for a specific challenge/goal
  Future<Result<ProofSubmission>> addProofApprovalFor(String proofId, String challengeId, String goalTemplateId, ProofApproval approval);

  /// Mark proof as viewed by user for a specific challenge/goal
  Future<Result<ProofSubmission>> markProofAsViewedFor(String proofId, String challengeId, String goalTemplateId, String userId);

  // Backward compatibility methods
  
  /// Update proof status (approve, dispute, reject) - uses first challenge/goal
  Future<Result<ProofSubmission>> updateProofStatus(String proofId, ProofStatus status);

  /// Add approval/rejection to a proof - uses first challenge/goal
  Future<Result<ProofSubmission>> addProofApproval(String proofId, ProofApproval approval);

  /// Mark proof as viewed by user - uses first challenge/goal
  Future<Result<ProofSubmission>> markProofAsViewed(String proofId, String userId);

  /// Delete a proof
  Future<Result<void>> deleteProof(String proofId);

  /// Delete all proofs for a challenge (used when challenge is cancelled)
  Future<Result<void>> deleteProofsForChallenge(String challengeId);

  /// Watch proofs for a challenge (real-time updates)
  Stream<Result<List<ProofSubmission>>> watchProofsForChallenge(String challengeId);

  /// Watch pending proofs for approval (real-time updates)
  Stream<Result<List<ProofSubmission>>> watchPendingProofs(String challengeId);

  /// Watch pending proofs grouped by user (real-time updates)
  Stream<Result<Map<String, List<ProofSubmission>>>> watchPendingProofsByUser(String challengeId);
}