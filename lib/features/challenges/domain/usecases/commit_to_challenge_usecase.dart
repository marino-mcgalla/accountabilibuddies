import '../../../../core/core.dart';
import '../entities/challenge.dart';
import '../entities/challenge_commitment.dart';
import '../repositories/challenge_repository.dart';

/// Parameters for committing to a challenge
class CommitToChallengeParams {
  const CommitToChallengeParams({
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.goalConfigs,
    this.wagerAmount,
    this.wagerCurrency = 'USD',
  });

  final String challengeId;
  final String userId;
  final String userName;
  final List<GoalCommitment> goalConfigs;
  final double? wagerAmount;
  final String wagerCurrency;
}

/// Use case for committing to a challenge
class CommitToChallengeUseCase {
  final ChallengeRepository _challengeRepository;

  CommitToChallengeUseCase(this._challengeRepository);

  Future<Result<ChallengeCommitment>> call(CommitToChallengeParams params) async {
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
          message: 'Challenge is no longer accepting commitments',
        ));
      }

      // Validate goal configs
      if (params.goalConfigs.isEmpty) {
        return Result.failure(const ValidationFailure(
          message: 'At least one goal must be selected',
        ));
      }

      // Validate wager amount (if provided)
      if (params.wagerAmount != null && params.wagerAmount! < 0) {
        return Result.failure(const ValidationFailure(
          message: 'Wager amount cannot be negative',
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
        // Update existing commitment
        commitment = existingCommitment.copyWith(
          status: CommitmentStatus.committed,
          goalConfigs: params.goalConfigs,
          wagerAmount: params.wagerAmount,
          wagerCurrency: params.wagerCurrency,
          commitmentDate: now,
          updatedAt: now,
        );
      } else {
        // Create new commitment
        commitment = ChallengeCommitment(
          id: '', // Will be set by repository
          challengeId: params.challengeId,
          userId: params.userId,
          userName: params.userName,
          status: CommitmentStatus.committed,
          createdAt: now,
          updatedAt: now,
          goalConfigs: params.goalConfigs,
          wagerAmount: params.wagerAmount,
          wagerCurrency: params.wagerCurrency,
          commitmentDate: now,
        );
      }

      return await _challengeRepository.saveCommitment(commitment);
    } catch (e, stackTrace) {
      logger.error('CommitToChallengeUseCase: Unexpected error', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to commit to challenge',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}