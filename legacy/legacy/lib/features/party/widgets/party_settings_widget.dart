import 'package:flutter/material.dart';
import '../models/party_model_multi.dart';

class PartySettingsWidget extends StatefulWidget {
  final MultiParty party;
  final bool isLeader;
  final Function(Map<String, dynamic>) onUpdateSettings;

  const PartySettingsWidget({
    super.key,
    required this.party,
    required this.isLeader,
    required this.onUpdateSettings,
  });

  @override
  State<PartySettingsWidget> createState() => _PartySettingsWidgetState();
}

class _PartySettingsWidgetState extends State<PartySettingsWidget> {
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.party.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Party Information Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Party Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Name', widget.party.name),
                _buildInfoRow('Challenge Duration', widget.party.challengeDurationDisplayName),
                _buildInfoRow('Start Day', widget.party.startDayDisplayName),
                _buildInfoRow('Members', '${widget.party.memberCount} / 10'),
                _buildInfoRow('Created', _formatDate(widget.party.createdAt)),
                _buildInfoRow('Last Activity', _formatDate(widget.party.lastActivityAt)),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Settings Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Party Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (!widget.isLeader) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Only party leaders can modify settings',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Allow Member Invites
                _buildSettingTile(
                  context,
                  'Allow Member Invites',
                  'Let regular members invite new people to the party',
                  Icons.person_add,
                  _settings['allowMemberInvites'] ?? false,
                  (value) => _updateSetting('allowMemberInvites', value),
                ),
                
                const Divider(),
                
                // Auto Start Challenges
                _buildSettingTile(
                  context,
                  'Auto Start Challenges',
                  'Automatically start new challenges when the previous one ends',
                  Icons.play_circle,
                  _settings['autoStartChallenges'] ?? false,
                  (value) => _updateSetting('autoStartChallenges', value),
                ),
                
                const Divider(),
                
                // Reminder Notifications
                _buildSettingTile(
                  context,
                  'Reminder Notifications',
                  'Send reminder notifications to all party members',
                  Icons.notifications,
                  _settings['reminderNotifications'] ?? true,
                  (value) => _updateSetting('reminderNotifications', value),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Challenge Rules Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge Rules',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildRuleItem(
                  'Challenge Duration',
                  'Challenges run for ${widget.party.challengeDurationDisplayName.toLowerCase()} periods',
                  Icons.schedule,
                ),
                _buildRuleItem(
                  'Start Day',
                  'New challenges start every ${widget.party.startDayDisplayName}',
                  Icons.calendar_today,
                ),
                _buildRuleItem(
                  'Member Limit',
                  'Maximum of 10 members per party',
                  Icons.people,
                ),
                _buildRuleItem(
                  'Goal Completion',
                  'Members must complete their daily goals to stay accountable',
                  Icons.check_circle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: Switch(
        value: value,
        onChanged: widget.isLeader ? onChanged : null,
      ),
    );
  }

  Widget _buildRuleItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _settings[key] = value;
    });
    
    // Apply the setting immediately
    widget.onUpdateSettings(_settings);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}