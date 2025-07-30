import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/parties/domain/entities/party_invite.dart';
import '../../features/parties/presentation/providers/party_providers.dart';

/// Global notification icon with badge that shows at the top of all screens
class GlobalNotificationIcon extends ConsumerWidget {
  const GlobalNotificationIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingInvitesAsync = ref.watch(pendingInvitesProvider);

    return pendingInvitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildNotificationIcon(context, ref, invites);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNotificationIcon(
    BuildContext context,
    WidgetRef ref,
    List<PartyInvite> invites,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context, ref, invites),
          ),
          // Badge counter
          if (invites.isNotEmpty)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  invites.length.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref, List<PartyInvite> invites) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationsBottomSheet(invites: invites),
    );
  }

}

/// Bottom sheet to show notifications
class _NotificationsBottomSheet extends ConsumerWidget {
  const _NotificationsBottomSheet({required this.invites});

  final List<PartyInvite> invites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Party Invitations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Invites list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: invites.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final invite = invites[index];
                return _buildInviteItem(context, ref, invite);
              },
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInviteItem(BuildContext context, WidgetRef ref, PartyInvite invite) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Party info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.group_add,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Party Invitation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  invite.partyName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From ${invite.inviterName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () async {
                  final controller = ref.read(partyControllerProvider);
                  await controller.declineInvite(invite.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Decline'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final controller = ref.read(partyControllerProvider);
                  final success = await controller.acceptInvite(invite.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Joined "${invite.partyName}" successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}