import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_party_screen.dart';
import 'party_info_screen.dart';
import '../../widgets/invite_list.dart';
import '../../refactor/party_provider.dart';

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
      appBar: AppBar(title: const Text("Party")),
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
                ],
              ),
      ),
    );
  }
}
