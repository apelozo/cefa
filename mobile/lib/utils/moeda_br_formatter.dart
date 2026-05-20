import 'package:flutter/services.dart';

import 'moeda_br.dart';

/// Máscara monetária BR aplicada a cada tecla (pode atrapalhar a digitação).
/// Preferir digitação livre + [formatarMoedaBrNoController] ao sair do campo.
class MoedaBrFormatter extends TextInputFormatter {
  static const _maxDigitosInteiros = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d,]'), '');
    if (cleaned.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (','.allMatches(cleaned).length > 1) return oldValue;

    final String intDigits;
    var decDigits = '';
    if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      intDigits = parts[0];
      if (parts.length > 1) decDigits = parts[1];
    } else {
      intDigits = cleaned;
    }

    if (intDigits.length > _maxDigitosInteiros) return oldValue;
    if (decDigits.length > 2) decDigits = decDigits.substring(0, 2);

    final inteiros =
        intDigits.isEmpty ? 0 : (int.tryParse(intDigits) ?? 0);
    final value = inteiros + _fracaoDecimal(decDigits);

    final text = formatMoedaBr(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static double _fracaoDecimal(String decDigits) {
    if (decDigits.isEmpty) return 0;
    if (decDigits.length == 1) {
      return int.parse(decDigits) / 10;
    }
    return int.parse(decDigits.substring(0, 2)) / 100;
  }
}
