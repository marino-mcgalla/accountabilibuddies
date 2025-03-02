import 'package:auth_test/features/goals/widgets/proof_submission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../models/total_goal.dart';
import '../models/weekly_goal.dart';
import 'progress_tracker.dart';
import '../providers/goals_provider.dart';

class GoalCard extends StatefulWidget {
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
  _GoalCardState createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
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
              goal: widget.goal,
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
          widget.goal.goalName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.goal.goalType.capitalize()} goal · ${widget.goal.goalFrequency} ${widget.goal.goalType == 'weekly' ? 'days/week' : 'total'}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        if (widget.goal.goalCriteria.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.goal.goalCriteria,
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
        if (widget.goal is TotalGoal)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Increment'),
            onPressed: () => goalsProvider.incrementCompletions(widget.goal.id),
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
          onPressed: widget.onEdit,
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onDelete,
          tooltip: 'Delete',
          color: Colors.red,
        ),
      ],
    );
  }

  /// Handles tapping on a day for weekly goals
  void _handleDayTap(String goalId, String day, String status) {
    if (widget.goal is! WeeklyGoal) return;

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

    // Use the stored context to update the status
    Provider.of<GoalsProvider>(context, listen: false)
        .toggleSkipPlan(goalId, day, newStatus);
  }

  /// Opens a dialog to submit proof
  Future<void> _submitProof(BuildContext context) async {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    await showDialog<bool>(
      context: context,
      builder: (context) => ProofSubmissionDialog(
        goal: widget.goal,
        onSubmit: (proofText, imageUrl) async {
          debugPrint(
              'Submitting proof with text: $proofText and image URL: $imageUrl');
          await goalsProvider.submitProof(
            widget.goal.id,
            proofText,
            imageUrl,
          );
        },
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
