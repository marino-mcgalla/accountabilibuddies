import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_party_provider.dart';
import 'simple_party_detail_screen.dart';

class SimplePartyListScreen extends StatelessWidget {
  const SimplePartyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Parties'),
        actions: [
          Consumer<SimplePartyProvider>(
            builder: (context, provider, child) {
              final invitationCount = provider.invitations.length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail),
                    onPressed: () => _showInvitationsDialog(context, provider),
                  ),
                  if (invitationCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          invitationCount > 9 ? '9+' : invitationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePartyDialog(context),
          ),
        ],
      ),
      body: Consumer<SimplePartyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () {
                      // Just try to refresh
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SimplePartyListScreen()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasParties) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No parties yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreatePartyDialog(context),
                    child: const Text('Create Party'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.parties.length,
            itemBuilder: (context, index) {
              final party = provider.parties[index];
              return ListTile(
                title: Text(party['name']),
                subtitle: Text('${party['members'].length} members'),
                trailing: party['leaderId'] == provider.currentUserId
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SimplePartyDetailScreen(partyId: party['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePartyDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Party'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Party Name',
            hintText: 'Enter party name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              Navigator.of(context).pop();
              
              final provider = context.read<SimplePartyProvider>();
              final success = await provider.createParty(nameController.text.trim());

              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Party created!')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showInvitationsDialog(BuildContext context, SimplePartyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Party Invitations'),
        content: SizedBox(
          width: double.maxFinite,
          child: provider.invitations.isEmpty
              ? const Text('No pending invitations')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.invitations.length,
                  itemBuilder: (context, index) {
                    final invitation = provider.invitations[index];
                    return ListTile(
                      title: Text(invitation['partyName']),
                      subtitle: const Text('Party invitation'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final success = await provider.acceptInvitation(
                                invitation['id'],
                                invitation['partyId'],
                              );
                              if (context.mounted) {
                                if (success) {
                                  Navigator.of(context).pop();
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
                            },
                            child: const Text('Accept'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final success = await provider.declineInvitation(
                                invitation['id'],
                              );
                              if (context.mounted) {
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
                            },
                            child: const Text('Decline'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}