import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/party_provider.dart';
import '../../goals/models/goal_model.dart';
import '../../goals/models/weekly_goal.dart';
import '../../goals/models/total_goal.dart';
import 'proof_item_widget.dart';
import '../../common/utils/utils.dart';

class PendingProofsWidget extends StatelessWidget {
  const PendingProofsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use party provider to get current members and their goals
    return Consumer<PartyProvider>(
      builder: (context, partyProvider, _) {
        // If party is loading, show loading indicator
        if (partyProvider.isLoading) {
          return const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Process current goals to find pending proofs
        final pendingProofs = _getPendingProofs(context, partyProvider);

        if (pendingProofs.isEmpty) {
          return const Center(child: Text('No pending proofs'));
        }

        return ListView.builder(
          itemCount: pendingProofs.length,
          itemBuilder: (context, index) {
            final proofData = pendingProofs[index];
            // Build proof item widget
            return ProofItem(
              key: ValueKey(
                  '${proofData['goalId']}-${proofData['date'] ?? 'total'}-${proofData['userId']}'),
              goal: proofData['goal'],
              userName: proofData['userName'],
              userId: proofData['userId'],
              date: proofData['date'],
              proof: proofData['proof'],
              onAction: _handleProofAction,
            );
          },
        );
      },
    );
  }

  // Process current party data to find pending proofs
  List<Map<String, dynamic>> _getPendingProofs(
      BuildContext context, PartyProvider partyProvider) {
    final List<Map<String, dynamic>> result = [];

    // Iterate through all members and their goals
    partyProvider.partyMemberGoals.forEach((userId, goals) {
      final userName = partyProvider.memberDetails[userId]?['displayName'] ??
          partyProvider.memberDetails[userId]?['username'] ??
          partyProvider.memberDetails[userId]?['email'] ??
          'Unknown User';

      for (final goal in goals) {
        if (goal is WeeklyGoal) {
          // Find days with submitted status
          goal.currentWeekCompletions.forEach((date, status) {
            if (status == 'submitted' && goal.proofs.containsKey(date)) {
              result.add({
                'goal': goal,
                'goalId': goal.id,
                'userId': userId,
                'userName': userName,
                'date': date,
                'proof': goal.proofs[date],
              });
            }
          });
        } else if (goal is TotalGoal) {
          // Add total goal proofs
          for (var proof in goal.proofs) {
            result.add({
              'goal': goal,
              'goalId': goal.id,
              'userId': userId,
              'userName': userName,
              'date': null,
              'proof': proof,
            });
          }
        }
      }
    });

    return result;
  }

  // Handle proof approval/denial
  Future<void> _handleProofAction(
      String goalId, String? date, bool isApprove) async {
    // Implementation needs to be in a StatefulWidget to access context properly
    // This is a placeholder that will be overridden by the actual implementation
  }
}

// StatefulWrapper to handle proof actions
class PendingProofsStatefulWrapper extends StatefulWidget {
  const PendingProofsStatefulWrapper({Key? key}) : super(key: key);

  @override
  _PendingProofsStatefulWrapperState createState() =>
      _PendingProofsStatefulWrapperState();
}

class _PendingProofsStatefulWrapperState
    extends State<PendingProofsStatefulWrapper> {
  Future<void> _handleProofAction(
      String goalId, String? date, bool isApprove) async {
    // Find the index of the item before removing it
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    // Store context in a local variable before async operations
    final BuildContext currentContext = context;

    try {
      if (isApprove) {
        await partyProvider.approveProof(goalId, date);
        if (mounted) {
          Utils.showFeedback(currentContext, 'Proof approved');
        }
      } else {
        await partyProvider.denyProof(goalId, date);
        if (mounted) {
          Utils.showFeedback(currentContext, 'Proof denied');
        }
      }
    } catch (e) {
      if (mounted) {
        Utils.showFeedback(currentContext, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PendingProofsWidget();
  }
}
