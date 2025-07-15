import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../party/providers/party_provider.dart';

class CreatePartyScreen extends StatelessWidget {
  const CreatePartyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: partyProvider.partyNameController,
          decoration: const InputDecoration(
            labelText: "Party Name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () =>
              partyProvider.createParty(partyProvider.partyNameController.text),
          child: const Text("Create Party"),
        ),
      ],
    );
  }
}
