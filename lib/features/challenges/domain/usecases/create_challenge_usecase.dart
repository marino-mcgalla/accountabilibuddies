import '../../../../core/core.dart';
import '../../../parties/domain/repositories/party_repository.dart';
import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

/// Parameters for creating a new challenge
class CreateChallengeParams {
  const CreateChallengeParams({
    required this.partyId,
    required this.createdBy,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.commitmentDeadline,
  });

  final String partyId;
  final String createdBy;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? commitmentDeadline;
}

/// Use case for creating a new challenge
class CreateChallengeUseCase {
  final ChallengeRepository _challengeRepository;
  final PartyRepository _partyRepository;

  CreateChallengeUseCase(
    this._challengeRepository,
    this._partyRepository,
  );

  Future<Result<Challenge>> call(CreateChallengeParams params) async {
    try {
      // Validate that the user is the party leader
      final partyResult = await _partyRepository.getParty(params.partyId);
      if (partyResult.isFailure) {
        return Result.failure(partyResult.failureOrNull!);
      }

      final party = partyResult.valueOrNull!;
      
      // Check if user is the party leader
      if (!party.isLeader(params.createdBy)) {
        return Result.failure(const ValidationFailure(
          message: 'Only the party leader can create challenges',
        ));
      }

      // Check if party can start challenges (has enough members)
      if (!party.canStartChallenges) {
        return Result.failure(const ValidationFailure(
          message: 'Party must have at least 2 members to start challenges',
        ));
      }

      // Check if there's already an active or pending challenge
      final currentChallengeResult = await _challengeRepository.getCurrentChallenge(params.partyId);
      if (currentChallengeResult.isFailure) {
        return Result.failure(currentChallengeResult.failureOrNull!);
      }

      final currentChallenge = currentChallengeResult.valueOrNull;
      if (currentChallenge != null && !currentChallenge.hasEnded) {
        return Result.failure(const ValidationFailure(
          message: 'There is already an active challenge for this party',
        ));
      }

      // Validate dates
      final now = DateTime.now();
      if (params.startDate.isBefore(now)) {
        return Result.failure(const ValidationFailure(
          message: 'Start date cannot be in the past',
        ));
      }

      if (params.endDate.isBefore(params.startDate)) {
        return Result.failure(const ValidationFailure(
          message: 'End date must be after start date',
        ));
      }

      if (params.commitmentDeadline != null && 
          params.commitmentDeadline!.isAfter(params.startDate)) {
        return Result.failure(const ValidationFailure(
          message: 'Commitment deadline must be before start date',
        ));
      }

      // Create the challenge
      final challenge = Challenge(
        id: '', // Will be set by repository
        partyId: params.partyId,
        name: params.name,
        description: params.description,
        startDate: params.startDate,
        endDate: params.endDate,
        status: ChallengeStatus.pending,
        createdBy: params.createdBy,
        createdAt: now,
        updatedAt: now,
        commitmentDeadline: params.commitmentDeadline,
      );

      return await _challengeRepository.createChallenge(challenge);
    } catch (e, stackTrace) {
      logger.error('CreateChallengeUseCase: Unexpected error', error: e, stackTrace: stackTrace);
      return Result.failure(UnknownFailure(
        message: 'Failed to create challenge',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}