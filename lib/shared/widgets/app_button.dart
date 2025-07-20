import 'package:flutter/material.dart';

enum AppButtonType {
  primary,
  secondary,
  outlined,
  text,
  icon,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.borderRadius,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;
  final IconData? icon;
  final IconPosition iconPosition;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(context, theme, isEnabled),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme, bool isEnabled) {
    final child = _buildChild(context, theme);

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getElevatedButtonStyle(theme, isEnabled),
          child: child,
        );
      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getSecondaryButtonStyle(theme, isEnabled),
          child: child,
        );
      case AppButtonType.outlined:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getOutlinedButtonStyle(theme, isEnabled),
          child: child,
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getTextButtonStyle(theme, isEnabled),
          child: child,
        );
      case AppButtonType.icon:
        return IconButton(
          onPressed: isEnabled ? onPressed : null,
          icon: isLoading ? _buildLoadingIndicator(theme) : Icon(icon),
          iconSize: _getIconSize(),
          style: _getIconButtonStyle(theme, isEnabled),
        );
    }
  }

  Widget _buildChild(BuildContext context, ThemeData theme) {
    if (type == AppButtonType.icon) {
      return isLoading ? _buildLoadingIndicator(theme) : Icon(icon);
    }

    if (isLoading) {
      return _buildLoadingIndicator(theme);
    }

    if (icon != null) {
      return _buildTextWithIcon(theme);
    }

    return Text(
      text,
      style: _getTextStyle(theme),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTextWithIcon(ThemeData theme) {
    final textWidget = Text(
      text,
      style: _getTextStyle(theme),
    );
    final iconWidget = Icon(
      icon,
      size: _getIconSize(),
    );

    if (iconPosition == IconPosition.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          SizedBox(width: _getIconSpacing()),
          textWidget,
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget,
          SizedBox(width: _getIconSpacing()),
          iconWidget,
        ],
      );
    }
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: _getLoadingSize(),
      height: _getLoadingSize(),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          _getLoadingColor(theme),
        ),
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 18;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case AppButtonSize.small:
        return 6;
      case AppButtonSize.medium:
        return 8;
      case AppButtonSize.large:
        return 10;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = switch (size) {
      AppButtonSize.small => theme.textTheme.bodySmall,
      AppButtonSize.medium => theme.textTheme.bodyMedium,
      AppButtonSize.large => theme.textTheme.bodyLarge,
    };

    return baseStyle?.copyWith(
      fontWeight: FontWeight.w600,
    ) ?? const TextStyle(fontWeight: FontWeight.w600);
  }

  Color _getLoadingColor(ThemeData theme) {
    switch (type) {
      case AppButtonType.primary:
        return theme.colorScheme.onPrimary;
      case AppButtonType.secondary:
        return theme.colorScheme.onSecondary;
      case AppButtonType.outlined:
      case AppButtonType.text:
        return theme.colorScheme.primary;
      case AppButtonType.icon:
        return theme.colorScheme.onSurface;
    }
  }

  ButtonStyle _getElevatedButtonStyle(ThemeData theme, bool isEnabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.12),
      foregroundColor: isEnabled ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
      elevation: isEnabled ? 2 : 0,
      shadowColor: theme.colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getSecondaryButtonStyle(ThemeData theme, bool isEnabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? theme.colorScheme.secondary : theme.colorScheme.onSurface.withValues(alpha: 0.12),
      foregroundColor: isEnabled ? theme.colorScheme.onSecondary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
      elevation: isEnabled ? 1 : 0,
      shadowColor: theme.colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getOutlinedButtonStyle(ThemeData theme, bool isEnabled) {
    return OutlinedButton.styleFrom(
      foregroundColor: isEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
      side: BorderSide(
        color: isEnabled ? theme.colorScheme.outline : theme.colorScheme.onSurface.withValues(alpha: 0.12),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getTextButtonStyle(ThemeData theme, bool isEnabled) {
    return TextButton.styleFrom(
      foregroundColor: isEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getIconButtonStyle(ThemeData theme, bool isEnabled) {
    return IconButton.styleFrom(
      foregroundColor: isEnabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.38),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }
}

enum IconPosition {
  left,
  right,
}