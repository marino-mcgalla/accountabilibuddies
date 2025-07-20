import 'package:flutter/material.dart';

enum AppLoadingType {
  circular,
  linear,
  dots,
  pulse,
}

enum AppLoadingSize {
  small,
  medium,
  large,
}

class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.type = AppLoadingType.circular,
    this.size = AppLoadingSize.medium,
    this.color,
    this.backgroundColor,
    this.strokeWidth,
    this.value,
    this.semanticsLabel,
    this.semanticsValue,
    this.message,
    this.messageStyle,
    this.spacing = 16,
    this.overlay = false,
    this.overlayColor,
    this.dismissible = false,
  });

  final AppLoadingType type;
  final AppLoadingSize size;
  final Color? color;
  final Color? backgroundColor;
  final double? strokeWidth;
  final double? value;
  final String? semanticsLabel;
  final String? semanticsValue;
  final String? message;
  final TextStyle? messageStyle;
  final double spacing;
  final bool overlay;
  final Color? overlayColor;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingWidget = _buildLoadingWidget(theme);

    if (overlay) {
      return _buildOverlay(context, theme, loadingWidget);
    }

    return loadingWidget;
  }

  Widget _buildOverlay(BuildContext context, ThemeData theme, Widget child) {
    return Material(
      color: overlayColor ?? Colors.black.withValues(alpha: 0.5),
      child: InkWell(
        onTap: dismissible ? () => Navigator.of(context).pop() : null,
        child: SizedBox.expand(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    final indicator = _buildIndicator(theme);
    
    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          SizedBox(height: spacing),
          Text(
            message!,
            style: messageStyle ?? theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }

  Widget _buildIndicator(ThemeData theme) {
    switch (type) {
      case AppLoadingType.circular:
        return _buildCircularIndicator(theme);
      case AppLoadingType.linear:
        return _buildLinearIndicator(theme);
      case AppLoadingType.dots:
        return _buildDotsIndicator(theme);
      case AppLoadingType.pulse:
        return _buildPulseIndicator(theme);
    }
  }

  Widget _buildCircularIndicator(ThemeData theme) {
    return SizedBox(
      width: _getSize(),
      height: _getSize(),
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth ?? _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
        backgroundColor: backgroundColor,
        semanticsLabel: semanticsLabel,
        semanticsValue: semanticsValue,
      ),
    );
  }

  Widget _buildLinearIndicator(ThemeData theme) {
    return SizedBox(
      width: _getLinearWidth(),
      height: _getStrokeWidth(),
      child: LinearProgressIndicator(
        value: value,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
        backgroundColor: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
        semanticsLabel: semanticsLabel,
        semanticsValue: semanticsValue,
      ),
    );
  }

  Widget _buildDotsIndicator(ThemeData theme) {
    return SizedBox(
      width: _getSize(),
      height: _getSize(),
      child: _DotsLoadingIndicator(
        color: color ?? theme.colorScheme.primary,
        size: _getDotSize(),
      ),
    );
  }

  Widget _buildPulseIndicator(ThemeData theme) {
    return SizedBox(
      width: _getSize(),
      height: _getSize(),
      child: _PulseLoadingIndicator(
        color: color ?? theme.colorScheme.primary,
        size: _getSize(),
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case AppLoadingSize.small:
        return 24;
      case AppLoadingSize.medium:
        return 40;
      case AppLoadingSize.large:
        return 64;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case AppLoadingSize.small:
        return 2;
      case AppLoadingSize.medium:
        return 3;
      case AppLoadingSize.large:
        return 4;
    }
  }

  double _getLinearWidth() {
    switch (size) {
      case AppLoadingSize.small:
        return 120;
      case AppLoadingSize.medium:
        return 200;
      case AppLoadingSize.large:
        return 280;
    }
  }

  double _getDotSize() {
    switch (size) {
      case AppLoadingSize.small:
        return 4;
      case AppLoadingSize.medium:
        return 6;
      case AppLoadingSize.large:
        return 8;
    }
  }
}

class _DotsLoadingIndicator extends StatefulWidget {
  const _DotsLoadingIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<_DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<_DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: widget.size,
              height: widget.size,
              margin: EdgeInsets.symmetric(horizontal: widget.size / 4),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _animations[index].value),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulseLoadingIndicator extends StatefulWidget {
  const _PulseLoadingIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<_PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<_PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppLoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    String? message,
    AppLoadingType type = AppLoadingType.circular,
    AppLoadingSize size = AppLoadingSize.medium,
    Color? color,
    Color? overlayColor,
    bool dismissible = false,
  }) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => AppLoading(
        type: type,
        size: size,
        color: color,
        message: message,
        overlay: true,
        overlayColor: overlayColor,
        dismissible: dismissible,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}