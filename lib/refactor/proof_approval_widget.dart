import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'party_provider.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';

class PendingProofsWidget extends StatefulWidget {
  const PendingProofsWidget({Key? key}) : super(key: key);

  @override
  _PendingProofsWidgetState createState() => _PendingProofsWidgetState();
}

class _PendingProofsWidgetState extends State<PendingProofsWidget> {
  // Cache submitted goals to prevent unnecessary rebuilds
  List<Map<String, dynamic>> _submittedGoals = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    // Load data when widget initializes
    _loadSubmittedGoals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when provider changes
    _loadSubmittedGoals();
  }

  Future<void> _loadSubmittedGoals() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingData) return;
    _isLoadingData = true;

    // Store context before the async gap
    final BuildContext currentContext = context;

    // Only set loading state if we're not already showing results
    if (_submittedGoals.isEmpty && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Get provider before async operation
      final partyProvider =
          Provider.of<PartyProvider>(currentContext, listen: false);
      final submittedGoals = await partyProvider.fetchSubmittedGoalsForParty();

      // Make sure the widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _submittedGoals = submittedGoals;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      // Make sure the widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading proofs: $e';
        _isLoading = false;
      });
    } finally {
      _isLoadingData = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only listen for party member goals changes, not everything in the provider
    return Selector<PartyProvider, Map<String, List<Goal>>>(
      selector: (_, provider) => provider.partyMemberGoals,
      builder: (context, partyMemberGoals, child) {
        // When party members' goals change, reload our data
        // But use debounce to avoid UI jitter
        if (!_isLoadingData) {
          Future.microtask(() {
            if (mounted) {
              _loadSubmittedGoals();
            }
          });
        }

        if (_isLoading && _submittedGoals.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_errorMessage != null) {
          return Center(child: Text(_errorMessage!));
        }

        if (_submittedGoals.isEmpty) {
          return const Center(child: Text('No pending proofs'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            key: ValueKey<int>(_submittedGoals
                .length), // Key based on list length to animate changes
            shrinkWrap: true,
            itemCount: _submittedGoals.length,
            itemBuilder: (context, index) {
              final goalData = _submittedGoals[index];
              final Goal goal = goalData['goal'];
              final String userId = goalData['userId'];

              // Get user name from member details
              final partyProvider =
                  Provider.of<PartyProvider>(context, listen: false);
              final String userName = partyProvider.memberDetails[userId]
                      ?['displayName'] ??
                  'Unknown User';

              if (goal is WeeklyGoal && goalData.containsKey('date')) {
                final String date = goalData['date'];
                return _buildWeeklyGoalItem(
                    context, goal, userName, date, index);
              } else if (goal is TotalGoal && goalData.containsKey('proof')) {
                final Map<String, dynamic> proof = goalData['proof'];
                return _buildTotalGoalItem(
                    context, goal, userName, proof, index);
              }

              return const SizedBox.shrink(); // Empty fallback
            },
          ),
        );
      },
    );
  }

  Widget _buildWeeklyGoalItem(BuildContext context, WeeklyGoal goal,
      String userName, String date, int index) {
    // Format date for display
    final DateTime dateObj = DateTime.parse(date);
    final String formattedDate =
        '${dateObj.month}/${dateObj.day}/${dateObj.year}';

    return Card(
      key: ValueKey('weekly-${goal.id}-$date-$index'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ProofActionButton(
                  label: 'Deny',
                  color: Colors.red,
                  onPressed: () => _handleAction(goal.id, date, false, index),
                ),
                const SizedBox(width: 8),
                _ProofActionButton(
                  label: 'Approve',
                  color: Colors.green,
                  onPressed: () => _handleAction(goal.id, date, true, index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalGoalItem(BuildContext context, TotalGoal goal,
      String userName, Map<String, dynamic> proof, int index) {
    // Extract proof details
    final String proofText = proof['proofText'] ?? 'No details provided';
    final String submissionDate = proof['submissionDate'] ?? '';

    // Format submission date if available
    String formattedDate = 'Unknown date';
    if (submissionDate.isNotEmpty) {
      final DateTime dateObj = DateTime.parse(submissionDate);
      formattedDate = '${dateObj.month}/${dateObj.day}/${dateObj.year}';
    }

    return Card(
      key: ValueKey('total-${goal.id}-$index'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ProofActionButton(
                  label: 'Deny',
                  color: Colors.red,
                  onPressed: () => _handleAction(goal.id, null, false, index),
                ),
                const SizedBox(width: 8),
                _ProofActionButton(
                  label: 'Approve',
                  color: Colors.green,
                  onPressed: () => _handleAction(goal.id, null, true, index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      String goalId, String? date, bool isApprove, int index) async {
    // Store context in a local variable before async operations
    final BuildContext currentContext = context;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Remove the item from our local list immediately for better UX
    if (mounted) {
      setState(() {
        // Since we're removing the item, all the remaining items will shift
        // so we need to be careful about our indexes
        _submittedGoals.removeAt(index);
      });
    }

    final partyProvider =
        Provider.of<PartyProvider>(currentContext, listen: false);

    try {
      if (isApprove) {
        await partyProvider.approveProof(goalId, date);
        // Show feedback only if still mounted
        if (mounted) {
          _showFeedback(currentContext, 'Proof approved');
        }
      } else {
        await partyProvider.denyProof(goalId, date);
        // Show feedback only if still mounted
        if (mounted) {
          _showFeedback(currentContext, 'Proof denied');
        }
      }
    } catch (e) {
      // Only add the item back if there was an error
      if (mounted) {
        _showFeedback(currentContext, 'Error: $e', isError: true);

        // Reload data if there was an error
        _loadSubmittedGoals();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFeedback(BuildContext context, String message,
      {bool isError = false}) {
    // Get a global key for the scaffold messenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Check if the scaffold messenger is still active
    if (scaffoldMessenger.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Stateful button that shows loading state
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
                child: Text(widget.label),
                style: TextButton.styleFrom(foregroundColor: widget.color),
              )
            : ElevatedButton(
                onPressed: _handlePress,
                child: Text(widget.label),
                style: ElevatedButton.styleFrom(backgroundColor: widget.color),
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
