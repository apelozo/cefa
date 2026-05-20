import 'package:flutter/material.dart';

/// Avanço de foco entre campos da entrevista (com post-frame).
abstract final class EntrevistaFocus {
  static void advance(FocusNode? node) {
    if (node == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }
}
