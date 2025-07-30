import '../../../../core/core.dart';
import '../entities/challenge.dart';
import '../entities/user_challenge_participation.dart';

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

  /// Get all participations for a challenge
  Future<Result<List<UserChallengeParticipation>>> getChallengeParticipations(String challengeId);

  /// Get a specific user's participation for a challenge
  Future<Result<UserChallengeParticipation?>> getUserParticipation(String challengeId, String userId);

  /// Create or update a user's participation in a challenge
  Future<Result<UserChallengeParticipation>> saveParticipation(UserChallengeParticipation participation);

  /// Delete a user's participation
  Future<Result<void>> deleteParticipation(String challengeId, String userId);

  /// Watch participations for a challenge (real-time updates)
  Stream<Result<List<UserChallengeParticipation>>> watchChallengeParticipations(String challengeId);

  /// Watch a specific user's participation (real-time updates)
  Stream<Result<UserChallengeParticipation?>> watchUserParticipation(String challengeId, String userId);

  /// Move challenge to summary phase (transition from active to summary)
  Future<Result<Challenge>> moveToSummary(String challengeId);

  /// Cancel a challenge
  Future<Result<Challenge>> cancelChallenge(String challengeId);
}