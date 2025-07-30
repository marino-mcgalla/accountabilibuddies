import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/party_providers.dart';

class PartyListPage extends ConsumerWidget {
  const PartyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partiesProvider);
    final pendingInvitesAsync = ref.watch(pendingInvitesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parties'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partiesProvider);
          ref.invalidate(pendingInvitesProvider);
        },
        child: partiesAsync.when(
          data: (parties) {
            if (parties.isEmpty) {
              return _buildEmptyState(context, ref, pendingInvitesAsync);
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (party.description.isNotEmpty) ...[
                          Text(
                            party.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${party.memberCount} members',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (party.isOwner(ref.read(userProvider)?.id ?? '')) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 152, 0, 0.2),
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
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/party/${party.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load parties'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(partiesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show pending invites FAB if any
          pendingInvitesAsync.when(
            data: (invites) {
              if (invites.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.extended(
                  onPressed: () => _showPendingInvites(context, ref, invites),
                  backgroundColor: Colors.orange,
                  icon: const Icon(Icons.mail),
                  label: Text('${invites.length} Invites'),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Create party FAB
          FloatingActionButton.extended(
            onPressed: () => context.go('/party/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create Party'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> pendingInvitesAsync) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              size: 96,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No parties yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create or join a party to start building accountability with friends.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/party/create'),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Create Party'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/party/join'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Join Party'),
                ),
              ],
            ),
            
            // Show pending invites if any
            const SizedBox(height: 24),
            pendingInvitesAsync.when(
              data: (invites) {
                if (invites.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'You have ${invites.length} pending invitation${invites.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showPendingInvites(context, ref, invites),
                      icon: const Icon(Icons.mail),
                      label: const Text('View Invitations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingInvites(BuildContext context, WidgetRef ref, List<dynamic> invites) {
    // This will reuse the existing showPendingInvites function from placeholder_screens.dart
    // We need to import it or recreate it here
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail),
                  const SizedBox(width: 8),
                  Text(
                    'Party Invitations (${invites.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  // Implement invite card UI here
                  // This would be similar to the existing implementation
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Invite ${index + 1}'), // Placeholder
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}