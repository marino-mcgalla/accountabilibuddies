import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for current user ID
import '../../goals/models/goal_model.dart';
import '../../goals/models/total_goal.dart';
import '../../goals/models/weekly_goal.dart';
import '../../goals/models/proof_model.dart';
import '../../common/utils/utils.dart';

/// A widget that displays a single proof item
class ProofItem extends StatelessWidget {
  final Goal goal;
  final String userName;
  final String userId; // Add userId parameter to check for self-approval
  final String? date;
  final dynamic proof; // Can be Map, Proof object, or null
  final Function(String, String?, bool) onAction;

  const ProofItem({
    required this.goal,
    required this.userName,
    required this.userId, // Add to constructor
    required this.onAction,
    this.date,
    this.proof,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check screen size for responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Choose the appropriate widget based on goal type
    if (goal is WeeklyGoal && date != null) {
      return _buildWeeklyGoalItem(context, isSmallScreen);
    } else if (goal is TotalGoal && proof != null) {
      return _buildTotalGoalItem(context, isSmallScreen);
    }

    return const SizedBox.shrink(); // Empty fallback
  }

  /// Helper to build consistent info chips
  Widget _buildInfoChip(IconData icon, String text, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isSmallScreen ? 18 : 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  /// Check if the current user is the owner of this goal
  bool _isOwnGoal() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == userId || currentUserId == goal.ownerId;
  }

  /// Builds a card for a weekly goal proof
  Widget _buildWeeklyGoalItem(BuildContext context, bool isSmallScreen) {
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

    // Check if this is the user's own goal
    final isSelfApproval = _isOwnGoal();

    return Card(
      margin: EdgeInsets.symmetric(
          vertical: 8.0, horizontal: isSmallScreen ? 8.0 : 16.0),
      elevation: isSmallScreen ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Goal: ${goal.goalName}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.person, 'User: $userName', isSmallScreen),
                _buildInfoChip(Icons.calendar_today, 'Date: $formattedDate',
                    isSmallScreen),
              ],
            ),
            Text('Criteria: ${goal.goalCriteria}'),

            // Add proof text if available
            if (proofText != 'No details provided') ...[
              const Divider(),
              Text('Proof: $proofText'),
            ],

            // Add image if available
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const Divider(),
              Center(
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, imageUrl!),
                  child: Hero(
                    tag: 'proof-image-$imageUrl',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: isSmallScreen ? 200 : 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: isSmallScreen ? 200 : 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
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
            ],

            const SizedBox(height: 16),

            // Action buttons - different layout for mobile
            if (isSelfApproval) ...[
              // Self-approval not allowed - show message instead
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You can't review your own proof. Another party member needs to verify it.",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isSmallScreen) ...[
              // Mobile layout for other users
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => onAction(goal.id, date, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => onAction(goal.id, date, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Deny'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Desktop layout for other users
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onAction(goal.id, date, false),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Deny'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onAction(goal.id, date, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a card for a total goal proof
  Widget _buildTotalGoalItem(BuildContext context, bool isSmallScreen) {
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

    // Check if this is the user's own goal
    final isSelfApproval = _isOwnGoal();

    return Card(
      margin: EdgeInsets.symmetric(
          vertical: 8.0, horizontal: isSmallScreen ? 8.0 : 16.0),
      elevation: isSmallScreen ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Goal: ${goal.goalName}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.person, 'User: $userName', isSmallScreen),
                _buildInfoChip(Icons.calendar_today, 'Date: $formattedDate',
                    isSmallScreen),
              ],
            ),
            const SizedBox(height: 4),
            Text('Criteria: ${goal.goalCriteria}'),
            const Divider(),
            Text('Proof: $proofText'),

            // If we have an image URL, show the image
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const Divider(),
              Center(
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, imageUrl!),
                  child: Hero(
                    tag: 'proof-image-$imageUrl',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: isSmallScreen ? 200 : 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: isSmallScreen ? 200 : 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
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
            ],

            const SizedBox(height: 16),

            // Action buttons - different based on whether it's self-approval
            if (isSelfApproval) ...[
              // Self-approval not allowed - show message instead
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You can't review your own proof. Another party member needs to verify it.",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isSmallScreen) ...[
              // Mobile layout for other users
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => onAction(goal.id, date, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => onAction(goal.id, date, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Deny'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Desktop layout for other users
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onAction(goal.id, date, false),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Deny'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onAction(goal.id, date, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      // Full-screen viewer for mobile
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Image Proof',
                  style: TextStyle(color: Colors.white)),
            ),
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20.0),
                minScale: 0.5,
                maxScale: 3.0,
                child: Hero(
                  tag: 'proof-image-$imageUrl',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Text(
                            'Error loading image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Dialog for desktop
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Stack(
            children: [
              InteractiveViewer(
                child: Hero(
                  tag: 'proof-image-$imageUrl',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
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
  }
}
