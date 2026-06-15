import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navegação com Enter entre campos de texto e botão de gravar.
class FormEnterFocus {
  FormEnterFocus(this.fields, {FocusNode? submitFocusNode})
      : submitFocusNode = submitFocusNode ?? FocusNode();

  final List<FocusNode> fields;
  final FocusNode submitFocusNode;

  factory FormEnterFocus.count(int count, {bool withSubmit = true}) {
    return FormEnterFocus(
      List.generate(count, (_) => FocusNode()),
      submitFocusNode: withSubmit ? FocusNode() : null,
    );
  }

  void dispose() {
    for (final node in fields) {
      node.dispose();
    }
    submitFocusNode.dispose();
  }

  TextInputAction inputAction(int index) {
    if (index < fields.length - 1) {
      return TextInputAction.next;
    }
    return TextInputAction.done;
  }

  /// Avança para o próximo campo ou para o botão de envio.
  void onSubmitted(int index) {
    final FocusNode target;
    if (index >= 0 && index < fields.length - 1) {
      target = fields[index + 1];
    } else {
      target = submitFocusNode;
    }

    void request() {
      if (target.canRequestFocus) {
        target.requestFocus();
      }
    }

    // Tenta focar imediatamente (responde melhor no Web/Windows) e mantém o
    // post-frame como fallback, pois o campo atual pode ainda “segurar” o foco.
    request();
    WidgetsBinding.instance.addPostFrameCallback((_) => request());
  }

  /// Teclado físico (Windows/Web/desktop): Enter avança o foco.
  KeyEventResult handleEnterKey(int index, FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (node.hasFocus) {
      onSubmitted(index);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Mesmo efeito de [onSubmitted]; necessário no desktop quando Enter não
  /// dispara [TextFormField.onFieldSubmitted].
  VoidCallback editingComplete(int index) => () => onSubmitted(index);

  /// Para listas dinâmicas (ex.: formulário de lançamento).
  static void chainSubmit({
    required List<FocusNode> orderedFields,
    required FocusNode current,
    required FocusNode submitFocusNode,
  }) {
    final index = orderedFields.indexOf(current);
    if (index < 0) return;

    final FocusNode target;
    if (index + 1 < orderedFields.length) {
      target = orderedFields[index + 1];
    } else {
      target = submitFocusNode;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (target.canRequestFocus) {
        target.requestFocus();
      }
    });
  }
}
