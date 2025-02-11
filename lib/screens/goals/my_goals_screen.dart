import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/goal_card.dart';

class MyGoalsScreen extends StatelessWidget {
  const MyGoalsScreen({super.key});

  Future<void> _addGoal(
      BuildContext context,
      TextEditingController goalNameController,
      TextEditingController goalFrequencyController,
      TextEditingController goalCriteriaController) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    String goalName = goalNameController.text.trim();
    int goalFrequency = int.parse(goalFrequencyController.text.trim());
    String goalCriteria = goalCriteriaController.text.trim();

    if (goalName.isEmpty || goalFrequency <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid goal details")),
      );
      return;
    }

    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    List<Map<String, dynamic>> weekStatus = List.generate(7, (index) {
      DateTime date = monday.add(Duration(days: index));
      return {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'status': 'blank',
      };
    });

    await FirebaseFirestore.instance.collection('goals').add({
      'goalName': goalName,
      'goalFrequency': goalFrequency,
      'goalCriteria': goalCriteria,
      'ownerId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'weekStatus': weekStatus,
    });

    goalNameController.clear();
    goalFrequencyController.clear();
    goalCriteriaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController goalNameController = TextEditingController();
    final TextEditingController goalFrequencyController =
        TextEditingController();
    final TextEditingController goalCriteriaController =
        TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("My Goals")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: goalNameController,
              decoration: const InputDecoration(
                labelText: "Goal Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: goalFrequencyController,
              decoration: const InputDecoration(
                labelText: "Goal Frequency",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: goalCriteriaController,
              decoration: const InputDecoration(
                labelText: "Goal Criteria/Details",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addGoal(context, goalNameController,
                  goalFrequencyController, goalCriteriaController),
              child: const Text("Add Goal"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('goals')
                    .where('ownerId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No goals found"));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var goal = doc.data() as Map<String, dynamic>;
                      return GoalCard(
                        goalId: doc.id,
                        goalName: goal['goalName'],
                        goalFrequency: goal['goalFrequency'],
                        goalCriteria: goal['goalCriteria'],
                      );
                    }).toList(),
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
