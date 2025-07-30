import '../../../../core/core.dart';
import '../entities/challenge_goal.dart';
import '../entities/user_challenge_participation.dart';
import '../repositories/challenge_repository.dart';

/// Parameters for participating in a challenge (lock-in)
class ParticipateInChallengeParams {
  const ParticipateInChallengeParams({
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.goals,
    this.wagerAmount,
    this.wagerCurrency = 'USD',
  });

  final String challengeId;
  final String userId;
  final String userName;
  final Map<String, ChallengeGoal> goals;
  final double? wagerAmount;
  final String wagerCurrency;
}

/// Use case for participating in a challenge (locking in goals)
class ParticipateInChallengeUseCase {
  final ChallengeRepository _challengeRepository;

  ParticipateInChallengeUseCase(this._challengeRepository);

  Future<Result<UserChallengeParticipation>> call(ParticipateInChallengeParams params) async {
    try {
      // Get the challenge
      final challengeResult = await _challengeRepository.getChallenge(params.challengeId);
      if (challengeResult.isFailure) {
        return Result.failure(challengeResult.failureOrNull!);
      }

      final challenge = challengeResult.valueOrNull!;

      // Validate challenge state - must be active to participate
      if (!challenge.isActive) {
        return Result.failure(const ValidationFailure(
          message: 'Challenge is not active',
        ));
      }

      // Validate goals
      if (params.goals.isEmpty) {
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

      // Check if user already has a participation
      final existingParticipationResult = await _challengeRepository.getUserParticipation(
        params.challengeId,
        params.userId,
      );
      
      if (existingParticipationResult.isFailure) {
        return Result.failure(existingParticipationResult.failureOrNull!);
      }

      final now = DateTime.now();
      final existingParticipation = existingParticipationResult.valueOrNull;
      
      UserChallengeParticipation participation;
      
      if (existingParticipation != null) {
        // Update existing participation
        participation = existingParticipation.copyWith(
          status: ParticipationStatus.lockedIn,
          goals: params.goals,
          wagerAmount: params.wagerAmount,
          wagerCurrency: params.wagerCurrency,
          lockedInDate: now,
          updatedAt: now,
        );
      } else {
        // Create new participation
        participation = UserChallengeParticipation(
          id: '', // Will be set by repository
          challengeId: params.challengeId,
          userId: params.userId,
          userName: params.userName,
          status: ParticipationStatus.lockedIn,
          goals: params.goals,
          wagerAmount: params.wagerAmount,
          wagerCurrency: params.wagerCurrency,
          lockedInDate: now,
          createdAt: now,
          updatedAt: now,
        );
      }

      return await _challengeRepository.saveParticipation(participation);
    } catch (e, stackTrace) {
      logger.error('ParticipateInChallengeUseCase: Error participating in challenge', 
          error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to participate in challenge',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}