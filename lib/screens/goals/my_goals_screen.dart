import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/goal_card.dart';
import '../../services/goals_service.dart';
import '../../models/goal_model.dart';

class MyGoalsScreen extends StatefulWidget {
  MyGoalsScreen({super.key});

  @override
  _MyGoalsScreenState createState() => _MyGoalsScreenState();
}

class _MyGoalsScreenState extends State<MyGoalsScreen> {
  final GoalsService _goalsService = GoalsService();
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  //TODO: maybe using state correctly now??????
  Future<void> _loadGoals() async {
    List<Goal> goals = await _goalsService.getGoals();
    //TODO: break this out into a service instead of here
    for (Goal goal in goals) {
      QuerySnapshot weekSnapshot = await FirebaseFirestore.instance
          .collection('weeks')
          .where('goalId', isEqualTo: goal.id)
          .where('isActive', isEqualTo: true)
          .get();
      if (weekSnapshot.docs.isNotEmpty) {
        goal.weekStatus = weekSnapshot.docs.first['weekStatus'];
      }
    }
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  Future<void> _toggleStatus(BuildContext context, String docId, String date,
      String currentStatus) async {
    await _goalsService.toggleStatus(docId, date, currentStatus);
    _loadGoals(); // Refresh the goals after toggling status
  }

  void _showAddGoalDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController frequencyController = TextEditingController();
    TextEditingController criteriaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Goal Name"),
              ),
              TextField(
                controller: frequencyController,
                decoration:
                    const InputDecoration(labelText: "Frequency (per week)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: criteriaController,
                decoration: const InputDecoration(labelText: "Goal Criteria"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    frequencyController.text.isNotEmpty) {
                  final goal = Goal(
                    id: '', // Firebase will generate the ID
                    name: nameController.text,
                    frequency: int.tryParse(frequencyController.text) ?? 1,
                    criteria: criteriaController.text,
                    weekStatus: [],
                  );
                  await _goalsService.createGoal(
                      goal.name, goal.frequency, goal.criteria);
                  Navigator.pop(context);
                  _loadGoals(); // Refresh the goals after adding a new goal
                }
              },
              child: const Text("Add Goal"),
            ),
          ],
        );
      },
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    TextEditingController nameController =
        TextEditingController(text: goal.name);
    TextEditingController frequencyController =
        TextEditingController(text: goal.frequency.toString());
    TextEditingController criteriaController =
        TextEditingController(text: goal.criteria);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Goal Name"),
              ),
              TextField(
                controller: frequencyController,
                decoration:
                    const InputDecoration(labelText: "Frequency (per week)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: criteriaController,
                decoration: const InputDecoration(labelText: "Goal Criteria"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    frequencyController.text.isNotEmpty) {
                  final updatedGoal = Goal(
                    id: goal.id,
                    name: nameController.text,
                    frequency: int.tryParse(frequencyController.text) ?? 1,
                    criteria: criteriaController.text,
                    weekStatus: goal.weekStatus,
                  );
                  await _goalsService.editGoal(updatedGoal);
                  Navigator.pop(context);
                  _loadGoals(); // Refresh the goals after editing a goal
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Goals")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return GoalCard(
                  goalId: goal.id,
                  goalName: goal.name,
                  goalFrequency: goal.frequency,
                  goalCriteria: goal.criteria,
                  week: goal.weekStatus,
                  toggleStatus: (context, docId, date, currentStatus) =>
                      _toggleStatus(context, docId, date, currentStatus),
                  onDelete: () async {
                    await _goalsService.deleteGoal(context, goal.id);
                    _loadGoals(); // Refresh the goals after deleting a goal
                  },
                  onEdit: () => _showEditGoalDialog(context, goal),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
