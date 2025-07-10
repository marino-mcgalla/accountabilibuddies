import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/multi_party_provider.dart';
import '../models/party_model_multi.dart';
import '../widgets/party_member_widget.dart';
import '../widgets/party_settings_widget.dart';
import '../widgets/sent_invitations_widget.dart';

class PartyDetailScreen extends StatefulWidget {
  final String partyId;

  const PartyDetailScreen({
    super.key,
    required this.partyId,
  });

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiPartyProvider>(
      builder: (context, provider, child) {
        final party = provider.getPartyById(widget.partyId);
        
        if (party == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Party Not Found'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64),
                  SizedBox(height: 16),
                  Text('Party not found or no longer exists'),
                ],
              ),
            ),
          );
        }

        final isLeader = party.isLeader(provider.currentUserId ?? '');

        return Scaffold(
          appBar: AppBar(
            title: Text(party.name),
            actions: [
              if (isLeader)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showInviteMemberDialog(context, party, provider),
                  tooltip: 'Invite Member',
                ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, party, provider),
                itemBuilder: (context) => [
                  if (isLeader) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Party'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete Party'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ] else ...[
                    const PopupMenuItem(
                      value: 'leave',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.orange),
                        title: Text('Leave Party'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Members', icon: Icon(Icons.people)),
                Tab(text: 'Invites', icon: Icon(Icons.mail)),
                Tab(text: 'Settings', icon: Icon(Icons.settings)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMembersTab(context, party, provider),
              _buildInvitesTab(context, party, provider),
              _buildSettingsTab(context, party, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(BuildContext context, MultiParty party, MultiPartyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Party Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Party Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatItem(
                        context,
                        Icons.people,
                        'Members',
                        party.memberCount.toString(),
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        Icons.schedule,
                        'Duration',
                        party.challengeDurationDisplayName,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        context,
                        Icons.calendar_today,
                        'Start Day',
                        party.startDayDisplayName,
                      ),
                    ],
                  ),
                  if (party.hasActiveChallenge) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Active Challenge Running',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Members List
          Text(
            'Members (${party.memberCount})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: party.members.length,
            itemBuilder: (context, index) {
              final memberId = party.members[index];
              return PartyMemberWidget(
                memberId: memberId,
                party: party,
                isCurrentUser: memberId == provider.currentUserId,
                onRemove: party.isLeader(provider.currentUserId ?? '') && 
                         !party.isLeader(memberId)
                    ? () => _showRemoveMemberDialog(context, memberId, party, provider)
                    : null,
                onTransferLeadership: party.isLeader(provider.currentUserId ?? '') && 
                                    !party.isLeader(memberId)
                    ? () => _showTransferLeadershipDialog(context, memberId, party, provider)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvitesTab(BuildContext context, MultiParty party, MultiPartyProvider provider) {
    final isLeader = party.isLeader(provider.currentUserId ?? '');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLeader) ...[
            // Invite New Member Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite New Members',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invite friends to join your party by email address',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showInviteMemberDialog(context, party, provider),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Send Invitation'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Sent Invitations
          Text(
            'Sent Invitations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          SentInvitationsWidget(
            partyId: party.id,
            sentInvitations: provider.getSentInvitationsForParty(party.id),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, MultiParty party, MultiPartyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PartySettingsWidget(
        party: party,
        isLeader: party.isLeader(provider.currentUserId ?? ''),
        onUpdateSettings: (settings) => _updatePartySettings(context, party, settings, provider),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    MultiParty party,
    MultiPartyProvider provider,
  ) {
    switch (action) {
      case 'edit':
        _showEditPartyDialog(context, party, provider);
        break;
      case 'delete':
        _showDeletePartyDialog(context, party, provider);
        break;
      case 'leave':
        _showLeavePartyDialog(context, party, provider);
        break;
    }
  }

  void _showInviteMemberDialog(BuildContext context, MultiParty party, MultiPartyProvider provider) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter email address',
              ),
              keyboardType: TextInputType.emailAddress,
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
              if (emailController.text.trim().isEmpty) return;
              
              Navigator.of(context).pop();
              
              final success = await provider.sendInvitation(
                party.id,
                emailController.text.trim(),
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? 'Invitation sent successfully!'
                          : 'Failed to send invitation',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showEditPartyDialog(BuildContext context, MultiParty party, MultiPartyProvider provider) {
    final nameController = TextEditingController(text: party.name);
    String challengeDuration = party.challengeDuration;
    String startDay = party.startDay;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Party'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Party Name',
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
                
                final updatedParty = party.copyWith(
                  name: nameController.text.trim(),
                  challengeDuration: challengeDuration,
                  startDay: startDay,
                );
                
                final success = await provider.updateParty(updatedParty);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                            ? 'Party updated successfully!'
                            : 'Failed to update party',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePartyDialog(BuildContext context, MultiParty party, MultiPartyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Party'),
        content: Text(
          'Are you sure you want to delete "${party.name}"? This action cannot be undone and will remove all members.',
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
              
              if (mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Go back to party list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted party "${party.name}"'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  void _showLeavePartyDialog(BuildContext context, MultiParty party, MultiPartyProvider provider) {
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
              
              if (mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Go back to party list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Left party "${party.name}"'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    String memberId,
    MultiParty party,
    MultiPartyProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member from the party?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.removeMember(party.id, memberId);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? 'Member removed successfully'
                          : 'Failed to remove member',
                    ),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showTransferLeadershipDialog(
    BuildContext context,
    String memberId,
    MultiParty party,
    MultiPartyProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Leadership'),
        content: const Text(
          'Are you sure you want to transfer leadership to this member? You will become a regular member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.transferLeadership(party.id, memberId);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? 'Leadership transferred successfully'
                          : 'Failed to transfer leadership',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  void _updatePartySettings(
    BuildContext context,
    MultiParty party,
    Map<String, dynamic> settings,
    MultiPartyProvider provider,
  ) async {
    final updatedParty = party.updateSettings(settings);
    final success = await provider.updateParty(updatedParty);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Settings updated successfully!'
                : 'Failed to update settings',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}