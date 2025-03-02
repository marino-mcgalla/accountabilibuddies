import 'package:flutter/material.dart';
import '../../goals/models/goal_model.dart';
import '../../goals/models/total_goal.dart';
import '../../goals/models/weekly_goal.dart';
import '../../goals/models/proof_model.dart';
import '../../common/utils/utils.dart';

/// A widget that displays a single proof item
class ProofItem extends StatelessWidget {
  final Goal goal;
  final String userName;
  final String? date;
  final dynamic proof; // Can be Map, Proof object, or null
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

    // Extract info from proof if available
    String proofText = 'No details provided';
    String? imageUrl;

    if (proof != null) {
      try {
        if (proof is Map<String, dynamic>) {
          proofText = proof['proofText'] ?? 'No details provided';
          imageUrl = proof['imageUrl'];
        } else if (proof is Proof) {
          proofText = proof.proofText;
          imageUrl = proof.imageUrl;
        }
      } catch (e) {
        debugPrint('Error accessing weekly proof details: $e');
      }
    }

    // Build a list of widgets for the card content
    List<Widget> children = [
      Text(
        'Weekly Goal: ${goal.goalName}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      Text('User: $userName'),
      Text('Date: $formattedDate'),
      Text('Criteria: ${goal.goalCriteria}'),
    ];

    // Add proof text if available
    if (proofText != 'No details provided') {
      children.add(const Divider());
      children.add(Text('Proof: $proofText'));
    }

    // Add image if available
    if (imageUrl != null && imageUrl.isNotEmpty) {
      children.add(const Divider());
      children.add(
        Center(
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl!),
            child: Hero(
              tag: 'proof-image-$imageUrl',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text('Error loading image'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add action buttons
    children.add(const SizedBox(height: 16));
    children.add(_buildActionButtons(context));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// Builds a card for a total goal proof
  Widget _buildTotalGoalItem(BuildContext context) {
    // Extract proof details - handle both Map and Proof object
    String proofText = 'No details provided';
    String submissionDate = '';
    String? imageUrl;

    try {
      if (proof is Map<String, dynamic>) {
        proofText = proof['proofText'] ?? 'No details provided';
        submissionDate = proof['submissionDate'] ?? '';
        imageUrl = proof['imageUrl'];
      } else if (proof is Proof) {
        proofText = proof.proofText;
        submissionDate = proof.submissionDate.toIso8601String();
        imageUrl = proof.imageUrl;
      } else {
        // Try to use dynamic approach for flexibility
        final dynamic proofObj = proof;
        proofText = proofObj?.proofText ?? 'No details provided';
        submissionDate = proofObj?.submissionDate?.toIso8601String() ?? '';
        imageUrl = proofObj?.imageUrl;
      }
    } catch (e) {
      debugPrint('Error accessing total goal proof details: $e');
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

    // Build the list of widgets to display
    List<Widget> children = [
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
    ];

    // If we have an image URL, show the image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      children.add(const Divider());
      children.add(
        Center(
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl!),
            child: Hero(
              tag: 'proof-image-$imageUrl',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text('Error loading image'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add action buttons
    children.add(const SizedBox(height: 16));
    children.add(_buildActionButtons(context));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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
