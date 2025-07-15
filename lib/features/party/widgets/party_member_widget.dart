import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/party_model_multi.dart';
import '../providers/multi_party_provider.dart';

class PartyMemberWidget extends StatelessWidget {
  final String memberId;
  final MultiParty party;
  final bool isCurrentUser;
  final VoidCallback? onRemove;
  final VoidCallback? onTransferLeadership;

  const PartyMemberWidget({
    super.key,
    required this.memberId,
    required this.party,
    required this.isCurrentUser,
    this.onRemove,
    this.onTransferLeadership,
  });

  @override
  Widget build(BuildContext context) {
    final isLeader = party.isLeader(memberId);
    final multiPartyProvider = Provider.of<MultiPartyProvider>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            multiPartyProvider.getUserInitials(memberId),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                multiPartyProvider.getUserDisplayName(memberId),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (isLeader) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Leader',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          _getSubtitle(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: _buildActionMenu(context),
      ),
    );
  }

  Widget? _buildActionMenu(BuildContext context) {
    if (isCurrentUser || (onRemove == null && onTransferLeadership == null)) {
      return null;
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'remove':
            onRemove?.call();
            break;
          case 'transfer':
            onTransferLeadership?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onTransferLeadership != null)
          const PopupMenuItem(
            value: 'transfer',
            child: ListTile(
              leading: Icon(Icons.swap_horiz, color: Colors.orange),
              title: Text('Transfer Leadership'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onRemove != null)
          const PopupMenuItem(
            value: 'remove',
            child: ListTile(
              leading: Icon(Icons.person_remove, color: Colors.red),
              title: Text('Remove Member'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  String _getSubtitle() {
    final isLeader = party.isLeader(memberId);
    final joinedText = isLeader ? 'Party Leader' : 'Member';
    // In a real app, you'd show when they joined
    return joinedText;
  }
}