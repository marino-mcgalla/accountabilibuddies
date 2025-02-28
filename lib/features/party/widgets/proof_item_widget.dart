import 'package:flutter/material.dart';
import '../../goals/models/goal_model.dart';
import '../../goals/models/total_goal.dart';
import '../../goals/models/weekly_goal.dart';
import '../../goals/models/proof_model.dart'; // Import Proof model
import '../../common/utils/utils.dart';

/// A widget that displays a single proof item
class ProofItem extends StatelessWidget {
  final Goal goal;
  final String userName;
  final String? date;
  final dynamic proof; // Changed to dynamic to handle both Map and Proof
  final Function(String, String?, bool) onAction;

  const ProofItem({
    required this.goal,
    required this.userName,
    required this.onAction,
    this.date,
    this.proof,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Choose the appropriate widget based on goal type
    if (goal is WeeklyGoal && date != null) {
      return _buildWeeklyGoalItem(context);
    } else if (goal is TotalGoal && proof != null) {
      return _buildTotalGoalItem(context);
    }

    return const SizedBox.shrink(); // Empty fallback
  }

  /// Builds a card for a weekly goal proof
  Widget _buildWeeklyGoalItem(BuildContext context) {
    // Format date for display
    final DateTime dateObj = DateTime.parse(date!);
    final String formattedDate = Utils.formatDate(dateObj);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Goal: ${goal.goalName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('User: $userName'),
            Text('Date: $formattedDate'),
            Text('Criteria: ${goal.goalCriteria}'),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds a card for a total goal proof
  Widget _buildTotalGoalItem(BuildContext context) {
    // Extract proof details - handle both Map and Proof object
    String proofText;
    String submissionDate;

    try {
      if (proof is Map<String, dynamic>) {
        // Legacy map format
        proofText = proof['proofText'] ?? 'No details provided';
        submissionDate = proof['submissionDate'] ?? '';
      } else if (proof is Proof) {
        // New Proof object
        proofText = proof.proofText;
        submissionDate = proof.submissionDate.toIso8601String();
      } else {
        // Try to use dynamic approach for flexibility
        final dynamic proofObj = proof;
        // Try to access properties safely
        proofText = proofObj?.proofText ?? 'No details provided';
        submissionDate = proofObj?.submissionDate?.toIso8601String() ?? '';
      }
    } catch (e) {
      // Fallback if any error occurs
      proofText = 'Error accessing proof details';
      submissionDate = '';
    }

    // Format submission date if available
    String formattedDate = 'Unknown date';
    if (submissionDate.isNotEmpty) {
      try {
        final DateTime dateObj = DateTime.parse(submissionDate);
        formattedDate = Utils.formatDate(dateObj);
      } catch (e) {
        formattedDate = 'Invalid date format';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Goal: ${goal.goalName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('User: $userName'),
            Text('Submitted: $formattedDate'),
            Text('Criteria: ${goal.goalCriteria}'),
            const Divider(),
            Text('Proof: $proofText'),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds the approve/deny action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ProofActionButton(
          label: 'Deny',
          color: Colors.red,
          onPressed: () => onAction(goal.id, date, false),
        ),
        const SizedBox(width: 8),
        _ProofActionButton(
          label: 'Approve',
          color: Colors.green,
          onPressed: () => onAction(goal.id, date, true),
        ),
      ],
    );
  }
}

/// A button with loading state for proof actions
class _ProofActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ProofActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _ProofActionButtonState createState() => _ProofActionButtonState();
}

class _ProofActionButtonState extends State<_ProofActionButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : widget.label == 'Deny'
            ? TextButton(
                onPressed: _handlePress,
                style: TextButton.styleFrom(foregroundColor: widget.color),
                child: Text(widget.label),
              )
            : ElevatedButton(
                onPressed: _handlePress,
                style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                child: Text(widget.label),
              );
  }

  Future<void> _handlePress() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      widget.onPressed();
    } finally {
      // Check if still mounted before updating state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
