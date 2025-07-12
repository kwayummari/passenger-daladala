import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final TextInputType keyboardType;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode autovalidateMode;
  final EdgeInsets contentPadding;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  const CustomInput({
    Key? key,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.controller,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.suffix,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.contentPadding = const EdgeInsets.all(16),
    this.readOnly = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  }) : super(key: key);

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget? passwordVisibilityToggle;
    if (widget.obscureText) {
      passwordVisibilityToggle = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: theme.iconTheme.color,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            contentPadding: widget.contentPadding,
            prefixIcon: widget.prefix,
            suffixIcon: widget.obscureText 
                ? passwordVisibilityToggle 
                : widget.suffix,
            counterText: '',
            filled: true,
            fillColor: widget.enabled ? Colors.white : theme.disabledColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}