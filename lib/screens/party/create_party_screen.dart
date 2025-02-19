import 'package:flutter/material.dart';

class CreatePartyScreen extends StatelessWidget {
  final TextEditingController partyNameController;
  final Function() createParty;

  const CreatePartyScreen({
    required this.partyNameController,
    required this.createParty,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: partyNameController,
          decoration: const InputDecoration(
            labelText: "Party Name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: createParty,
          child: const Text("Create Party"),
        ),
      ],
    );
  }
}
