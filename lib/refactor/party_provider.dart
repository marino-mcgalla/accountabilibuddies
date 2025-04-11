import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'time_machine_provider.dart'; // Import TimeMachineProvider

class PartyProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _partyId;
  String? _partyName;
  List<String> _members = [];
  Map<String, Map<String, dynamic>> _memberDetails = {};
  bool _isLoading = true;
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController inviteController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _partySubscription;

  String? get partyId => _partyId;
  String? get partyName => _partyName;
  List<String> get members => _members;
  Map<String, Map<String, dynamic>> get memberDetails => _memberDetails;
  bool get isLoading => _isLoading;

  PartyProvider() {
    initializePartyState();
  }

  void initializePartyState() {
    _isLoading = true;
    notifyListeners();

    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return; // Exit if there is no valid user ID
    }

    _partySubscription?.cancel(); // Cancel any existing subscription
    _partySubscription = _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists &&
          userDoc.data() != null &&
          (userDoc.data() as Map<String, dynamic>).containsKey('partyId')) {
        String partyId = (userDoc.data() as Map<String, dynamic>)['partyId'];
        _firestore
            .collection('parties')
            .doc(partyId)
            .snapshots()
            .listen((partyDoc) {
          print("Firestore read: Party document updated");
          if (partyDoc.exists) {
            _partyId = partyId;
            _partyName = partyDoc['partyName'];
            _members = List<String>.from(partyDoc['members']);
            _fetchMemberDetails();
          } else {
            _partyId = null;
            _partyName = null;
            _members = [];
            _memberDetails = {};
          }
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _partyId = null;
        _partyName = null;
        _members = [];
        _memberDetails = {};
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchMemberDetails() async {
    for (String memberId in _members) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        _memberDetails[memberId] = userDoc.data() as Map<String, dynamic>;
      }
    }
    notifyListeners();
  }

  Future<void> createParty(String partyName) async {
    String currentUserId = _auth.currentUser?.uid ?? "";

    if (partyName.isEmpty) {
      return;
    }

    DocumentReference partyRef = await _firestore.collection('parties').add({
      'createdBy': currentUserId,
      'partyOwner': currentUserId,
      'members': [currentUserId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    String partyId = partyRef.id;

    await partyRef.update({'partyName': partyName});

    _partyId = partyId;
    _partyName = partyName;
    _members = [currentUserId];

    await _firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    _fetchMemberDetails();
    notifyListeners();
  }

  Future<void> leaveParty() async {
    String currentUserId = _auth.currentUser?.uid ?? "";

    if (_members.length == 1) {
      await closeParty();
    } else {
      await _firestore.collection('users').doc(currentUserId).update({
        'partyId': FieldValue.delete(),
      });

      await _firestore.collection('parties').doc(_partyId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });

      _partyId = null;
      _partyName = null;
      _members = [];
      _memberDetails = {};
      notifyListeners();
    }
  }

  Future<void> closeParty() async {
    if (_partyId != null) {
      await _firestore.collection('parties').doc(_partyId).delete();

      for (String memberId in _members) {
        await _firestore.collection('users').doc(memberId).update({
          'partyId': FieldValue.delete(),
        });
      }

      _partyId = null;
      _partyName = null;
      _members = [];
      _memberDetails = {};
      notifyListeners();
    }
  }

  Future<void> updateCounter(String memberId, int value) async {
    DocumentReference userRef = _firestore.collection('users').doc(memberId);
    DocumentSnapshot userDoc = await userRef.get();

    if (userDoc.exists) {
      int currentCounter = userDoc['counter'] ?? 0;
      await userRef.update({'counter': currentCounter + value});
      notifyListeners();
    }
  }

  Stream<QuerySnapshot> fetchIncomingPendingInvites() {
    String currentUserId = _auth.currentUser?.uid ?? "";
    return _firestore
        .collection('invites')
        .where('inviteeId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> fetchOutgoingPendingInvites() {
    String currentUserId = _auth.currentUser?.uid ?? "";
    return _firestore
        .collection('invites')
        .where('inviterId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptInvite(String inviteId, String partyId) async {
    String currentUserId = _auth.currentUser?.uid ?? "";

    await _firestore.collection('invites').doc(inviteId).update({
      'status': 'accepted',
    });

    await _firestore.collection('users').doc(currentUserId).update({
      'partyId': partyId,
    });

    await _firestore.collection('parties').doc(partyId).update({
      'members': FieldValue.arrayUnion([currentUserId]),
    });

    _partyId = partyId;
    _fetchMemberDetails();
    notifyListeners();
  }

  Future<void> sendInvite() async {
    String currentUserId = _auth.currentUser?.uid ?? "";
    String inviteeEmail = inviteController.text;

    if (inviteeEmail.isEmpty) {
      return;
    }

    print("Firestore read: Checking if user exists with email $inviteeEmail");
    QuerySnapshot userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: inviteeEmail)
        .get();

    if (userQuery.docs.isNotEmpty) {
      String inviteeId = userQuery.docs.first.id;

      await _firestore.collection('invites').add({
        'inviterId': currentUserId,
        'inviteeId': inviteeId,
        'partyId': _partyId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      inviteController.clear();
      notifyListeners();
    }
  }

  Future<void> cancelInvite(String inviteId) async {
    print("Firestore read: Deleting invite with ID $inviteId");
    await _firestore.collection('invites').doc(inviteId).delete();
    notifyListeners();
  }

  Future<List<Goal>> fetchGoalsForUser(String userId) async {
    DocumentSnapshot userGoalsDoc =
        await _firestore.collection('userGoals').doc(userId).get();

    if (userGoalsDoc.exists) {
      final data = userGoalsDoc.data();
      if (data != null && data is Map<String, dynamic>) {
        List<dynamic> goalsData = data['goals'] ?? [];
        return goalsData.map((goalData) => Goal.fromMap(goalData)).toList();
      }
    }
    return [];
  }

  Future<void> endWeekForAll(BuildContext context) async {
    final timeMachineProvider =
        Provider.of<TimeMachineProvider>(context, listen: false);
    DateTime newWeekStartDate = timeMachineProvider.now;

    for (String memberId in _members) {
      DocumentSnapshot userGoalsDoc =
          await _firestore.collection('userGoals').doc(memberId).get();

      if (userGoalsDoc.exists) {
        List<dynamic> goalsData = userGoalsDoc['goals'] ?? [];
        List<Goal> goals =
            goalsData.map((goalData) => Goal.fromMap(goalData)).toList();

        // Store current week's progress in history
        await _firestore
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
        await _firestore
            .collection('userGoals')
            .doc(memberId)
            .set({'goals': updatedGoalsData});
      }
    }
    notifyListeners(); // Notify listeners after updating goals
  }

  void resetState() {
    _partyId = null;
    _partyName = null;
    _members = [];
    _memberDetails = {};
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _partySubscription?.cancel();
    super.dispose();
  }
}
