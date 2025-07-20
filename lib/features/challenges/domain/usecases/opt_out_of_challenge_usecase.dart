import '../../../../core/core.dart';
import '../entities/challenge.dart';
import '../entities/challenge_commitment.dart';
import '../repositories/challenge_repository.dart';

/// Parameters for opting out of a challenge
class OptOutOfChallengeParams {
  const OptOutOfChallengeParams({
    required this.challengeId,
    required this.userId,
    required this.userName,
  });

  final String challengeId;
  final String userId;
  final String userName;
}

/// Use case for opting out of a challenge
class OptOutOfChallengeUseCase {
  final ChallengeRepository _challengeRepository;

  OptOutOfChallengeUseCase(this._challengeRepository);

  Future<Result<ChallengeCommitment>> call(OptOutOfChallengeParams params) async {
    try {
      // Get the challenge
      final challengeResult = await _challengeRepository.getChallenge(params.challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;

      // Validate challenge state
      if (!challenge.isAcceptingCommitments) {
        return Result.failure(const ValidationFailure(
          message: 'Cannot opt out - challenge commitments are no longer being accepted',
        ));
      }

      // Check if user already has a commitment
      final existingCommitmentResult = await _challengeRepository.getUserCommitment(
        params.challengeId,
        params.userId,
      );
      
      if (existingCommitmentResult.isFailure) {
        return Result.failure(existingCommitmentResult.failureOrNull!);
      }

      final now = DateTime.now();
      final existingCommitment = existingCommitmentResult.valueOrNull;

      ChallengeCommitment commitment;

      if (existingCommitment != null) {
        // Update existing commitment to opted out
        commitment = existingCommitment.copyWith(
          status: CommitmentStatus.optedOut,
          goalConfigs: [], // Clear goal configs when opting out
          wagerAmount: null, // Clear wager when opting out
          commitmentDate: null, // Clear commitment date
          updatedAt: now,
        );
      } else {
        // Create new commitment with opted out status
        commitment = ChallengeCommitment(
          id: '', // Will be set by repository
          challengeId: params.challengeId,
          userId: params.userId,
          userName: params.userName,
          status: CommitmentStatus.optedOut,
          createdAt: now,
          updatedAt: now,
          goalConfigs: [],
        );
      }

      return await _challengeRepository.saveCommitment(commitment);
    } catch (e, stackTrace) {
      logger.error('OptOutOfChallengeUseCase: Unexpected error', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to opt out of challenge',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}