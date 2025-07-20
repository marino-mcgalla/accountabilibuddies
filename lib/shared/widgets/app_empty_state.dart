import 'package:flutter/material.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.illustration,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.titleStyle,
    this.messageStyle,
    this.padding,
    this.spacing = 16,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final Widget? illustration;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? (compact ? const EdgeInsets.all(16) : const EdgeInsets.all(32)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (illustration != null) ...[
            illustration!,
            SizedBox(height: spacing),
          ] else if (icon != null) ...[
            Icon(
              icon!,
              size: iconSize ?? (compact ? 48 : 80),
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: spacing),
          ],
          Text(
            title,
            style: titleStyle ?? theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing / 2),
          Text(
            message,
            style: messageStyle ?? theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            SizedBox(height: spacing * 1.5),
            AppButton(
              text: actionText!,
              onPressed: onAction,
              size: compact ? AppButtonSize.small : AppButtonSize.medium,
            ),
            if (secondaryActionText != null && onSecondaryAction != null) ...[
              SizedBox(height: spacing / 2),
              AppButton(
                text: secondaryActionText!,
                onPressed: onSecondaryAction,
                type: AppButtonType.text,
                size: compact ? AppButtonSize.small : AppButtonSize.medium,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// Predefined common empty states
class AppEmptyStates {
  static Widget noData({
    String? title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'No Data',
      message: message ?? 'There\'s nothing here yet.',
      icon: Icons.inbox_outlined,
      actionText: actionText,
      onAction: onAction,
      compact: compact,
    );
  }

  static Widget noSearchResults({
    String? title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'No Results',
      message: message ?? 'We couldn\'t find anything matching your search.',
      icon: Icons.search_off,
      actionText: actionText,
      onAction: onAction,
      compact: compact,
    );
  }

  static Widget noNetwork({
    String? title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'No Connection',
      message: message ?? 'Check your internet connection and try again.',
      icon: Icons.wifi_off,
      actionText: actionText ?? 'Retry',
      onAction: onAction,
      compact: compact,
    );
  }

  static Widget noGoals({
    String? title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'No Goals Yet',
      message: message ?? 'Create your first goal to get started with your accountability journey.',
      icon: Icons.flag_outlined,
      actionText: actionText ?? 'Create Goal',
      onAction: onAction,
      compact: compact,
    );
  }

  static Widget noParty({
    String? title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'No Party Yet',
      message: message ?? 'Create or join a party to start your accountability journey with friends.',
      icon: Icons.group_outlined,
      actionText: actionText ?? 'Create Party',
      onAction: onAction,
      secondaryActionText: secondaryActionText ?? 'Join Party',
      onSecondaryAction: onSecondaryAction,
      compact: compact,
    );
  }

  static Widget noProofs({
    String? title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'No Proofs Yet',
      message: message ?? 'Submit your first proof to show your progress.',
      icon: Icons.camera_alt_outlined,
      actionText: actionText ?? 'Submit Proof',
      onAction: onAction,
      compact: compact,
    );
  }

  static Widget noPendingApprovals({
    String? title,
    String? message,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'All Caught Up!',
      message: message ?? 'No pending proofs to review right now.',
      icon: Icons.check_circle_outline,
      compact: compact,
    );
  }

  static Widget noNotifications({
    String? title,
    String? message,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'No Notifications',
      message: message ?? 'You\'re all caught up! No new notifications.',
      icon: Icons.notifications_none_outlined,
      compact: compact,
    );
  }

  static Widget comingSoon({
    String? title,
    String? message,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'Coming Soon',
      message: message ?? 'This feature is coming soon. Stay tuned!',
      icon: Icons.construction_outlined,
      compact: compact,
    );
  }

  static Widget maintenance({
    String? title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    return AppEmptyState(
      title: title ?? 'Under Maintenance',
      message: message ?? 'We\'re making improvements. Please check back later.',
      icon: Icons.build_outlined,
      actionText: actionText ?? 'Refresh',
      onAction: onAction,
      compact: compact,
    );
  }
}