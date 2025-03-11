import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/party_provider.dart';
import '../../goals/models/goal_model.dart';
import 'proof_item_widget.dart';
import '../../common/utils/utils.dart';

class PendingProofsWidget extends StatelessWidget {
  const PendingProofsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: partyProvider.streamSubmittedProofs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final submittedGoals = snapshot.data ?? [];
        if (submittedGoals.isEmpty) {
          return const Center(child: Text('No pending proofs'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: submittedGoals.length,
            itemBuilder: (context, index) {
              final goalData = submittedGoals[index];
              final Goal goal = goalData['goal'];
              final String userId = goalData['userId'];

              final String userName = partyProvider.memberDetails[userId]
                      ?['displayName'] ??
                  partyProvider.memberDetails[userId]?['username'] ??
                  partyProvider.memberDetails[userId]?['email'] ??
                  'Unknown User';

              final String proofKey =
                  '${goal.id}-${goalData['date'] ?? 'total'}-$userId-$index';

              return ProofItem(
                key: ValueKey(proofKey),
                goal: goal,
                userName: userName,
                userId: userId,
                date: goalData['date'],
                proof: goalData['proof'],
                onAction: (goalId, date, isApprove) =>
                    _handleAction(context, userId, goalId, date, isApprove),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleAction(BuildContext context, String userId, String goalId,
      String? date, bool isApprove) async {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    try {
      if (isApprove) {
        await partyProvider.approveProof(userId, goalId, date);
        Utils.showFeedback(context, 'Proof approved');
      } else {
        await partyProvider.denyProof(userId, goalId, date);
        Utils.showFeedback(context, 'Proof denied');
      }
    } catch (e) {
      Utils.showFeedback(context, 'Error: $e', isError: true);
    }
  }
}
