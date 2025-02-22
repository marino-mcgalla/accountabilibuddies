import 'package:flutter/material.dart';
import '../../refactor/compact_progress_tracker.dart';
import '../../refactor/party_provider.dart';
import 'package:provider/provider.dart';
import '../../refactor/goal_model.dart';

class PartyInfoScreen extends StatelessWidget {
  final String partyId;
  final String partyName;
  final List<String> members;
  final Function(String, int) updateCounter;
  final Function() leaveParty;
  final Function() closeParty;

  const PartyInfoScreen({
    required this.partyId,
    required this.partyName,
    required this.members,
    required this.updateCounter,
    required this.leaveParty,
    required this.closeParty,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Party ID: $partyId"),
        Text("Party Name: $partyName"),
        const SizedBox(height: 20),
        ...members.map((member) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (partyProvider.memberDetails.containsKey(member))
                  Text(partyProvider.memberDetails[member]?['email'] ??
                      ''), //TODO: change this to username after user refactor
                FutureBuilder<List<Goal>>(
                  future: partyProvider.fetchGoalsForUser(member),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Text('Error loading goals');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No goals found');
                    } else {
                      return Column(
                        children: snapshot.data!
                            .map((goal) => CompactProgressTracker(goal: goal))
                            .toList(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            )),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: leaveParty,
          child: const Text("Leave Party"),
        ),
        ElevatedButton(
          onPressed: closeParty,
          child: const Text("Close Party"),
        ),
      ],
    );
  }
}
