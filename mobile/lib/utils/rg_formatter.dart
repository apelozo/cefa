import 'package:flutter/services.dart';

String normalizeRg(String rg) =>
    rg.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

String formatRgDisplay(String rg) {
  final n = normalizeRg(rg);
  if (n.length == 9 && RegExp(r'^\d+$').hasMatch(n)) {
    return '${n.substring(0, 2)}.${n.substring(2, 5)}.${n.substring(5, 8)}-${n.substring(8)}';
  }
  return n;
}

class RgFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase();
    final cleaned = raw.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.length > 20) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8 && cleaned.length > 8) buffer.write('-');
      buffer.write(cleaned[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
