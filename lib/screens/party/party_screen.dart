import 'package:auth_test/screens/party/create_party_screen.dart';
import 'package:auth_test/screens/party/party_info_screen.dart';
import 'package:auth_test/widgets/invite_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../refactor/party_provider.dart';
import '../../refactor/goals_provider.dart';
import '../../refactor/goal_model.dart';

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);

    if (partyProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Party")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Party 2.0")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: partyProvider.partyId == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CreatePartyScreen(),
                  const SizedBox(height: 20),
                  InviteList(
                    inviteStream: partyProvider.fetchIncomingPendingInvites(),
                    title: "Incoming Pending Invites",
                    onAction: (inviteId, partyId) =>
                        partyProvider.acceptInvite(inviteId, partyId),
                    isOutgoing: false,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PartyInfoScreen(
                    partyId: partyProvider.partyId!,
                    partyName: partyProvider.partyName!,
                    members: partyProvider.members,
                    updateCounter: partyProvider.updateCounter,
                    leaveParty: partyProvider.leaveParty,
                    closeParty: partyProvider.closeParty,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: partyProvider.inviteController,
                    decoration: const InputDecoration(
                      labelText: "Invite Member by Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: partyProvider.sendInvite,
                    child: const Text("Send Invite"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => partyProvider.endWeekForAll(context),
                    child: const Text("End Week for All"),
                  ),
                  const SizedBox(height: 20),
                  InviteList(
                    inviteStream: partyProvider.fetchOutgoingPendingInvites(),
                    title: "Outgoing Pending Invites",
                    onAction: (inviteId, _) =>
                        partyProvider.cancelInvite(inviteId),
                    isOutgoing: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Submitted Proofs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: partyProvider.fetchSubmittedGoalsForParty(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text("No submitted proofs"));
                        }
                        final submittedGoals = snapshot.data!;
                        return ListView.builder(
                          itemCount: submittedGoals.length,
                          itemBuilder: (context, index) {
                            final goalData = submittedGoals[index];
                            final Goal goal = goalData['goal'];
                            final String? date = goalData['date'];
                            return ListTile(
                              title: Text(goal.goalName),
                              subtitle: Text(
                                  "Submitted by: ${goal.ownerId}\nDate: ${date ?? 'N/A'}"),
                              onTap: () {
                                _showProofDialog(context, goal, date);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showProofDialog(BuildContext context, Goal goal, String? proofDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Proof for ${goal.goalName}"),
          content: Text(goal.proofText ?? "No proof provided."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<GoalsProvider>(context, listen: false)
                    .approveProof(goal.id, goal.ownerId, proofDate);
                Navigator.of(context).pop();
              },
              child: const Text("Approve"),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<GoalsProvider>(context, listen: false)
                    .denyProof(goal.id, goal.ownerId, proofDate);
                Navigator.of(context).pop();
              },
              child: const Text("Deny"),
            ),
          ],
        );
      },
    );
  }
}
