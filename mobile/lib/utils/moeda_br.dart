import 'package:flutter/material.dart';

/// Converte texto monetário BR (1.234,56 ou 1234.56) para double.
double parseMoedaBr(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  final normalized = trimmed.replaceAll(RegExp(r'[^\d,.-]'), '');
  if (normalized.isEmpty) return 0;
  final semMilhar = normalized.contains(',')
      ? normalized.replaceAll('.', '').replaceAll(',', '.')
      : normalized;
  final n = double.tryParse(semMilhar);
  if (n == null || n < 0) return 0;
  return n;
}

/// Formata número como moeda BR (R$ 1.234,56).
String formatMoedaBr(double value) {
  final neg = value < 0;
  final abs = value.abs();
  final parts = abs.toStringAsFixed(2).split('.');
  final inteiros = parts[0];
  final dec = parts.length > 1 ? parts[1] : '00';
  final buffer = StringBuffer();
  for (var i = 0; i < inteiros.length; i++) {
    if (i > 0 && (inteiros.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiros[i]);
  }
  final s = '${buffer.toString()},$dec';
  return neg ? '-$s' : s;
}

/// Formata o texto do controller como moeda BR (ex.: 2500 → 2.500,00).
/// Use ao sair do campo (perda de foco), não durante a digitação.
void formatarMoedaBrNoController(TextEditingController controller) {
  final trimmed = controller.text.trim();
  if (trimmed.isEmpty) return;
  final formatado = formatMoedaBr(parseMoedaBr(trimmed));
  if (controller.text != formatado) {
    controller.value = TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}
