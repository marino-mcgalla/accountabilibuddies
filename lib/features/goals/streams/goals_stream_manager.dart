import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/goal_model.dart';
import '../repositories/goals_repository.dart';
import '../state/goals_state.dart';

class GoalsStreamManager {
  final GoalsRepository _repository;
  final FirebaseAuth _auth;
  StreamSubscription<List<Goal>>? _goalsSubscription;

  GoalsStreamManager({
    GoalsRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? GoalsRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  Stream<GoalsState> getGoalsStateStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(const GoalsState());
    }

    return _repository.getGoalsStream(userId).map((goals) {
      return GoalsState(
        goals: goals,
        isLoading: false,
      );
    }).handleError((error) {
      // Log error but don't break the stream
      return const GoalsState(isLoading: false);
    });
  }

  void dispose() {
    _goalsSubscription?.cancel();
  }
}