import 'package:flutter/services.dart';

String normalizeTelefone(String value) => value.replaceAll(RegExp(r'\D'), '');

String formatTelefoneDisplay(String digits) {
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return digits;
}

class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = normalizeTelefone(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = formatTelefoneDisplay(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String? validateTelefoneOpcional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final d = normalizeTelefone(value);
  if (d.length < 10 || d.length > 11) return 'Telefone inválido';
  return null;
}

class NisFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
  }
}

String? validateNisOpcional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final d = value.replaceAll(RegExp(r'\D'), '');
  if (d.length != 11) return 'NIS deve ter 11 dígitos';
  return null;
}
