import 'package:flutter/services.dart';

/// Máscara dd/mm/aa — o usuário digita só os 2 últimos dígitos do ano.
class DataBrFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String? validateDataBr(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe a data';
  }
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{2}|\d{4})$').firstMatch(value.trim());
  if (match == null) {
    return 'Use o formato dd/mm/aa';
  }
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  var year = int.parse(match.group(3)!);
  if (year < 100) year += 2000;
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return 'Data inválida';
  }
  return null;
}

/// Converte dd/mm/aa para dd/mm/aaaa (ano com 4 dígitos) para envio à API.
String normalizarDataBr(String value) {
  final trimmed = value.trim();
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{2}|\d{4})$').firstMatch(trimmed)!;
  var year = int.parse(match.group(3)!);
  if (year < 100) year += 2000;
  final day = match.group(1)!;
  final month = match.group(2)!;
  return '$day/$month/$year';
}

/// Exibição dd/mm/aaaa — expande ano de 2 para 4 dígitos quando o formato é válido.
String formatarDataBrExibicao4Anos(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{2}|\d{4})$').firstMatch(trimmed);
  if (match == null) return trimmed;
  return normalizarDataBr(trimmed);
}
