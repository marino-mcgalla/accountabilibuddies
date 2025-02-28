import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'week_view_grid.dart';

class GoalCard extends StatelessWidget {
  final String goalId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;
  final List<dynamic> weekStatus;
  final Function(BuildContext, String, String, String) toggleStatus;
  final VoidCallback? onDelete; // Optional callback for delete action

  const GoalCard({
    required this.goalId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    required this.weekStatus,
    required this.toggleStatus,
    this.onDelete, // Optional delete action
    Key? key,
  }) : super(key: key);

  Future<void> _deleteGoal(BuildContext context) async {
    // Show confirmation dialog for deletion
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("This action will permanently delete the goal."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Proceed with goal deletion
      await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal deleted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(goalName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Frequency: $goalFrequency times per week"),
            const SizedBox(height: 10),
            Text("Criteria: $goalCriteria"),
            const SizedBox(height: 20),
            WeekViewGrid(
                goalId: goalId,
                weekStatus: weekStatus,
                toggleStatus: toggleStatus),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteGoal(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
