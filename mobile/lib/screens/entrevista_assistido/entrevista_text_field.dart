import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto da entrevista com Enter avançando para o próximo foco.
class EntrevistaTextField extends StatelessWidget {
  const EntrevistaTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onAdvance,
    this.readOnly = false,
    this.decoration,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.textInputAction,
    this.beforeAdvance,
    this.onTapOutside,
    this.chainEnter = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdvance;
  final bool readOnly;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? beforeAdvance;
  final TapRegionCallback? onTapOutside;
  final bool chainEnter;

  bool get _useEnterChain => chainEnter && !readOnly && (maxLines ?? 1) == 1;

  void _advance() {
    beforeAdvance?.call();
    onAdvance();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_useEnterChain) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (node.hasFocus) {
      _advance();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      decoration: decoration,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      textInputAction: _useEnterChain
          ? (textInputAction ?? TextInputAction.next)
          : TextInputAction.newline,
      onFieldSubmitted: _useEnterChain ? (_) => _advance() : null,
      onEditingComplete: _useEnterChain ? _advance : null,
      onTapOutside: onTapOutside,
    );

    if (!_useEnterChain) return field;

    return Focus(
      onKeyEvent: (_, event) => _onKey(focusNode, event),
      child: field,
    );
  }
}
