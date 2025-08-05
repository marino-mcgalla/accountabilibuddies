import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../auth/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../challenges/presentation/pages/create_challenge_page.dart';
import '../../../challenges/presentation/pages/challenge_commitment_page.dart';
import '../../../challenges/presentation/widgets/proof_submission_widget.dart';
import '../../../challenges/presentation/providers/challenge_providers.dart';
import '../../../challenges/domain/entities/challenge.dart';
import '../../../challenges/domain/entities/user_challenge_participation.dart';
import '../../domain/entities/party.dart';
import '../providers/party_providers.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../../core/providers/display_name_providers.dart';
import '../../../../core/utils/display_name_utils.dart';

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
    
    // Sync the selected party ID when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedPartyIdProvider.notifier).state = widget.partyId;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildPartyTitle(Party currentParty, AsyncValue<List<Party>> partiesAsync) {
    return partiesAsync.when(
      data: (parties) {
        if (parties.length <= 1) {
          // Single party - just show party name with proper styling
          return Text(
            currentParty.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
        }
        
        // Multiple parties - show dropdown selector
        return Container(
          constraints: const BoxConstraints(maxWidth: 250),
          child: DropdownButton<String>(
            value: currentParty.id,
            underline: const SizedBox.shrink(),
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down, 
              color: Theme.of(context).colorScheme.onSurface,
            ),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          items: parties.map((party) {
            return DropdownMenuItem<String>(
              value: party.id,
              child: Container(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        party.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        party.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (party.id == currentParty.id) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
            onChanged: (String? newPartyId) {
              if (newPartyId != null && newPartyId != currentParty.id) {
                // Update the selected party ID for dashboard sync
                ref.read(selectedPartyIdProvider.notifier).state = newPartyId;
                context.go('${AppRoutes.party}/$newPartyId');
              }
            },
          ),
        );
      },
      loading: () => Text(
        currentParty.name,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      error: (_, __) => Text(
        currentParty.name,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _showPartyManagementBottomSheet(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partiesProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'All Parties',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: partiesAsync.when(
                data: (parties) => _buildPartyManagementContent(context, ref, parties, scrollController),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading parties')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyManagementContent(BuildContext context, WidgetRef ref, List<Party> parties, ScrollController scrollController) {
    final user = ref.watch(userProvider);
    
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parties list
          if (parties.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parties.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final party = parties[index];
                final isLeader = user != null && party.isLeader(user.id);
                final isCurrentParty = party.id == widget.partyId;
                
                return Card(
                  color: isCurrentParty ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        party.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      party.name,
                      style: TextStyle(
                        fontWeight: isCurrentParty ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text('${party.memberCount} members'),
                        if (isLeader) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LEADER',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isCurrentParty 
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : const Icon(Icons.chevron_right),
                    onTap: isCurrentParty ? null : () {
                      Navigator.of(context).pop();
                      context.go('${AppRoutes.party}/${party.id}');
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          
          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Create New Party'),
                  subtitle: const Text('Start your own accountability group'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/party/create');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Join Existing Party'),
                  subtitle: const Text('Use an invite code to join'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/party/join');
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partyAsync = ref.watch(partyProvider(widget.partyId));
    final currentUser = ref.watch(userProvider);
    final partiesAsync = ref.watch(partiesProvider);

    return partyAsync.when(
      data: (party) {
        if (party == null) {
          // Party not found, redirect to parties list
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/party');
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('Party not found or was deleted'),
              //     backgroundColor: Colors.orange,
              //   ),
              // );
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
            body: Column(
              children: [
                // Custom header with party switcher and menu
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Header with party title and menu
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPartyTitle(party, partiesAsync),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'manage_parties':
                                      _showPartyManagementBottomSheet(context, ref);
                                      break;
                                    case 'create_party':
                                      context.go('/party/create');
                                      break;
                                    case 'join_party':
                                      context.go('/party/join');
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'manage_parties',
                                    child: ListTile(
                                      leading: Icon(Icons.dashboard),
                                      title: Text('All Parties'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'create_party',
                                    child: ListTile(
                                      leading: Icon(Icons.group_add),
                                      title: Text('Create Party'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'join_party',
                                    child: ListTile(
                                      leading: Icon(Icons.person_add),
                                      title: Text('Join Party'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Tab bar
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Party Info', icon: Icon(Icons.info_outline)),
                            Tab(text: 'Manage Party', icon: Icon(Icons.admin_panel_settings)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Party Info (what everyone sees)
                      _PartyInfoTab(party: party, partyId: widget.partyId, currentUser: currentUser),
                      // Tab 2: Manage Party (leader only)
                      _ManagePartyTab(party: party, currentUser: currentUser),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Regular Member View - no tabs
          return Scaffold(
            body: Column(
              children: [
                // Custom header with party switcher and menu
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPartyTitle(party, partiesAsync),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'manage_parties':
                                  _showPartyManagementBottomSheet(context, ref);
                                  break;
                                case 'create_party':
                                  context.go('/party/create');
                                  break;
                                case 'join_party':
                                  context.go('/party/join');
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'manage_parties',
                                child: ListTile(
                                  leading: Icon(Icons.dashboard),
                                  title: Text('All Parties'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'create_party',
                                child: ListTile(
                                  leading: Icon(Icons.group_add),
                                  title: Text('Create Party'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'join_party',
                                child: ListTile(
                                  leading: Icon(Icons.person_add),
                                  title: Text('Join Party'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: _PartyInfoTab(party: party, partyId: widget.partyId, currentUser: currentUser),
                ),
              ],
            ),
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
            if (party.description.isNotEmpty) ...[
              Text(
                party.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
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

class _LeaderActionsCard extends ConsumerWidget {
  const _LeaderActionsCard({
    required this.party,
    required this.onStartChallenge,
    required this.onInviteMembers,
    required this.onEditParty,
    required this.onCancelChallenge,
    required this.onEndChallenge,
  });

  final Party party;
  final VoidCallback onStartChallenge;
  final VoidCallback onInviteMembers;
  final VoidCallback onEditParty;
  final void Function(Challenge) onCancelChallenge;
  final void Function(Challenge) onEndChallenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChallengeAsync = ref.watch(currentChallengeProvider(party.id));
    
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
            
            // Start Challenge Button
            currentChallengeAsync.when(
              data: (currentChallenge) {
                final hasActiveChallenge = currentChallenge != null;
                final canStartChallenge = party.canStartChallenges && !hasActiveChallenge;
                
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canStartChallenge ? onStartChallenge : null,
                    icon: Icon(hasActiveChallenge ? Icons.block : Icons.flag),
                    label: Text(hasActiveChallenge 
                        ? 'Challenge Already Active' 
                        : 'Start New Challenge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasActiveChallenge 
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: hasActiveChallenge 
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                );
              },
              loading: () => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: const Text('Loading...'),
                ),
              ),
              error: (error, stack) => SizedBox(
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
            ),
            
            // Cancel Challenge Button (only show when there's an active challenge)
            currentChallengeAsync.when(
              data: (currentChallenge) {
                if (currentChallenge != null) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => onEndChallenge(currentChallenge),
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('End Challenge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onCancelChallenge(currentChallenge),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Challenge'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
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
                    const SizedBox(height: 16),
                    
                    // Participation section for all members (including leaders)
                    _ChallengeParticipationSection(
                      challenge: challenge,
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
      case 'ChallengeStatus.summary':
        return Colors.green;
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

class _RecentChallengesSection extends ConsumerWidget {
  const _RecentChallengesSection({
    required this.partyId,
  });

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(partyChallengesProvider(partyId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Challenges',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            challengesAsync.when(
              data: (challenges) {
                // Filter to show only summary status challenges (completed)
                final summaryChallenges = challenges.where((c) => c.status == ChallengeStatus.summary).toList();
                
                if (summaryChallenges.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No completed challenges yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: summaryChallenges.take(3).map((challenge) => 
                    _buildChallengeCard(context, challenge)
                  ).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading challenges: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, Challenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(challenge.startDate)} - ${_formatDate(challenge.endDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push(AppRoutesExtension.challengeSummary(challenge.id));
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Summary'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            if (challenge.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
                leading: Consumer(
                  builder: (context, ref, child) {
                    final displayNameAsync = ref.watch(displayNameProvider(memberId));
                    return CircleAvatar(
                      backgroundColor: isOwner 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      child: displayNameAsync.when(
                        data: (displayName) => Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isOwner ? Colors.white : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        loading: () => Text(
                          '?',
                          style: TextStyle(
                            color: isOwner ? Colors.white : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        error: (_, __) => Text(
                          '?',
                          style: TextStyle(
                            color: isOwner ? Colors.white : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                title: isCurrentUser 
                  ? Text(
                      'You',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Consumer(
                      builder: (context, ref, child) {
                        final displayNameAsync = ref.watch(displayNameProvider(memberId));
                        return displayNameAsync.when(
                          data: (displayName) => Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          loading: () => Text(
                            'Loading...',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          error: (_, __) => Text(
                            'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        );
                      },
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
        inviterName: DisplayNameUtils.getDisplayNameSync(user),
        inviteeEmail: _emailController.text.trim(),
      );

      if (mounted) {
        if (result.isSuccess) {
          Navigator.of(context).pop();
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Invite sent successfully!'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Failed to send invite: ${result.failureOrNull?.message}'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
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
    
    if (!mounted) return;
    
    
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
              Navigator.of(context).pop(); // Close dialog
              
              // Navigate to party list page
              if (context.mounted) {
                context.go('/party/list');
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
      
      
      // Check if user was removed from the party
      next.whenData((party) {
        if (party != null) {
          
          // Only trigger if the previous state had the user as a member
          if (previous != null && !_isLeavingVoluntarily) {
            previous.whenData((previousParty) {
              if (previousParty != null && 
                  previousParty.memberIds.contains(widget.currentUser!.id) &&
                  !party.memberIds.contains(widget.currentUser!.id)) {
                // User was removed from the party
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleUserRemoved();
                });
              }
            });
          }
        } else {
          // Party was deleted, navigate all users back to parties list
          if (previous != null) {
            previous.whenData((previousParty) {
              if (previousParty != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.go('/party/list');
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text('The party "${previousParty.name}" was deleted by the leader'),
                    //     backgroundColor: Colors.orange,
                    //   ),
                    // );
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
                onCancelChallenge: (challenge) => _showCancelChallengeDialog(context, ref, challenge),
                onEndChallenge: (challenge) => _showEndChallengeDialog(context, ref, challenge),
              ),
              const SizedBox(height: 16),
            ],

            // Current Challenge Section
            _CurrentChallengeSection(partyId: widget.partyId, isLeader: isLeader),
            const SizedBox(height: 16),

            // Recent Challenges Section (including summary challenges)
            _RecentChallengesSection(partyId: widget.partyId),
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
            // Navigate to party list page
            context.go('/party/list');
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Left "${party.name}" successfully'),
            //     backgroundColor: Colors.green,
            //   ),
            // );
          } else {
            // Reset flag if leave failed
            setState(() {
              _isLeavingVoluntarily = false;
            });
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(
            //     content: Text('Failed to leave party'),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          }
        }
      } catch (e) {
        if (context.mounted) {
          // Reset flag on error
          setState(() {
            _isLeavingVoluntarily = false;
          });
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Error leaving party: $e'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
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

  void _showCancelChallengeDialog(BuildContext context, WidgetRef ref, Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel "${challenge.name}"?'),
            const SizedBox(height: 16),
            const Text('This will:'),
            const SizedBox(height: 8),
            const Text('• Permanently delete the challenge'),
            const Text('• Remove all member participation'),
            const Text('• Delete all proof submissions'),
            const Text('• Cancel any locked-in wagers'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red[700],
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Challenge'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelChallenge(context, ref, challenge);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Challenge'),
          ),
        ],
      ),
    );
  }

  void _showEndChallengeDialog(BuildContext context, WidgetRef ref, Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to end "${challenge.name}"?'),
            const SizedBox(height: 16),
            const Text('This will:'),
            const SizedBox(height: 8),
            const Text('• Calculate final results and money owed'),
            const Text('• Move challenge to summary phase'),
            const Text('• Show completion statistics'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can view the challenge summary after ending.',
                      style: TextStyle(
                        color: Colors.green[700],
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Running'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _endChallenge(context, ref, challenge);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Challenge'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelChallenge(BuildContext context, WidgetRef ref, Challenge challenge) async {
    try {
      // Get the challenge repository and cancel the challenge (includes proof deletion)
      final repository = ref.read(challengeRepositoryProvider);
      final result = await repository.cancelChallenge(challenge.id);
      
      if (context.mounted) {
        result.fold(
          onSuccess: (_) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Challenge "${challenge.name}" has been cancelled and removed'),
            //     backgroundColor: Colors.orange,
            //   ),
            // );
          },
          onFailure: (failure) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Failed to cancel challenge: ${failure.message}'),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error cancelling challenge: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    }
  }

  Future<void> _endChallenge(BuildContext context, WidgetRef ref, Challenge challenge) async {
    try {
      // Get the challenge repository and move challenge to summary
      final repository = ref.read(challengeRepositoryProvider);
      final result = await repository.moveToSummary(challenge.id);
      
      if (context.mounted) {
        result.fold(
          onSuccess: (updatedChallenge) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Challenge "${challenge.name}" has been ended successfully'),
            //     backgroundColor: Colors.green,
            //   ),
            // );
            // Navigate to challenge summary page
            context.push(AppRoutesExtension.challengeSummary(challenge.id));
          },
          onFailure: (failure) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Failed to end challenge: ${failure.message}'),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error ending challenge: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    }
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
            // Navigate to party list page
            context.go('/party/list');
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Left "${party.name}" successfully'),
            //     backgroundColor: Colors.green,
            //   ),
            // );
          } else {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(
            //     content: Text('Failed to leave party'),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          }
        }
      } catch (e) {
        if (context.mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Error leaving party: $e'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

            // Sent Invites Section
            _buildSentInvitesSection(),
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
                leading: Consumer(
                  builder: (context, ref, child) {
                    final displayNameAsync = ref.watch(displayNameProvider(memberId));
                    return CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      child: displayNameAsync.when(
                        data: (displayName) => Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => Text(
                          '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        error: (_, __) => Text(
                          '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                title: Consumer(
                  builder: (context, ref, child) {
                    if (isCurrentUser) {
                      return Text(
                        'You',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    }
                    
                    final displayNameAsync = ref.watch(displayNameProvider(memberId));
                    return displayNameAsync.when(
                      data: (displayName) => Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                      loading: () => Text(
                        'Loading...',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                      error: (_, __) => Text(
                        'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    );
                  },
                ),
                subtitle: Text(
                  'Party Member',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
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

  Widget _buildSentInvitesSection() {
    final sentInvitesAsync = ref.watch(sentInvitesProvider);
    
    return sentInvitesAsync.when(
      data: (sentInvites) {
        // Filter invites for this specific party
        final partySentInvites = sentInvites.where((invite) => invite.partyId == widget.party.id).toList();
        
        if (partySentInvites.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Invites',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: partySentInvites.map((invite) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: Icon(
                      Icons.mail_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Sent to ${invite.inviteeEmail}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    'Expires ${_getDaysUntilExpiration(invite.expiresAt)} • Sent ${_getRelativeDate(invite.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  trailing: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () => _cancelInvite(invite.id),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel'),
                      ),
                )).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getDaysUntilExpiration(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now).inDays;
    
    if (difference <= 0) {
      return 'expired';
    } else if (difference == 1) {
      return 'in 1 day';
    } else {
      return 'in $difference days';
    }
  }
  
  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Future<void> _cancelInvite(String inviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invite'),
        content: const Text('Are you sure you want to cancel this invite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Invite'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Invite'),
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
      final success = await controller.declineInvite(inviteId);

      if (mounted) {
        if (success) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Invite cancelled successfully'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Failed to cancel invite'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Member removed successfully'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Failed to remove member'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
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
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Leadership transferred successfully'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
          // Navigate back since user is no longer leader
          Navigator.of(context).pop();
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Failed to transfer leadership'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
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
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Party deleted successfully'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Failed to delete party'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
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
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Party updated successfully!'),
          //     backgroundColor: Colors.green,
          //   ),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Failed to update party'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error: $e'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
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
  
  Widget _getUserNameWidget(String userId, List<UserChallengeParticipation> participations) {
    return Consumer(
      builder: (context, ref, child) {
        final displayNameAsync = ref.watch(displayNameProvider(userId));
        return displayNameAsync.when(
          data: (displayName) => Text(displayName),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Unknown'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get members excluding the current owner
    final members = party.memberIds.where((id) => id != party.ownerId).toList();
    
    // Try to get current challenge to fetch user names
    final currentChallengeAsync = ref.watch(currentChallengeProvider(party.id));
    final challengeParticipations = currentChallengeAsync.when(
      data: (challenge) {
        if (challenge != null) {
          final participationsAsync = ref.watch(challengeParticipationsProvider(challenge.id));
          return participationsAsync.maybeWhen(
            data: (participations) => participations,
            orElse: () => <UserChallengeParticipation>[],
          );
        }
        return <UserChallengeParticipation>[];
      },
      loading: () => <UserChallengeParticipation>[],
      error: (_, __) => <UserChallengeParticipation>[],
    );

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
                      leading: Consumer(
                        builder: (context, ref, child) {
                          final displayNameAsync = ref.watch(displayNameProvider(memberId));
                          return CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: displayNameAsync.when(
                              data: (displayName) => Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              loading: () => const Text(
                                '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              error: (_, __) => const Text(
                                '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      title: _getUserNameWidget(memberId, challengeParticipations),
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

class _ChallengeParticipationSection extends ConsumerWidget {
  const _ChallengeParticipationSection({
    required this.challenge,
  });

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateChangesProvider).valueOrNull;
    if (currentUser == null) return const SizedBox.shrink();

    final userParticipationAsync = ref.watch(userParticipationProvider((
      challengeId: challenge.id,
      userId: currentUser.id,
    )));

    return userParticipationAsync.when(
      data: (participation) {
        if (participation == null) {
          // User hasn't participated yet - show lock in button
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ready to participate?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your goals and set your wager to join this challenge!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToCommitment(context, challenge),
                    icon: const Icon(Icons.flag),
                    label: const Text('Lock In My Goals'),
                  ),
                ),
              ],
            ),
          );
        } else {
          // User has participated - show status
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getParticipationStatusColor(context, participation.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getParticipationStatusColor(context, participation.status).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getParticipationStatusIcon(participation.status),
                      color: _getParticipationStatusColor(context, participation.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getParticipationStatusText(participation.status),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _getParticipationStatusColor(context, participation.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (participation.goals.isNotEmpty) ...[
                  Text(
                    'Goals committed: ${participation.goals.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                ],
                if (participation.wagerAmount != null) ...[
                  Text(
                    'Wager: \$${participation.wagerAmount!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                ],
                if (participation.lockedInDate != null) ...[
                  Text(
                    'Locked in: ${_formatDateTime(participation.lockedInDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                
                // Allow editing if not locked in yet
                if (participation.status == ParticipationStatus.notLockedIn) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToCommitment(context, challenge),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit My Commitment'),
                    ),
                  ),
                ],
                
                // Show proof submission for locked-in users
                if (participation.status == ParticipationStatus.lockedIn && participation.goals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ProofSubmissionWidget(
                    challengeId: challenge.id,
                    participationId: participation.id,
                    goals: participation.goals,
                  ),
                ],
              ],
            ),
          );
        }
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error loading participation status: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  void _navigateToCommitment(BuildContext context, Challenge challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChallengeCommitmentPage(challenge: challenge),
      ),
    );
  }

  Color _getParticipationStatusColor(BuildContext context, ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.notLockedIn:
        return Colors.orange;
      case ParticipationStatus.lockedIn:
        return Colors.green;
      case ParticipationStatus.optedOut:
        return Colors.grey;
      case ParticipationStatus.removed:
        return Colors.red;
    }
  }

  IconData _getParticipationStatusIcon(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.notLockedIn:
        return Icons.schedule;
      case ParticipationStatus.lockedIn:
        return Icons.lock;
      case ParticipationStatus.optedOut:
        return Icons.close;
      case ParticipationStatus.removed:
        return Icons.remove_circle;
    }
  }

  String _getParticipationStatusText(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.notLockedIn:
        return 'Commitment in Progress';
      case ParticipationStatus.lockedIn:
        return 'Goals Locked In';
      case ParticipationStatus.optedOut:
        return 'Opted Out';
      case ParticipationStatus.removed:
        return 'Removed from Challenge';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}