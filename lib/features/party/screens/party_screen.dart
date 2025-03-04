import 'package:auth_test/features/goals/screens/create_party_screen.dart';
import 'package:auth_test/screens/party/party_info_screen.dart';
import 'package:auth_test/features/party/widgets/invite_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/party_provider.dart';
import '../../goals/providers/goals_provider.dart';
import '../../time_machine/providers/time_machine_provider.dart';
import '../widgets/proof_approval_widget.dart';

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PartyProvider>(create: (_) => PartyProvider()),
        ChangeNotifierProvider<GoalsProvider>(
          create: (_) => GoalsProvider(TimeMachineProvider()),
        ),
      ],
      child: const PartyScreenContent(),
    );
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
            appBar: AppBar(title: const Text("Party")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (partyId == null) {
          // No party view
          return Scaffold(
            appBar: AppBar(title: const Text("Party 2.0")),
            body: const Padding(
              padding: EdgeInsets.all(16.0),
              child: CreatePartyView(),
            ),
          );
        }

        // Party exists view with tabs
        return Scaffold(
          appBar: AppBar(
            title: Text(
                Provider.of<PartyProvider>(context).partyName ?? "Party 2.0"),
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

// Separate widget for create party view
class CreatePartyView extends StatelessWidget {
  const CreatePartyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Column(
        key: const ValueKey<String>('create-party'),
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
      ),
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

// Helper class for multiple return values
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
