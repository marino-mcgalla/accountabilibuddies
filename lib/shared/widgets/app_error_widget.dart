import 'package:flutter/material.dart';
import '../../../core/core.dart';
import 'app_button.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.showRetryButton = true,
    this.retryButtonText = 'Retry',
    this.icon,
    this.iconSize,
    this.iconColor,
    this.title,
    this.titleStyle,
    this.messageStyle,
    this.padding,
    this.spacing = 16,
    this.compact = false,
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final String retryButtonText;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final String? title;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? (compact ? const EdgeInsets.all(16) : const EdgeInsets.all(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!compact) ...[
            Icon(
              icon ?? _getIconForFailure(failure),
              size: iconSize ?? (compact ? 40 : 64),
              color: iconColor ?? theme.colorScheme.error,
            ),
            SizedBox(height: spacing),
          ],
          if (title != null || !compact) ...[
            Text(
              title ?? _getTitleForFailure(failure),
              style: titleStyle ?? theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing / 2),
          ],
          Text(
            _getDisplayMessage(failure),
            style: messageStyle ?? theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetryButton && onRetry != null) ...[
            SizedBox(height: spacing),
            AppButton(
              text: retryButtonText,
              onPressed: onRetry,
              type: AppButtonType.outlined,
              size: compact ? AppButtonSize.small : AppButtonSize.medium,
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayMessage(Failure failure) {
    switch (failure) {
      case NetworkFailure _:
        return 'Please check your internet connection and try again.';
      case AuthFailure _:
        return 'Authentication failed. Please sign in again.';
      case PermissionFailure _:
        return 'You don\'t have permission to access this resource.';
      case ValidationFailure _:
        return failure.message;
      case NotFoundFailure _:
        return 'The requested resource was not found.';
      case ServerFailure _:
        return 'Something went wrong on our end. Please try again later.';
      case CacheFailure _:
        return 'Failed to load cached data. Please try again.';
      case UnknownFailure _:
      default:
        return failure.message.isNotEmpty 
          ? failure.message 
          : 'An unexpected error occurred. Please try again.';
    }
  }

  String _getTitleForFailure(Failure failure) {
    switch (failure) {
      case NetworkFailure _:
        return 'Connection Error';
      case AuthFailure _:
        return 'Authentication Error';
      case PermissionFailure _:
        return 'Access Denied';
      case ValidationFailure _:
        return 'Invalid Input';
      case NotFoundFailure _:
        return 'Not Found';
      case ServerFailure _:
        return 'Server Error';
      case CacheFailure _:
        return 'Cache Error';
      case UnknownFailure _:
      default:
        return 'Error';
    }
  }

  IconData _getIconForFailure(Failure failure) {
    switch (failure) {
      case NetworkFailure _:
        return Icons.wifi_off;
      case AuthFailure _:
        return Icons.lock_outline;
      case PermissionFailure _:
        return Icons.block;
      case ValidationFailure _:
        return Icons.error_outline;
      case NotFoundFailure _:
        return Icons.search_off;
      case ServerFailure _:
        return Icons.cloud_off;
      case CacheFailure _:
        return Icons.storage;
      case UnknownFailure _:
      default:
        return Icons.error_outline;
    }
  }
}

class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.errorWidget,
    this.showRetryButton = true,
    this.retryButtonText = 'Retry',
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error, StackTrace stackTrace)? errorWidget;
  final bool showRetryButton;
  final String retryButtonText;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
        widget.onError?.call(details.exception, details.stack ?? StackTrace.current);
      }
    };
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorWidget != null) {
        return widget.errorWidget!(_error!, _stackTrace!);
      }

      final failure = _error is Failure 
        ? _error as Failure
        : UnknownFailure(
            message: _error.toString(),
            originalError: _error,
            stackTrace: _stackTrace,
          );

      return AppErrorWidget(
        failure: failure,
        onRetry: widget.showRetryButton ? _retry : null,
        showRetryButton: widget.showRetryButton,
        retryButtonText: widget.retryButtonText,
      );
    }

    return widget.child;
  }
}

class AppSnackbar {
  static void showError(
    BuildContext context,
    Failure failure, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                failure.message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Theme.of(context).colorScheme.onSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}