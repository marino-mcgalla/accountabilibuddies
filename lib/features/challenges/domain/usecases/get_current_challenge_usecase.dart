import '../../../../core/core.dart';
import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

/// Use case for getting the current active challenge for a party
class GetCurrentChallengeUseCase {
  final ChallengeRepository _challengeRepository;

  GetCurrentChallengeUseCase(this._challengeRepository);

  Future<Result<Challenge?>> call(String partyId) async {
    try {
      return await _challengeRepository.getCurrentChallenge(partyId);
    } catch (e, stackTrace) {
      logger.error('GetCurrentChallengeUseCase: Unexpected error', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to get current challenge',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}