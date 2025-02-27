import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'progress_tracker.dart';
import 'goals_provider.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            ProgressTracker(
              goal: goal,
              onDayTap: _handleDayTap,
            ),
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// Builds the goal header with name and details
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.goalName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${goal.goalType.capitalize()} goal · ${goal.goalFrequency} ${goal.goalType == 'weekly' ? 'days/week' : 'total'}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        if (goal.goalCriteria.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            goal.goalCriteria,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the action buttons
  Widget _buildActions(BuildContext context) {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (goal is TotalGoal)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Increment'),
            onPressed: () => goalsProvider.incrementCompletions(goal.id),
          )
        else
          const SizedBox.shrink(),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Submit Proof'),
          onPressed: () => _submitProof(context),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
          tooltip: 'Delete',
          color: Colors.red,
        ),
      ],
    );
  }

  /// Handles tapping on a day for weekly goals
  void _handleDayTap(String goalId, String day, String status) {
    if (goal is! WeeklyGoal) return;

    // Cycle through statuses
    String newStatus;
    switch (status) {
      case 'default':
        newStatus = 'skipped';
        break;
      case 'skipped':
        newStatus = 'planned';
        break;
      case 'planned':
      default:
        newStatus = 'default';
        break;
    }

    // Use the BuildContext from the callback
    // This is usually handled in the parent widget
  }

  /// Opens a dialog to submit proof
  Future<void> _submitProof(BuildContext context) async {
    final TextEditingController proofController = TextEditingController();
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Goal: ${goal.goalName}'),
            const SizedBox(height: 16),
            TextField(
              controller: proofController,
              decoration: const InputDecoration(
                labelText: 'Proof Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && proofController.text.isNotEmpty) {
      await goalsProvider.submitProof(goal.id, proofController.text);
    }
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
