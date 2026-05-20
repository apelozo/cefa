import 'package:flutter/services.dart';

String normalizeCpf(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');

String formatCpfDisplay(String cpf) {
  final d = normalizeCpf(cpf);
  if (d.length != 11) return cpf;
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
}

bool isValidCpf(String cpf) {
  final digits = normalizeCpf(cpf);
  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

  var sum = 0;
  for (var i = 0; i < 9; i++) {
    sum += int.parse(digits[i]) * (10 - i);
  }
  var rest = (sum * 10) % 11;
  if (rest == 10) rest = 0;
  if (rest != int.parse(digits[9])) return false;

  sum = 0;
  for (var i = 0; i < 10; i++) {
    sum += int.parse(digits[i]) * (11 - i);
  }
  rest = (sum * 10) % 11;
  if (rest == 10) rest = 0;
  return rest == int.parse(digits[10]);
}

class CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String? validateCpf(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe o CPF';
  }
  if (!isValidCpf(value)) {
    return 'CPF inválido';
  }
  return null;
}

String? validateCpfOpcional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  if (!isValidCpf(value)) return 'CPF inválido';
  return null;
}
