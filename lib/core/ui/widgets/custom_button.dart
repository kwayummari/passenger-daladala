import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Changed to nullable
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final bool disabled; // Made non-nullable with default value
  final Color? backgroundColor; // Added for custom background color
  final Color? textColor; // Added for custom text color
  final Color? borderColor; // Added for custom border color

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
    this.height = 50,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    this.textStyle,
    this.disabled = false, // Default to false
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  // Convenience constructor for disabled state
  const CustomButton.disabled({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
    this.height = 50,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    this.textStyle,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : disabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine if button should be disabled
    final bool isDisabled = disabled || isLoading || onPressed == null;

    Widget buttonChild() {
      if (isLoading) {
        return SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              _getLoadingColor(theme, isDisabled),
            ),
            strokeWidth: 2.5,
          ),
        );
      } else if (icon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _getForegroundColor(theme, isDisabled)),
            const SizedBox(width: 8),
            Text(text, style: textStyle ?? _getTextStyle(theme, isDisabled)),
          ],
        );
      } else {
        return Text(text, style: textStyle ?? _getTextStyle(theme, isDisabled));
      }
    }

    Widget buttonContent = Container(
      height: height,
      width: isFullWidth ? double.infinity : width,
      padding: padding,
      child: Center(child: buttonChild()),
    );

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getBackgroundColor(theme, isDisabled),
            foregroundColor: _getForegroundColor(theme, isDisabled),
            elevation: isDisabled ? 0 : 2,
            shadowColor: isDisabled ? Colors.transparent : null,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonContent,
        );

      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _getForegroundColor(theme, isDisabled),
            backgroundColor:
                isDisabled ? Colors.grey.shade100 : Colors.transparent,
            side: BorderSide(
              color: _getBorderColor(theme, isDisabled),
              width: 1.5,
            ),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonContent,
        );

      case ButtonType.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _getForegroundColor(theme, isDisabled),
            backgroundColor:
                isDisabled ? Colors.transparent : Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonContent,
        );
    }
  }

  TextStyle _getTextStyle(ThemeData theme, bool isDisabled) {
    Color color;

    if (textColor != null && !isDisabled) {
      color = textColor!;
    } else {
      switch (type) {
        case ButtonType.primary:
          color = isDisabled ? Colors.grey.shade500 : Colors.white;
          break;
        case ButtonType.secondary:
        case ButtonType.text:
          color = isDisabled ? Colors.grey.shade400 : theme.primaryColor;
          break;
      }
    }

    return theme.textTheme.labelLarge!.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  Color _getForegroundColor(ThemeData theme, bool isDisabled) {
    if (textColor != null && !isDisabled) {
      return textColor!;
    }

    switch (type) {
      case ButtonType.primary:
        return isDisabled ? Colors.grey.shade500 : Colors.white;
      case ButtonType.secondary:
      case ButtonType.text:
        return isDisabled ? Colors.grey.shade400 : theme.primaryColor;
    }
  }

  Color _getBackgroundColor(ThemeData theme, bool isDisabled) {
    if (backgroundColor != null && !isDisabled) {
      return backgroundColor!;
    }

    switch (type) {
      case ButtonType.primary:
        return isDisabled ? Colors.grey.shade300 : theme.primaryColor;
      case ButtonType.secondary:
        return isDisabled ? Colors.grey.shade100 : Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getBorderColor(ThemeData theme, bool isDisabled) {
    if (borderColor != null && !isDisabled) {
      return borderColor!;
    }

    return isDisabled ? Colors.grey.shade300 : theme.primaryColor;
  }

  Color _getLoadingColor(ThemeData theme, bool isDisabled) {
    switch (type) {
      case ButtonType.primary:
        return isDisabled ? Colors.grey.shade500 : Colors.white;
      case ButtonType.secondary:
      case ButtonType.text:
        return isDisabled ? Colors.grey.shade400 : theme.primaryColor;
    }
  }
}
