//// filepath: /Users/marino/Documents/dev/Projects/accountabilibuddies/lib/features/goals/widgets/goal_card.dart
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
  final VoidCallback onArchive; // New callback for archiving the goal

  const GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
    Key? key,
  }) : super(key: key);

  @override
  _GoalCardState createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  @override
  Widget build(BuildContext context) {
    // Check screen size for responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8.0 : 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isSmallScreen),
            const Divider(),
            ProgressTracker(
              goal: widget.goal,
              onDayTap: _handleDayTap,
              isCompact: isSmallScreen, // Pass the screen size info
            ),
            const SizedBox(height: 12),
            _buildActions(context, isSmallScreen),
          ],
        ),
      ),
    );
  }

  /// Builds the goal header with name and details
  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.goal.goalName,
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.goal.goalType.capitalize()} goal · ${widget.goal.goalFrequency} ${widget.goal.goalType == 'weekly' ? 'days/week' : 'total'}',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 14,
            color: Colors.grey[700],
          ),
        ),
        if (widget.goal.goalCriteria.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.goal.goalCriteria,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the action buttons
  Widget _buildActions(BuildContext context, bool isSmallScreen) {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    if (isSmallScreen) {
      // Compact layout for mobile
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Submit Proof'),
                  onPressed: () => _submitProof(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row - action icons for edit, archive and delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: widget.onEdit,
                tooltip: 'Edit',
                iconSize: 24,
                padding: const EdgeInsets.all(12),
              ),
              IconButton(
                icon:
                    Icon(widget.goal.active ? Icons.archive : Icons.unarchive),
                onPressed: widget.onArchive,
                tooltip: widget.goal.active ? 'Archive' : 'Restore',
                color: widget.goal.active ? Colors.orange : Colors.green,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: widget.onDelete,
                tooltip: 'Delete',
                color: Colors.red,
                iconSize: 24,
                padding: const EdgeInsets.all(12),
              ),
            ],
          ),
        ],
      );
    } else {
      // Desktop layout
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
            icon: const Icon(Icons.archive),
            onPressed: widget.onArchive,
            tooltip: 'Archive',
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
  }

  /// Handles tapping on a day for weekly goals
  void _handleDayTap(String goalId, String day, String status) {
    if (widget.goal is! WeeklyGoal) return;

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

    Provider.of<GoalsProvider>(context, listen: false)
        .toggleSkipPlan(goalId, day, newStatus);
  }

  // Opens a dialog to submit proof
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
