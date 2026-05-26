import 'hora_formatter.dart';

String? validateHoraOpcional(String? value) {
  final t = formatHoraOnBlur(value?.trim() ?? '');
  if (t.isEmpty) return null;
  if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(t)) {
    return 'Use o formato HH:mm';
  }
  final parts = t.split(':');
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h > 23 || m > 59) {
    return 'Hora inválida';
  }
  return null;
}

String? validateHoraObrigatoria(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) return 'Informe a hora';
  return validateHoraOpcional(t);
}

int _minutos(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String? validateHoraTerminoAposInicio(String? termino, String inicio) {
  final terminoFmt = formatHoraOnBlur(termino?.trim() ?? '');
  final inicioFmt = formatHoraOnBlur(inicio.trim());
  final err = validateHoraObrigatoria(terminoFmt);
  if (err != null) return err;
  final errInicio = validateHoraObrigatoria(inicioFmt);
  if (errInicio != null) return null;
  if (_minutos(terminoFmt) <= _minutos(inicioFmt)) {
    return 'Deve ser posterior à hora início';
  }
  return null;
}
