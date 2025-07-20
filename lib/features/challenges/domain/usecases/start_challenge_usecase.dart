import '../../../../core/core.dart';
import '../../../parties/domain/repositories/party_repository.dart';
import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

/// Parameters for starting a challenge
class StartChallengeParams {
  const StartChallengeParams({
    required this.challengeId,
    required this.userId,
  });

  final String challengeId;
  final String userId;
}

/// Use case for starting a challenge (transitioning from pending to active)
class StartChallengeUseCase {
  final ChallengeRepository _challengeRepository;
  final PartyRepository _partyRepository;

  StartChallengeUseCase(
    this._challengeRepository,
    this._partyRepository,
  );

  Future<Result<Challenge>> call(StartChallengeParams params) async {
    try {
      // Get the challenge
      final challengeResult = await _challengeRepository.getChallenge(params.challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;

      // Validate that the user is the party leader
      final partyResult = await _partyRepository.getParty(challenge.partyId);
      if (partyResult.isFailure) {
        return Result.failure(partyResult.failureOrNull!);
      }

      final party = partyResult.valueOrNull!;
      
      // Check if user is the party leader
      if (!party.isLeader(params.userId)) {
        return Result.failure(const ValidationFailure(
          message: 'Only the party leader can start challenges',
        ));
      }

      // Validate challenge state
      if (challenge.status != ChallengeStatus.pending) {
        return Result.failure(const ValidationFailure(
          message: 'Challenge is not in pending state',
        ));
      }

      // Check if challenge start date has been reached
      final now = DateTime.now();
      if (challenge.startDate.isAfter(now)) {
        return Result.failure(const ValidationFailure(
          message: 'Challenge cannot be started before its start date',
        ));
      }

      // Get all commitments to validate that at least one member has committed
      final commitmentsResult = await _challengeRepository.getChallengeCommitments(params.challengeId);
      if (commitmentsResult.isFailure) {
        return Result.failure(commitmentsResult.failureOrNull!);
      }

      final commitments = commitmentsResult.valueOrNull!;
      final committedCount = commitments.where((c) => c.isCommitted).length;

      if (committedCount == 0) {
        return Result.failure(const ValidationFailure(
          message: 'At least one member must commit before starting the challenge',
        ));
      }

      logger.info('StartChallengeUseCase: Starting challenge ${challenge.id} with $committedCount committed members');

      // Start the challenge
      return await _challengeRepository.startChallenge(params.challengeId);
    } catch (e, stackTrace) {
      logger.error('StartChallengeUseCase: Unexpected error', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to start challenge',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}