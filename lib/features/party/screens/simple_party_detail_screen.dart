import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_party_provider.dart';

class SimplePartyDetailScreen extends StatefulWidget {
  final String partyId;

  const SimplePartyDetailScreen({
    super.key,
    required this.partyId,
  });

  @override
  State<SimplePartyDetailScreen> createState() => _SimplePartyDetailScreenState();
}

class _SimplePartyDetailScreenState extends State<SimplePartyDetailScreen> {
  Map<String, dynamic>? _partyData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPartyData();
  }

  Future<void> _loadPartyData() async {
    final provider = context.read<SimplePartyProvider>();
    
    try {
      final party = await provider.getPartyById(widget.partyId);
      if (party != null) {
        // Load user data for all members
        await provider.loadUserData(List<String>.from(party['members']));
        
        setState(() {
          _partyData = party;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Party not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading party: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Party Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _loadPartyData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_partyData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Party Details')),
        body: const Center(child: Text('Party not found')),
      );
    }

    return Consumer<SimplePartyProvider>(
      builder: (context, provider, child) {
        final party = _partyData!;
        final members = List<String>.from(party['members']);
        final isLeader = party['leaderId'] == provider.currentUserId;
        final isMember = members.contains(provider.currentUserId);

        return Scaffold(
          appBar: AppBar(
            title: Text(party['name']),
            actions: [
              if (isLeader)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'invite':
                        _showInviteDialog(context, provider);
                        break;
                      case 'delete':
                        _showDeleteDialog(context, provider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'invite',
                      child: Text('Invite Member'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Party'),
                    ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadPartyData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Party Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.groups,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    party['name'],
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  Text(
                                    '${party['memberCount']} members',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (isLeader)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Leader',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Members Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ...members.map((memberId) => _buildMemberTile(
                              context,
                              provider,
                              memberId,
                              isLeader,
                              party['leaderId'] == memberId,
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Actions Section
                if (isMember && !isLeader)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showLeaveDialog(context, provider),
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text('Leave Party'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    SimplePartyProvider provider,
    String memberId,
    bool isLeader,
    bool isMemberLeader,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          provider.getUserInitials(memberId),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(provider.getUserDisplayName(memberId)),
      subtitle: isMemberLeader ? const Text('Leader') : null,
      trailing: isMemberLeader
          ? const Icon(Icons.star, color: Colors.amber)
          : (isLeader && memberId != provider.currentUserId)
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _showRemoveMemberDialog(context, provider, memberId),
                )
              : null,
    );
  }

  void _showInviteDialog(BuildContext context, SimplePartyProvider provider) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter member\'s email',
          ),
          keyboardType: TextInputType.emailAddress,
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
                widget.partyId,
                emailController.text.trim(),
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Invitation sent!'
                        : 'Failed to send invitation'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(BuildContext context, SimplePartyProvider provider, String memberId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${provider.getUserDisplayName(memberId)} from the party?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await provider.removeMember(widget.partyId, memberId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Member removed'
                        : 'Failed to remove member'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );

                if (success) {
                  _loadPartyData(); // Refresh party data
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, SimplePartyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Party'),
        content: const Text('Are you sure you want to leave this party?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await provider.leaveParty(widget.partyId);

              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Go back to party list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Left party successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to leave party'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SimplePartyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Party'),
        content: const Text('Are you sure you want to delete this party? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await provider.deleteParty(widget.partyId);

              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Go back to party list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Party deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete party'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}