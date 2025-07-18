import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_party_provider.dart';

class SimpleJoinPartyScreen extends StatefulWidget {
  const SimpleJoinPartyScreen({super.key});

  @override
  State<SimpleJoinPartyScreen> createState() => _SimpleJoinPartyScreenState();
}

class _SimpleJoinPartyScreenState extends State<SimpleJoinPartyScreen> {
  final _partyIdController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _partyIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Party'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join a Party',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter the Party ID to join an existing party. You can get this from the party leader.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _partyIdController,
                      decoration: InputDecoration(
                        labelText: 'Party ID',
                        hintText: 'Enter party ID',
                        border: const OutlineInputBorder(),
                        errorText: _error,
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _joinParty,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Join Party'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Invitations',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Consumer<SimplePartyProvider>(
                      builder: (context, provider, child) {
                        if (provider.invitations.isEmpty) {
                          return const Text('No pending invitations');
                        }

                        return Column(
                          children: provider.invitations.map((invitation) {
                            return ListTile(
                              leading: const Icon(Icons.mail),
                              title: Text(invitation['partyName']),
                              subtitle: const Text('Party invitation'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _acceptInvitation(
                                      provider,
                                      invitation['id'],
                                      invitation['partyId'],
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                  TextButton(
                                    onPressed: () => _declineInvitation(
                                      provider,
                                      invitation['id'],
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinParty() async {
    final partyId = _partyIdController.text.trim();
    if (partyId.isEmpty) {
      setState(() {
        _error = 'Please enter a party ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<SimplePartyProvider>();
    final success = await provider.joinParty(partyId);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined party successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _error = 'Failed to join party. Please check the Party ID.';
        });
      }
    }
  }

  Future<void> _acceptInvitation(SimplePartyProvider provider, String invitationId, String partyId) async {
    final success = await provider.acceptInvitation(invitationId, partyId);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineInvitation(SimplePartyProvider provider, String invitationId) async {
    final success = await provider.declineInvitation(invitationId);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}