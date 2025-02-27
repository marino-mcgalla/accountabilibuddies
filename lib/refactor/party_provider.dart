import 'dart:async';
import 'package:auth_test/refactor/goals_provider.dart';
import 'package:auth_test/refactor/time_machine_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'party_actions.dart'; // Import the new file

class PartyProvider with ChangeNotifier {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? partyId;
  String? partyName;
  List<String> members = [];
  Map<String, Map<String, dynamic>> memberDetails = {};
  bool isLoading = true;
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController inviteController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? partySubscription;

  String? get getPartyId => partyId;
  String? get getPartyName => partyName;
  List<String> get getMembers => members;
  Map<String, Map<String, dynamic>> get getMemberDetails => memberDetails;
  bool get getIsLoading => isLoading;

  PartyProvider() {
    initializePartyState();
  }

  void initializePartyState() {
    isLoading = true;
    notifyListeners();

    String? currentUserId = auth.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      isLoading = false;
      notifyListeners();
      return; // Exit if there is no valid user ID
    }

    partySubscription?.cancel(); // Cancel any existing subscription
    partySubscription = firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists &&
          userDoc.data() != null &&
          (userDoc.data() as Map<String, dynamic>).containsKey('partyId')) {
        String partyId = (userDoc.data() as Map<String, dynamic>)['partyId'];
        firestore
            .collection('parties')
            .doc(partyId)
            .snapshots()
            .listen((partyDoc) {
          if (partyDoc.exists) {
            this.partyId = partyId;
            this.partyName = partyDoc['partyName'];
            this.members = List<String>.from(partyDoc['members']);
            fetchMemberDetails();
          } else {
            this.partyId = null;
            this.partyName = null;
            this.members = [];
            this.memberDetails = {};
          }
          isLoading = false;
          notifyListeners();
        });
      } else {
        this.partyId = null;
        this.partyName = null;
        this.members = [];
        this.memberDetails = {};
        isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchMemberDetails() async {
    for (String memberId in members) {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        memberDetails[memberId] = userDoc.data() as Map<String, dynamic>;
      }
    }
    notifyListeners();
  }

  void triggerNotifyListeners() {
    notifyListeners();
  }

  Future<List<Goal>> fetchGoalsForUser(String userId) async {
    DocumentSnapshot userGoalsDoc =
        await firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      final data = userGoalsDoc.data();
      if (data != null && data is Map<String, dynamic>) {
        List<dynamic> goalsData = data['goals'] ?? [];
        return goalsData.map((goalData) => Goal.fromMap(goalData)).toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchSubmittedGoalsForParty(
      BuildContext context) async {
    List<Map<String, dynamic>> submittedGoals = [];
    for (String memberId in members) {
      List<Goal> goals = await fetchGoalsForUser(memberId);
      for (Goal goal in goals) {
        if (goal is WeeklyGoal) {
          goal.currentWeekCompletions.forEach((day, status) {
            if (status == 'submitted') {
              submittedGoals.add({
                'goal': goal,
                'date': day,
              });
            }
          });
        } else if (goal is TotalGoal) {
          List<Map<String, dynamic>> proofs = goal.proofs;
          for (var proof in proofs) {
            submittedGoals.add({
              'goal': goal,
              'proof': proof,
            });
          }
        }
      }
    }
    return submittedGoals;
  }

  Future<void> endWeekForAll(BuildContext context) async {
    final timeMachineProvider =
        Provider.of<TimeMachineProvider>(context, listen: false);
    DateTime newWeekStartDate = timeMachineProvider.now;

    for (String memberId in members) {
      DocumentSnapshot userGoalsDoc =
          await firestore.collection('userGoals').doc(memberId).get();

      if (userGoalsDoc.exists) {
        List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
        List<Goal> goals =
            goalsData.map((goalData) => Goal.fromMap(goalData)).toList();

        // Store current week's progress in history
        await firestore
            .collection('userGoalsHistory')
            .doc(memberId)
            .collection('weeks')
            .doc(timeMachineProvider.now
                .toString()) //TODO: change this to the history goal's week start date instead
            .set({'goals': goalsData});

        // Reset goals for the new week
        for (Goal goal in goals) {
          goal.weekStartDate = newWeekStartDate;
          goal.currentWeekCompletions = {}; // Reset completions
        }

        // Update goals in Firestore
        List<Map<String, dynamic>> updatedGoalsData =
            goals.map((goal) => goal.toMap()).toList();
        await firestore
            .collection('userGoals')
            .doc(memberId)
            .set({'goals': updatedGoalsData});
      }
    }
    notifyListeners(); // Notify listeners after updating goals
  }

  void resetState() {
    partyId = null;
    partyName = null;
    members = [];
    memberDetails = {};
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    partySubscription?.cancel();
    super.dispose();
  }
}
