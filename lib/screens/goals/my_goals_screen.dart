import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyGoalsScreen extends StatefulWidget {
  const MyGoalsScreen({super.key});

  @override
  MyGoalsScreenState createState() => MyGoalsScreenState();
}

class MyGoalsScreenState extends State<MyGoalsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  int _frequency = 1;

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Enter your goal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('How many times per week?'),
                  DropdownButton<int>(
                    value: _frequency,
                    items: List.generate(7, (index) => index + 1)
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text('$e times'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _frequency = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveGoal();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Goal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGoal() async {
    User? user = _auth.currentUser;
    if (user != null && _goalController.text.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .add({
        'goal': _goalController.text,
        'details': _detailsController.text,
        'frequency': _frequency,
        'completedDays': [],
        'verificationRequests':
            {}, // Start with an empty map for verification requests
        'timestamp': FieldValue.serverTimestamp(),
        'creatorId': user.uid, // Store the user ID who created the goal
        'verifiedDays': [],
      });
      _goalController.clear();
      _detailsController.clear();
      _frequency = 1;
    }
  }

  // This method will be used to request verification for a specific day
  void _requestVerification(String goalId, String day) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Get the current verification requests
      DocumentSnapshot goalDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(goalId)
          .get();

      if (goalDoc.exists) {
        final goalData = goalDoc.data() as Map<String, dynamic>;
        final verificationRequests = goalData['verificationRequests'] ?? {};

        // Only change the selected day's status to true (yellow question mark)
        if (verificationRequests[day] != true) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('goals')
              .doc(goalId)
              .update({
            'verificationRequests': {
              ...verificationRequests,
              day: true, // Request verification for the day
            }
          });
        }
      }
    }
  }

  Future<void> _verifyGoal(String goalId, String day) async {
    User? user = _auth.currentUser;
    final goalDoc = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('goals')
        .doc(goalId)
        .get();

    if (goalDoc.exists) {
      final goalData = goalDoc.data()!;
      final creatorId = goalData['creatorId'];

      // Get party members
      DocumentSnapshot partyDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('party')
          .doc('partyDetails')
          .get();

      final partyMembers = List<String>.from(partyDoc['members'] ?? []);

      // Only allow party members to verify each other's goals
      if (partyMembers.contains(user.uid) && creatorId != user.uid) {
        // If user is not the creator and is in the party, verify the goal
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .doc(goalId)
            .update({
          'verificationRequests': {
            day: false, // Mark the request as verified by setting it to false
          },
          'verifiedDays':
              FieldValue.arrayUnion([day]), // Add day to verifiedDays
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You can only verify goals of other party members.')),
        );
      }
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(goalId)
          .delete();
    }
  }

  Stream<QuerySnapshot> _getGoalsStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .orderBy('timestamp')
          .snapshots();
    }
    return const Stream.empty();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Goals')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _showAddGoalDialog,
              child: const Text('Add Goal'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getGoalsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final goals = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goalData =
                          goals[index].data() as Map<String, dynamic>;
                      final List<dynamic> completedDays =
                          goalData['completedDays'] ?? [];
                      final int remaining =
                          goalData['frequency'] - completedDays.length;
                      final verificationRequests =
                          goalData['verificationRequests'] ?? {};
                      final verifiedDays = goalData['verifiedDays'] ?? [];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(goalData['goal']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (goalData['details'].isNotEmpty)
                                Text(goalData['details']),
                              Text(
                                  'Frequency: ${goalData['frequency']} times/week'),
                              Text('Completed: ${completedDays.length} times'),
                              Text('Remaining: $remaining times'),
                              const SizedBox(height: 10),
                              for (var day in [
                                'Sunday',
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday'
                              ])
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(day),
                                    IconButton(
                                      icon: Icon(
                                        verificationRequests[day] == true
                                            ? Icons.help_outline
                                            : Icons.circle_outlined,
                                        color: verificationRequests[day] == true
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        if (verificationRequests[day] == true) {
                                          // Verify goal if the user is not the creator
                                          _verifyGoal(goals[index].id, day);
                                        } else {
                                          // Request verification for the day
                                          _requestVerification(
                                              goals[index].id, day);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              if (verifiedDays.isNotEmpty)
                                Text(
                                    'Verified Days: ${verifiedDays.join(', ')}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _deleteGoal(goals[index].id);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
