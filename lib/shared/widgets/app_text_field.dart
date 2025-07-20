import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppTextFieldType {
  outlined,
  filled,
  underline,
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.focusNode,
    this.type = AppTextFieldType.outlined,
    this.contentPadding,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.cursorColor,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.helperStyle,
    this.errorStyle,
    this.counterStyle,
    this.prefixStyle,
    this.suffixStyle,
    this.showCursor,
    this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    this.scrollPadding,
    this.enableInteractiveSelection,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.expands = false,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.showCounterText = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final AppTextFieldType type;
  final EdgeInsetsGeometry? contentPadding;
  final double? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? cursorColor;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? helperStyle;
  final TextStyle? errorStyle;
  final TextStyle? counterStyle;
  final TextStyle? prefixStyle;
  final TextStyle? suffixStyle;
  final bool? showCursor;
  final double? cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final EdgeInsets? scrollPadding;
  final bool? enableInteractiveSelection;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool expands;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool showCounterText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.type == AppTextFieldType.outlined)
          _buildFloatingLabel(theme),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: _buildInputDecoration(theme),
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          onEditingComplete: widget.onEditingComplete,
          style: widget.textStyle ?? theme.textTheme.bodyMedium,
          cursorColor: widget.cursorColor ?? theme.colorScheme.primary,
          showCursor: widget.showCursor,
          cursorWidth: widget.cursorWidth ?? 2.0,
          cursorHeight: widget.cursorHeight,
          cursorRadius: widget.cursorRadius,
          scrollPadding: widget.scrollPadding ?? const EdgeInsets.all(20.0),
          enableInteractiveSelection: widget.enableInteractiveSelection,
          buildCounter: widget.buildCounter,
          scrollController: widget.scrollController,
          scrollPhysics: widget.scrollPhysics,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          expands: widget.expands,
          strutStyle: widget.strutStyle,
          textAlign: widget.textAlign,
          textAlignVertical: widget.textAlignVertical,
          textDirection: widget.textDirection,
        ),
        if (widget.helperText != null && widget.errorText == null)
          _buildHelperText(theme),
        if (widget.showCounterText && widget.maxLength != null)
          _buildCounterText(theme),
      ],
    );
  }

  Widget _buildFloatingLabel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        widget.label!,
        style: widget.labelStyle ?? 
          theme.textTheme.bodySmall?.copyWith(
            color: widget.errorText != null 
              ? theme.colorScheme.error
              : _isFocused 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
      ),
    );
  }

  Widget _buildHelperText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        widget.helperText!,
        style: widget.helperStyle ?? 
          theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
      ),
    );
  }

  Widget _buildCounterText(ThemeData theme) {
    final currentLength = widget.controller?.text.length ?? 0;
    final maxLength = widget.maxLength ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$currentLength/$maxLength',
          style: widget.counterStyle ?? 
            theme.textTheme.bodySmall?.copyWith(
              color: currentLength > maxLength 
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
            ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme) {
    switch (widget.type) {
      case AppTextFieldType.outlined:
        return _buildOutlinedDecoration(theme);
      case AppTextFieldType.filled:
        return _buildFilledDecoration(theme);
      case AppTextFieldType.underline:
        return _buildUnderlineDecoration(theme);
    }
  }

  InputDecoration _buildOutlinedDecoration(ThemeData theme) {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: widget.hintStyle ?? 
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      errorText: widget.errorText,
      errorStyle: widget.errorStyle ?? 
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      prefixIconColor: _getPrefixIconColor(theme),
      suffixIconColor: _getSuffixIconColor(theme),
      contentPadding: widget.contentPadding ?? 
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.borderColor ?? theme.colorScheme.outline,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.borderColor ?? theme.colorScheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.focusedBorderColor ?? theme.colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      filled: false,
      counterText: widget.showCounterText ? null : '',
    );
  }

  InputDecoration _buildFilledDecoration(ThemeData theme) {
    return InputDecoration(
      labelText: widget.label,
      labelStyle: widget.labelStyle,
      hintText: widget.hint,
      hintStyle: widget.hintStyle ?? 
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      errorText: widget.errorText,
      errorStyle: widget.errorStyle ?? 
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      prefixIconColor: _getPrefixIconColor(theme),
      suffixIconColor: _getSuffixIconColor(theme),
      contentPadding: widget.contentPadding ?? 
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.focusedBorderColor ?? theme.colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: widget.fillColor ?? theme.colorScheme.surfaceContainerHighest,
      counterText: widget.showCounterText ? null : '',
    );
  }

  InputDecoration _buildUnderlineDecoration(ThemeData theme) {
    return InputDecoration(
      labelText: widget.label,
      labelStyle: widget.labelStyle,
      hintText: widget.hint,
      hintStyle: widget.hintStyle ?? 
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      errorText: widget.errorText,
      errorStyle: widget.errorStyle ?? 
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      prefixIconColor: _getPrefixIconColor(theme),
      suffixIconColor: _getSuffixIconColor(theme),
      contentPadding: widget.contentPadding ?? 
        const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: widget.borderColor ?? theme.colorScheme.outline,
          width: 1,
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: widget.borderColor ?? theme.colorScheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: widget.focusedBorderColor ?? theme.colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: widget.errorBorderColor ?? theme.colorScheme.error,
          width: 2,
        ),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      filled: false,
      counterText: widget.showCounterText ? null : '',
    );
  }

  Color _getPrefixIconColor(ThemeData theme) {
    if (widget.errorText != null) {
      return theme.colorScheme.error;
    }
    if (_isFocused) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.onSurfaceVariant;
  }

  Color _getSuffixIconColor(ThemeData theme) {
    if (widget.errorText != null) {
      return theme.colorScheme.error;
    }
    if (_isFocused) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.onSurfaceVariant;
  }
}