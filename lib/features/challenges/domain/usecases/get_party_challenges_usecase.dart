import '../../../../core/core.dart';
import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

/// Use case for getting all challenges for a party
class GetPartyChallengesUseCase {
  final ChallengeRepository _challengeRepository;

  GetPartyChallengesUseCase(this._challengeRepository);

  Future<Result<List<Challenge>>> call(String partyId) async {
    try {
      return await _challengeRepository.getChallenges(partyId);
    } catch (e, stackTrace) {
      logger.error('GetPartyChallengesUseCase: Unexpected error', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to get party challenges',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}