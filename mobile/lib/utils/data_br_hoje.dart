/// Data de hoje no formato dd/mm/aa (entrada do usuário).
String dataBrHojeCurta() {
  final now = DateTime.now();
  final d = now.day.toString().padLeft(2, '0');
  final m = now.month.toString().padLeft(2, '0');
  final y = (now.year % 100).toString().padLeft(2, '0');
  return '$d/$m/$y';
}

/// Data de hoje no formato dd/mm/aaaa (exibição com ano de 4 dígitos).
String dataBrHoje4Anos() {
  final now = DateTime.now();
  final d = now.day.toString().padLeft(2, '0');
  final m = now.month.toString().padLeft(2, '0');
  final y = now.year.toString();
  return '$d/$m/$y';
}
