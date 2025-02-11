import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyGoalsScreen extends StatefulWidget {
  const MyGoalsScreen({super.key});

//TODO: Public API use for individual goals is likely a no-no at scale
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
        'timestamp': FieldValue.serverTimestamp(),
      });
      _goalController.clear();
      _detailsController.clear();
      _frequency = 1;
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
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _firestore
                                  .collection('users')
                                  .doc(_auth.currentUser!.uid)
                                  .collection('goals')
                                  .doc(goals[index].id)
                                  .delete();
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
