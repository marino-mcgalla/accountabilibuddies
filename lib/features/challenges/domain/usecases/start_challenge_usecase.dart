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

      // Validate challenge state - challenges are active upon creation now
      if (challenge.status != ChallengeStatus.active) {
        return Result.failure(const ValidationFailure(
          message: 'Challenge is already active or completed',
        ));
      }

      // Challenges are active immediately, so just return the challenge
      logger.info('StartChallengeUseCase: Challenge ${challenge.id} is already active');
      return Result.success(challenge);
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