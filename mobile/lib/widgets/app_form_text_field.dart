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
    this.onEnterAdvance,
  });

  final FormEnterFocus enterFocus;
  final int enterIndex;
  /// Quando informado, substitui [FormEnterFocus.onSubmitted] (ex.: pular campo
  /// condicional ou mudar de aba).
  final VoidCallback? onEnterAdvance;
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

  void _advanceOnEnter() {
    if (onEnterAdvance != null) {
      onEnterAdvance!();
    } else {
      enterFocus.onSubmitted(enterIndex);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_chainEnter) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (node.hasFocus) {
      _advanceOnEnter();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = enterFocus.fields[enterIndex];
    final decoration = (this.decoration ?? const InputDecoration()).copyWith(
      suffixIcon: suffixIcon ?? this.decoration?.suffixIcon,
    );

    final field = TextFormField(
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
      onFieldSubmitted: _chainEnter ? (_) => _advanceOnEnter() : null,
      onEditingComplete: _chainEnter ? _advanceOnEnter : null,
      onChanged: onChanged,
    );

    if (!_chainEnter) return field;

    return Focus(
      onKeyEvent: (_, event) => _onKey(focusNode, event),
      child: field,
    );
  }
}
