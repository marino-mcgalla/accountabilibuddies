import 'dart:async';
import '../../goals/models/goal_model.dart';
import '../repositories/party_repository.dart';
import '../state/party_state.dart';

class PartyStreamManager {
  final PartyRepository _repository;
  StreamSubscription<Map<String, dynamic>?>? _partySubscription;
  final List<StreamSubscription<List<Goal>>> _goalSubscriptions = [];
  
  PartyStreamManager({PartyRepository? repository})
      : _repository = repository ?? PartyRepository();

  Stream<PartyState> getPartyStateStream() {
    return _repository.getUserPartyStream().map((partyData) {
      if (partyData == null) {
        return const PartyState();
      }

      return PartyState(
        partyId: partyData['partyId'],
        partyName: partyData['partyName'],
        partyLeaderId: partyData['partyOwner'],
        members: List<String>.from(partyData['members'] ?? []),
        challengeStartDay: partyData['challengeStartDay'] ?? 1,
        activeChallenge: partyData['activeChallenge'],
        isLoading: false,
      );
    });
  }

  Stream<Map<String, List<Goal>>> getMemberGoalsStream(List<String> memberIds) async* {
    if (memberIds.isEmpty) {
      yield {};
      return;
    }

    // Cancel existing subscriptions
    for (var subscription in _goalSubscriptions) {
      subscription.cancel();
    }
    _goalSubscriptions.clear();

    // Create a map to track each member's goals
    Map<String, List<Goal>> memberGoals = {};
    
    // Create a stream controller to combine all member goal streams
    final StreamController<Map<String, List<Goal>>> controller = 
        StreamController<Map<String, List<Goal>>>();

    for (String memberId in memberIds) {
      final subscription = _repository.getMemberGoalsStream(memberId).listen((goals) {
        memberGoals[memberId] = goals;
        controller.add(Map.from(memberGoals)); // Send updated map
      });
      _goalSubscriptions.add(subscription);
    }

    yield* controller.stream;
  }

  void dispose() {
    _partySubscription?.cancel();
    for (var subscription in _goalSubscriptions) {
      subscription.cancel();
    }
    _goalSubscriptions.clear();
  }
}