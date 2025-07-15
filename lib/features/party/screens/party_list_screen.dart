import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/multi_party_provider.dart';
import '../models/party_model_multi.dart';
import '../widgets/party_list_item.dart';
import '../widgets/invitation_list_widget.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePartyDialog(context),
            tooltip: 'Create Party',
          ),
        ],
      ),
      body: Consumer<MultiPartyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading parties',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending Invitations Section
                if (provider.hasPendingInvitations) ...[
                  _buildSectionHeader(
                    context,
                    'Pending Invitations',
                    Icons.mail_outline,
                    provider.pendingInvitations.length,
                  ),
                  const SizedBox(height: 12),
                  InvitationListWidget(
                    invitations: provider.pendingInvitations,
                    onAccept: (inviteId) => provider.acceptInvitation(inviteId),
                    onDecline: (inviteId) => provider.declineInvitation(inviteId),
                  ),
                  const SizedBox(height: 24),
                ],

                // Current Parties Section
                if (provider.hasParties) ...[
                  _buildSectionHeader(
                    context,
                    'My Parties',
                    Icons.groups,
                    provider.userParties.length,
                  ),
                  const SizedBox(height: 12),
                  _buildPartiesList(context, provider.userParties, provider),
                ] else ...[
                  _buildEmptyState(context),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePartyDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Party'),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    int count,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartiesList(
    BuildContext context,
    List<MultiParty> parties,
    MultiPartyProvider provider,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: parties.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final party = parties[index];
        return PartyListItem(
          party: party,
          isSelected: party.id == provider.currentPartyId,
          onTap: () {
            provider.setCurrentParty(party.id);
            context.go('/party/${party.id}');
          },
          onLeave: () => _showLeavePartyDialog(context, party, provider),
          onDelete: party.isLeader(provider.currentUser?.uid ?? '')
              ? () => _showDeletePartyDialog(context, party, provider)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'No Parties Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first party to start\naccountability challenges with friends',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreatePartyDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Party'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showJoinPartyDialog(context),
            icon: const Icon(Icons.group_add),
            label: const Text('Join Party'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePartyDialog(BuildContext context) {
    final nameController = TextEditingController();
    String challengeDuration = 'weekly';
    String startDay = 'monday';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Party'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Party Name',
                  hintText: 'Enter party name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: challengeDuration,
                decoration: const InputDecoration(
                  labelText: 'Challenge Duration',
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => challengeDuration = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: startDay,
                decoration: const InputDecoration(
                  labelText: 'Challenge Start Day',
                ),
                items: const [
                  DropdownMenuItem(value: 'monday', child: Text('Monday')),
                  DropdownMenuItem(value: 'tuesday', child: Text('Tuesday')),
                  DropdownMenuItem(value: 'wednesday', child: Text('Wednesday')),
                  DropdownMenuItem(value: 'thursday', child: Text('Thursday')),
                  DropdownMenuItem(value: 'friday', child: Text('Friday')),
                  DropdownMenuItem(value: 'saturday', child: Text('Saturday')),
                  DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => startDay = value);
                  }
                },
              ),
            ],
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
                
                final provider = context.read<MultiPartyProvider>();
                final success = await provider.createParty(
                  name: nameController.text.trim(),
                  challengeDuration: challengeDuration,
                  startDay: startDay,
                );

                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Party created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinPartyDialog(BuildContext context) {
    // Placeholder for join party functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Join party feature coming soon!'),
      ),
    );
  }

  void _showLeavePartyDialog(
    BuildContext context,
    MultiParty party,
    MultiPartyProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Party'),
        content: Text(
          'Are you sure you want to leave "${party.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.leaveParty(party.id);
              
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Left party "${party.name}"'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showDeletePartyDialog(
    BuildContext context,
    MultiParty party,
    MultiPartyProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Party'),
        content: Text(
          'Are you sure you want to delete "${party.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.deleteParty(party.id);
              
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted party "${party.name}"'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}