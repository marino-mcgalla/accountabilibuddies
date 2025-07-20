import '../../../../core/core.dart';
import '../entities/challenge.dart';
import '../entities/challenge_commitment.dart';

/// Repository interface for challenge management
abstract class ChallengeRepository {
  /// Get all challenges for a party
  Future<Result<List<Challenge>>> getChallenges(String partyId);

  /// Get a specific challenge by ID
  Future<Result<Challenge>> getChallenge(String challengeId);

  /// Create a new challenge
  Future<Result<Challenge>> createChallenge(Challenge challenge);

  /// Update an existing challenge
  Future<Result<Challenge>> updateChallenge(Challenge challenge);

  /// Delete a challenge
  Future<Result<void>> deleteChallenge(String challengeId);

  /// Get the current active challenge for a party
  Future<Result<Challenge?>> getCurrentChallenge(String partyId);

  /// Watch challenges for a party (real-time updates)
  Stream<Result<List<Challenge>>> watchChallenges(String partyId);

  /// Watch a specific challenge (real-time updates)
  Stream<Result<Challenge>> watchChallenge(String challengeId);

  /// Get all commitments for a challenge
  Future<Result<List<ChallengeCommitment>>> getChallengeCommitments(String challengeId);

  /// Get a specific user's commitment for a challenge
  Future<Result<ChallengeCommitment?>> getUserCommitment(String challengeId, String userId);

  /// Create or update a user's commitment to a challenge
  Future<Result<ChallengeCommitment>> saveCommitment(ChallengeCommitment commitment);

  /// Delete a user's commitment
  Future<Result<void>> deleteCommitment(String commitmentId);

  /// Watch commitments for a challenge (real-time updates)
  Stream<Result<List<ChallengeCommitment>>> watchChallengeCommitments(String challengeId);

  /// Watch a specific user's commitment (real-time updates)
  Stream<Result<ChallengeCommitment?>> watchUserCommitment(String challengeId, String userId);

  /// Start a challenge (transition from pending to active)
  Future<Result<Challenge>> startChallenge(String challengeId);

  /// Complete a challenge (transition from active to settling)
  Future<Result<Challenge>> completeChallenge(String challengeId);

  /// Cancel a challenge
  Future<Result<Challenge>> cancelChallenge(String challengeId);

  /// Settle a challenge (transition from settling to completed)
  Future<Result<Challenge>> settleChallenge(String challengeId);
}