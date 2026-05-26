/// Idade em anos completos a partir de data no formato dd/mm/aa ou dd/mm/aaaa.
int? calcularIdadeFromDataBr(String? dataBr) {
  if (dataBr == null || dataBr.trim().isEmpty) return null;
  final match =
      RegExp(r'^(\d{2})/(\d{2})/(\d{2}|\d{4})$').firstMatch(dataBr.trim());
  if (match == null) return null;

  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  var year = int.parse(match.group(3)!);
  if (year < 100) year += 2000;

  final nascimento = DateTime.utc(year, month, day);
  if (nascimento.month != month || nascimento.day != day) return null;

  final hoje = DateTime.now().toUtc();
  var idade = hoje.year - nascimento.year;
  if (hoje.month < nascimento.month ||
      (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
    idade--;
  }
  return idade < 0 ? 0 : idade;
}
