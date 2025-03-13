import 'package:auth_test/features/goals/screens/create_party_screen.dart';
import 'package:auth_test/screens/party/party_info_screen.dart';
import 'package:auth_test/features/party/widgets/invite_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/party_provider.dart';
import '../../goals/providers/goals_provider.dart';
import '../../time_machine/providers/time_machine_provider.dart';
import '../widgets/proof_approval_widget.dart';

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PartyScreenContent();
  }
}

class PartyScreenContent extends StatefulWidget {
  const PartyScreenContent({Key? key}) : super(key: key);

  @override
  _PartyScreenContentState createState() => _PartyScreenContentState();
}

class _PartyScreenContentState extends State<PartyScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<PartyProvider, GoalsProvider, Tuple2<bool, String?>>(
      selector: (_, partyProvider, goalsProvider) =>
          Tuple2(partyProvider.isLoading, partyProvider.partyId),
      builder: (context, data, child) {
        final isLoading = data.item1;
        final partyId = data.item2;

        if (isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text("Accountabilibuddies")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

// Replace the existing "no party" view with this updated version:

        if (partyId == null) {
          // No party view - with goal setup option
          return Scaffold(
            appBar: AppBar(title: const Text("Accountabilibuddies")),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.group_outlined,
                      size: 100,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.7),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Let's get set up!",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Create a party, join one with friends, or start by setting up your personal goals.",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Two action buttons side by side
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => CreatePartyDialog(),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Create a Party"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to the goals page
                              GoRouter.of(context).go('/goals');
                            },
                            icon: const Icon(Icons.flag),
                            label: const Text("Set Up My Goals"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Explanation section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Getting Started",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.looks_one, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Set up your personal goals that you want to track",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.looks_two, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Create or join a party with friends",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.looks_3, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Challenge each other to stay accountable",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Pending invites section (unchanged)
                    StreamBuilder(
                      stream: Provider.of<PartyProvider>(context, listen: false)
                          .fetchIncomingPendingInvites(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final List<Map<String, dynamic>> invites =
                            snapshot.data?.docs
                                    .map((doc) => {
                                          ...doc.data() as Map<String, dynamic>,
                                          'id': doc.id,
                                        })
                                    .toList() ??
                                [];

                        if (invites.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You have pending invites!",
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 12),
                            ...invites.map((invite) {
                              final partyProvider = Provider.of<PartyProvider>(
                                  context,
                                  listen: false);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                      invite['partyName'] ?? 'Unknown party'),
                                  subtitle: Text(
                                      "From: ${invite['senderEmail'] ?? 'Unknown'}"),
                                  trailing: ElevatedButton(
                                    onPressed: () => partyProvider.acceptInvite(
                                        invite['id'], invite['partyId']),
                                    child: const Text("Accept"),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Party exists view with tabs
        return Scaffold(
          appBar: AppBar(
            title: Text(Provider.of<PartyProvider>(context).partyName ??
                "Accountabilibuddies"),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Party Info"),
                Tab(text: "Pending Approvals"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              PartyInfoTab(),
              PendingApprovalsTab(),
            ],
          ),
        );
      },
    );
  }
}

// Create Party Dialog
class CreatePartyDialog extends StatelessWidget {
  CreatePartyDialog({Key? key}) : super(key: key);

  final TextEditingController _partyNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Create New Party'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter a name for your new party'),
          const SizedBox(height: 16),
          TextField(
            controller: _partyNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Party Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final partyName = _partyNameController.text.trim();
            if (partyName.isNotEmpty) {
              Navigator.pop(context);
              partyProvider.createParty(partyName);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// Party Info Tab - scrollable
class PartyInfoTab extends StatelessWidget {
  const PartyInfoTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartyInfoScreen(
            partyId: partyProvider.partyId!,
            partyName: partyProvider.partyName!,
            members: partyProvider.members,
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Send Invite"),
                  onPressed: partyProvider.isCurrentUserPartyLeader
                      ? partyProvider.sendInvite
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InviteList(
            inviteStream: partyProvider.fetchOutgoingPendingInvites(),
            title: "Outgoing Pending Invites",
            onAction: (inviteId, _) => partyProvider.cancelInvite(inviteId),
            isOutgoing: true,
          ),
        ],
      ),
    );
  }
}

// Pending Approvals Tab - dedicated to showing and handling proofs
class PendingApprovalsTab extends StatelessWidget {
  const PendingApprovalsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Submitted Proofs",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Expanded(
          child: PendingProofsWidget(),
        ),
      ],
    );
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tuple2 && other.item1 == item1 && other.item2 == item2;
  }

  @override
  int get hashCode => item1.hashCode ^ item2.hashCode;
}
