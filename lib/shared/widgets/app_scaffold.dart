import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'global_notification_bar.dart';

/// A scaffold wrapper that adds consistent app bar with notification icon
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Combine any provided actions with the notification icon
    final allActions = <Widget>[
      const GlobalNotificationIcon(),
      if (actions != null) ...actions!,
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: allActions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}