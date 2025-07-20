import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../challenges/presentation/pages/create_challenge_page.dart';
import '../../../challenges/presentation/providers/challenge_providers.dart';
import '../../domain/entities/party.dart';
import '../providers/party_providers.dart';

class PartyDetailPage extends ConsumerStatefulWidget {
  const PartyDetailPage({
    required this.partyId,
    super.key,
  });

  final String partyId;

  @override
  ConsumerState<PartyDetailPage> createState() => _PartyDetailPageState();
}

class _PartyDetailPageState extends ConsumerState<PartyDetailPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partyAsync = ref.watch(partyProvider(widget.partyId));
    final currentUser = ref.watch(userProvider);

    return partyAsync.when(
      data: (party) {
        if (party == null) {
          // Party not found, redirect to parties list
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/party');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Party not found or was deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          });
          
          // Show loading while redirecting
          return Scaffold(
            appBar: AppBar(
              title: const Text('Party Details'),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isLeader = currentUser != null && party.isLeader(currentUser!.id);

        if (isLeader) {
          // Party Leader View - with tabs
          return Scaffold(
            appBar: AppBar(
              title: Text(party.name),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Party Info', icon: Icon(Icons.info_outline)),
                  Tab(text: 'Manage Party', icon: Icon(Icons.admin_panel_settings)),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Party Info (what everyone sees)
                _PartyInfoTab(party: party, partyId: widget.partyId, currentUser: currentUser),
                // Tab 2: Manage Party (leader only)
                _ManagePartyTab(party: party, currentUser: currentUser),
              ],
            ),
          );
        } else {
          // Regular Member View - no tabs
          return Scaffold(
            appBar: AppBar(
              title: Text(party.name),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
            body: _PartyInfoTab(party: party, partyId: widget.partyId, currentUser: currentUser),
          );
        }
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Party Details'),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Party Details'),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
        body: Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _PartyInfoCard extends StatelessWidget {
  const _PartyInfoCard({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              party.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              party.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${party.memberCount} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.link,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Code: ${party.inviteCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderActionsCard extends StatelessWidget {
  const _LeaderActionsCard({
    required this.party,
    required this.onStartChallenge,
    required this.onInviteMembers,
    required this.onEditParty,
  });

  final Party party;
  final VoidCallback onStartChallenge;
  final VoidCallback onInviteMembers;
  final VoidCallback onEditParty;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Leader Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: party.canStartChallenges ? onStartChallenge : null,
                icon: const Icon(Icons.flag),
                label: const Text('Start New Challenge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            if (!party.canStartChallenges) ...[
              const SizedBox(height: 8),
              Text(
                'Need at least 2 members to start challenges',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onInviteMembers,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditParty,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentChallengeSection extends ConsumerWidget {
  const _CurrentChallengeSection({
    required this.partyId,
    required this.isLeader,
  });

  final String partyId;
  final bool isLeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChallengeAsync = ref.watch(currentChallengeProvider(partyId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Challenge',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            currentChallengeAsync.when(
              data: (challenge) {
                if (challenge == null) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No active challenge',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (isLeader) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Start a challenge to begin!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(challenge.startDate)} - ${_formatDate(challenge.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: _getStatusColor(context, challenge.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Status: ${challenge.status.name.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(context, challenge.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading challenge: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(BuildContext context, status) {
    switch (status.toString()) {
      case 'ChallengeStatus.pending':
        return Theme.of(context).colorScheme.secondary;
      case 'ChallengeStatus.active':
        return Theme.of(context).colorScheme.primary;
      case 'ChallengeStatus.settling':
        return Colors.orange;
      case 'ChallengeStatus.completed':
        return Colors.green;
      case 'ChallengeStatus.cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    }
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.party,
    required this.currentUserId,
  });

  final Party party;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Members (${party.memberCount})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...party.memberIds.map((memberId) {
              final isOwner = party.isOwner(memberId);
              final isCurrentUser = memberId == currentUserId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOwner 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  child: Text(
                    memberId.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: isOwner ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  isCurrentUser ? 'You' : 'User ${memberId.substring(0, 8)}...',
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: isOwner ? const Text('Party Leader') : null,
                trailing: isOwner 
                  ? Icon(Icons.star, color: Theme.of(context).colorScheme.primary)
                  : null,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _PartySettingsCard extends StatelessWidget {
  const _PartySettingsCard({
    required this.party,
    required this.isLeader,
    required this.onLeaveParty,
  });

  final Party party;
  final bool isLeader;
  final VoidCallback onLeaveParty;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isLeader) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLeaveParty,
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Leave Party'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'As the party leader, you cannot leave. Delete the party instead.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InviteMemberDialog extends ConsumerStatefulWidget {
  const _InviteMemberDialog({required this.party});

  final Party party;

  @override
  ConsumerState<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<_InviteMemberDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the email address of the person you want to invite to "${widget.party.name}".',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'friend@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email address';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendInvite,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Invite'),
        ),
      ],
    );
  }

  void _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(userProvider);
      if (user == null) throw Exception('User not logged in');

      final result = await ref.read(partyRepositoryProvider).sendInvite(
        partyId: widget.party.id,
        inviterUserId: user.id,
        inviterName: user.displayName ?? user.email,
        inviteeEmail: _emailController.text.trim(),
      );

      if (mounted) {
        if (result.isSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invite sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send invite: ${result.failureOrNull?.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Party Info Tab - What all members see
class _PartyInfoTab extends ConsumerStatefulWidget {
  const _PartyInfoTab({
    required this.party,
    required this.partyId,
    required this.currentUser,
  });

  final Party party;
  final String partyId;
  final UserModel? currentUser;

  @override
  ConsumerState<_PartyInfoTab> createState() => _PartyInfoTabState();
}

class _PartyInfoTabState extends ConsumerState<_PartyInfoTab> {
  bool _isLeavingVoluntarily = false;

  void _handleUserRemoved() {
    print('DEBUG: _handleUserRemoved called');
    print('DEBUG: Widget mounted? $mounted');
    
    if (!mounted) return;
    
    print('DEBUG: Showing removal dialog');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Removed from Party'),
          ],
        ),
        content: Text(
          'You have been removed from "${widget.party.name}" by the party leader.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              print('DEBUG: User clicked OK, navigating to dashboard');
              Navigator.of(context).pop(); // Close dialog
              
              // Navigate to dashboard using GoRouter
              if (context.mounted) {
                context.go('/'); // Go to dashboard/home route
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLeader = widget.currentUser != null && widget.party.isLeader(widget.currentUser!.id);

    // Listen for party changes to detect if current user was removed
    ref.listen<AsyncValue<Party?>>(partyProvider(widget.partyId), (previous, next) {
      if (widget.currentUser == null) return;
      
      print('DEBUG: Party listener triggered');
      print('DEBUG: Current user ID: ${widget.currentUser!.id}');
      
      // Check if user was removed from the party
      next.whenData((party) {
        if (party != null) {
          print('DEBUG: Party found, member IDs: ${party.memberIds}');
          print('DEBUG: User in party? ${party.memberIds.contains(widget.currentUser!.id)}');
          
          // Only trigger if the previous state had the user as a member
          if (previous != null && !_isLeavingVoluntarily) {
            previous.whenData((previousParty) {
              if (previousParty != null && 
                  previousParty.memberIds.contains(widget.currentUser!.id) &&
                  !party.memberIds.contains(widget.currentUser!.id)) {
                print('DEBUG: User was removed! Showing notification');
                // User was removed from the party
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleUserRemoved();
                });
              }
            });
          }
        } else {
          print('DEBUG: Party is null - party was deleted');
          // Party was deleted, navigate all users back to parties list
          if (previous != null) {
            previous.whenData((previousParty) {
              if (previousParty != null) {
                print('DEBUG: Party was deleted, redirecting user to parties list');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.go('/party');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('The party "${previousParty.name}" was deleted by the leader'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                });
              }
            });
          }
        }
      });
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(partyProvider(widget.partyId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party Info Card
            _PartyInfoCard(party: widget.party),
            const SizedBox(height: 16),

            // Leader Actions (quick access)
            if (isLeader) ...[
              _LeaderActionsCard(
                party: widget.party,
                onStartChallenge: () => _navigateToCreateChallenge(context, widget.party),
                onInviteMembers: () => _showInviteDialog(context, ref, widget.party),
                onEditParty: () => _showEditDialog(context, ref, widget.party),
              ),
              const SizedBox(height: 16),
            ],

            // Current Challenge Section
            _CurrentChallengeSection(partyId: widget.partyId, isLeader: isLeader),
            const SizedBox(height: 16),

            // Members Section
            _MembersSection(party: widget.party, currentUserId: widget.currentUser?.id),
            const SizedBox(height: 16),

            // Party Settings
            _PartySettingsCard(
              party: widget.party,
              isLeader: isLeader,
              onLeaveParty: () => _handleLeaveParty(context, ref, widget.party),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLeaveParty(BuildContext context, WidgetRef ref, Party party) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Party'),
        content: Text('Are you sure you want to leave "${party.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Set flag to indicate voluntary leaving
        setState(() {
          _isLeavingVoluntarily = true;
        });
        
        final controller = ref.read(partyControllerProvider);
        final success = await controller.leaveParty(party.id);
        
        if (context.mounted) {
          if (success) {
            // Navigate back to parties list using GoRouter
            context.go('/party');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Left "${party.name}" successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Reset flag if leave failed
            setState(() {
              _isLeavingVoluntarily = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to leave party'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          // Reset flag on error
          setState(() {
            _isLeavingVoluntarily = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error leaving party: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToCreateChallenge(BuildContext context, Party party) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateChallengePage(party: party),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, Party party) {
    showDialog(
      context: context,
      builder: (context) => _InviteMemberDialog(party: party),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Party party) {
    showDialog(
      context: context,
      builder: (context) => _EditPartyDialog(party: party),
    );
  }

  void _leaveParty(BuildContext context, WidgetRef ref, Party party) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Party'),
        content: Text('Are you sure you want to leave "${party.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final controller = ref.read(partyControllerProvider);
        final success = await controller.leaveParty(party.id);
        
        if (context.mounted) {
          if (success) {
            // Navigate back to parties list using GoRouter to avoid triggering removal listener
            context.go('/party');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Left "${party.name}" successfully'),
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
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error leaving party: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Manage Party Tab - Leader-only management interface
class _ManagePartyTab extends ConsumerStatefulWidget {
  const _ManagePartyTab({
    required this.party,
    required this.currentUser,
  });

  final Party party;
  final UserModel? currentUser;

  @override
  ConsumerState<_ManagePartyTab> createState() => _ManagePartyTabState();
}

class _ManagePartyTabState extends ConsumerState<_ManagePartyTab> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(partyProvider(widget.party.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Party Management',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Manage your party members and settings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Member Management Section
            _buildMemberManagement(),
            const SizedBox(height: 24),

            // Danger Zone
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showEditDialog(),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Details'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showInviteDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Invite Members'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Only show transfer leadership if there are other members
        if (widget.party.memberIds.length > 1) 
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _showTransferLeadershipDialog(),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Transfer Leadership'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberManagement() {
    if (widget.party.memberIds.length <= 1) {
      return const SizedBox.shrink(); // Don't show if only owner
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Member Management',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: widget.party.memberIds.map((memberId) {
              final isMemberOwner = widget.party.isOwner(memberId);
              final isCurrentUser = widget.currentUser?.id == memberId;
              
              if (isMemberOwner) return const SizedBox.shrink(); // Don't show owner
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  child: Text(
                    memberId.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  isCurrentUser ? 'You' : 'User ${memberId.substring(0, 8)}...',
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  'Party Member',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _transferOwnership(memberId),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Transfer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _removeMember(memberId),
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            }).where((widget) => widget is! SizedBox).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Party',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Permanently delete this party and remove all members. This action cannot be undone.',
                  style: TextStyle(color: Colors.red[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _deleteParty,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Party'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => _EditPartyDialog(party: widget.party),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteMemberDialog(party: widget.party),
    );
  }

  Future<void> _removeMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove this member from "${widget.party.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(partyControllerProvider);
      final success = await controller.removeMember(widget.party.id, memberId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove member'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showTransferLeadershipDialog() {
    showDialog(
      context: context,
      builder: (context) => _TransferLeadershipDialog(party: widget.party),
    );
  }

  Future<void> _transferOwnership(String newOwnerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Leadership'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to transfer leadership to this member?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will lose all leadership privileges and cannot undo this action.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(partyControllerProvider);
      final success = await controller.transferOwnership(widget.party.id, newOwnerId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leadership transferred successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back since user is no longer leader
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to transfer leadership'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteParty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to permanently delete "${widget.party.name}"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone and will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('• Remove all members from the party'),
            const Text('• Delete all party data'),
            const Text('• Cancel any active challenges'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(partyControllerProvider);
      final success = await controller.deleteParty(widget.party.id);

      if (mounted) {
        if (success) {
          // Navigate to parties list using GoRouter
          context.go('/party');
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _EditPartyDialog extends ConsumerStatefulWidget {
  const _EditPartyDialog({required this.party});

  final Party party;

  @override
  ConsumerState<_EditPartyDialog> createState() => _EditPartyDialogState();
}

class _EditPartyDialogState extends ConsumerState<_EditPartyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.party.name;
    _descriptionController.text = widget.party.description;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Party Details'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Party Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a party name';
                }
                if (value.trim().length < 3) {
                  return 'Party name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.trim().length > 200) {
                  return 'Description must be less than 200 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedParty = widget.party.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(partyControllerProvider);
      final success = await controller.updateParty(updatedParty);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Party updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update party'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
class _TransferLeadershipDialog extends ConsumerWidget {
  const _TransferLeadershipDialog({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get members excluding the current owner
    final members = party.memberIds.where((id) => id != party.ownerId).toList();

    return AlertDialog(
      title: const Text('Transfer Leadership'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a member to transfer leadership to:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final memberId = members[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          memberId.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text('User ${memberId.substring(0, 8)}...'),
                      subtitle: const Text('Party Member'),
                      trailing: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Call the transfer method from the parent
                          if (context.mounted) {
                            final managePartyState = context.findAncestorStateOfType<_ManagePartyTabState>();
                            managePartyState?._transferOwnership(memberId);
                          }
                        },
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Transfer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: You will lose all leadership privileges and cannot undo this action.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}