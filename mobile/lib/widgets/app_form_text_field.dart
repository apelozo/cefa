import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/form_enter_focus.dart';

/// [TextFormField] com navegação Enter via [FormEnterFocus].
class AppFormTextField extends StatelessWidget {
  const AppFormTextField({
    super.key,
    required this.enterFocus,
    required this.enterIndex,
    required this.controller,
    this.decoration,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.suffixIcon,
  });

  final FormEnterFocus enterFocus;
  final int enterIndex;
  final TextEditingController controller;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  bool get _chainEnter => (maxLines ?? 1) == 1;

  @override
  Widget build(BuildContext context) {
    final focusNode = enterFocus.fields[enterIndex];
    final decoration = (this.decoration ?? const InputDecoration()).copyWith(
      suffixIcon: suffixIcon ?? this.decoration?.suffixIcon,
    );

    return Focus(
      onKeyEvent: _chainEnter
          ? (_, event) =>
              enterFocus.handleEnterKey(enterIndex, focusNode, event)
          : null,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        decoration: decoration,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        textInputAction: _chainEnter
            ? enterFocus.inputAction(enterIndex)
            : TextInputAction.newline,
        onFieldSubmitted:
            _chainEnter ? (_) => enterFocus.onSubmitted(enterIndex) : null,
        onEditingComplete:
            _chainEnter ? enterFocus.editingComplete(enterIndex) : null,
        onChanged: onChanged,
      ),
    );
  }
}
