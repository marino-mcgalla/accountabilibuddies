import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_loading.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.titleIcon,
    this.content,
    this.actions,
    this.primaryAction,
    this.secondaryAction,
    this.destructiveAction,
    this.isDismissible = true,
    this.showCloseButton = true,
    this.titleStyle,
    this.contentStyle,
    this.contentPadding,
    this.actionsPadding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.insetPadding,
    this.scrollable = false,
    this.alignment,
  });

  final String? title;
  final IconData? titleIcon;
  final Widget? content;
  final List<Widget>? actions;
  final AppDialogAction? primaryAction;
  final AppDialogAction? secondaryAction;
  final AppDialogAction? destructiveAction;
  final bool isDismissible;
  final bool showCloseButton;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsets? insetPadding;
  final bool scrollable;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: _buildTitle(context, theme),
      content: content,
      actions: _buildActions(context, theme),
      scrollable: scrollable,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      elevation: elevation,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: actionsPadding ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 8, 16),
      insetPadding: insetPadding ?? const EdgeInsets.all(16),
      alignment: alignment,
    );
  }

  Widget? _buildTitle(BuildContext context, ThemeData theme) {
    if (title == null && titleIcon == null && !showCloseButton) {
      return null;
    }

    return Row(
      children: [
        if (titleIcon != null) ...[
          Icon(
            titleIcon,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
        ],
        if (title != null)
          Expanded(
            child: Text(
              title!,
              style: titleStyle ?? theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (showCloseButton) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            iconSize: 20,
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget>? _buildActions(BuildContext context, ThemeData theme) {
    if (actions != null) {
      return actions;
    }

    final dialogActions = <Widget>[];

    if (secondaryAction != null) {
      dialogActions.add(
        AppButton(
          text: secondaryAction!.text,
          onPressed: secondaryAction!.onPressed ?? () => Navigator.of(context).pop(),
          type: AppButtonType.text,
          size: AppButtonSize.medium,
          isDisabled: secondaryAction!.isDisabled,
        ),
      );
    }

    if (destructiveAction != null) {
      dialogActions.add(
        AppButton(
          text: destructiveAction!.text,
          onPressed: destructiveAction!.onPressed ?? () => Navigator.of(context).pop(),
          type: AppButtonType.text,
          size: AppButtonSize.medium,
          isDisabled: destructiveAction!.isDisabled,
        ),
      );
    }

    if (primaryAction != null) {
      dialogActions.add(
        AppButton(
          text: primaryAction!.text,
          onPressed: primaryAction!.onPressed ?? () => Navigator.of(context).pop(),
          type: AppButtonType.primary,
          size: AppButtonSize.medium,
          isLoading: primaryAction!.isLoading,
          isDisabled: primaryAction!.isDisabled,
        ),
      );
    }

    return dialogActions.isEmpty ? null : dialogActions;
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );
  }
}

class AppDialogAction {
  const AppDialogAction({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
}

// Predefined dialog types
class AppDialogs {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    IconData? icon,
    bool isDismissible = true,
  }) {
    return AppDialog.show<bool>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        titleIcon: icon,
        content: Text(message),
        primaryAction: AppDialogAction(
          text: confirmText,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
        ),
        secondaryAction: AppDialogAction(
          text: cancelText,
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
        ),
        isDismissible: isDismissible,
      ),
    );
  }

  static Future<bool?> showDestructiveConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    IconData? icon,
    bool isDismissible = true,
  }) {
    return AppDialog.show<bool>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        titleIcon: icon ?? Icons.warning_amber_outlined,
        content: Text(message),
        destructiveAction: AppDialogAction(
          text: confirmText,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
        ),
        secondaryAction: AppDialogAction(
          text: cancelText,
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
        ),
        isDismissible: isDismissible,
      ),
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    IconData? icon,
    bool isDismissible = true,
  }) {
    return AppDialog.show<void>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        titleIcon: icon ?? Icons.info_outline,
        content: Text(message),
        primaryAction: AppDialogAction(
          text: buttonText,
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
        ),
        isDismissible: isDismissible,
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    IconData? icon,
    bool isDismissible = true,
  }) {
    return AppDialog.show<void>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        titleIcon: icon ?? Icons.error_outline,
        content: Text(message),
        primaryAction: AppDialogAction(
          text: buttonText,
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
        ),
        isDismissible: isDismissible,
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    IconData? icon,
    bool isDismissible = true,
  }) {
    return AppDialog.show<void>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        titleIcon: icon ?? Icons.check_circle_outline,
        content: Text(message),
        primaryAction: AppDialogAction(
          text: buttonText,
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
        ),
        isDismissible: isDismissible,
      ),
    );
  }

  static Future<void> showLoading({
    required BuildContext context,
    required String title,
    String? message,
    bool isDismissible = false,
  }) {
    return AppDialog.show<void>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoading(
              type: AppLoadingType.circular,
              size: AppLoadingSize.medium,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
        isDismissible: isDismissible,
        showCloseButton: false,
      ),
    );
  }

  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    bool isDismissible = true,
    String? Function(String?)? validator,
  }) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return AppDialog.show<String>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null) ...[
              Text(message),
              const SizedBox(height: 16),
            ],
            Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: maxLines,
                maxLength: maxLength,
                keyboardType: keyboardType,
                validator: validator,
                autofocus: true,
              ),
            ),
          ],
        ),
        primaryAction: AppDialogAction(
          text: confirmText,
          onPressed: () {
            if (formKey.currentState?.validate() ?? true) {
              Navigator.of(context).pop(controller.text);
            }
          },
        ),
        secondaryAction: AppDialogAction(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        isDismissible: isDismissible,
      ),
    );
  }
}