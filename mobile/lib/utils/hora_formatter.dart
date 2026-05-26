import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Normaliza entrada de hora para `HH:mm` (ex.: `0800` → `08:00`).
String formatHoraOnBlur(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  final padded = digits.length > 4
      ? digits.substring(digits.length - 4)
      : digits.padLeft(4, '0');
  final h = int.tryParse(padded.substring(0, 2));
  final m = int.tryParse(padded.substring(2, 4));
  if (h == null || m == null || h > 23 || m > 59) {
    return value.trim();
  }
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Aceita apenas dígitos (até 4) enquanto digita.
class HoraInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) return oldValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

void aplicarFormatoHoraAoSair(TextEditingController controller) {
  final formatted = formatHoraOnBlur(controller.text);
  if (formatted != controller.text) {
    controller.text = formatted;
  }
}
