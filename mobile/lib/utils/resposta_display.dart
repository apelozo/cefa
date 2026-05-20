import '../models/submissao.dart';
import '../models/tipo_campo.dart';

String formatRespostaSubmissao(RespostaSubmissao resposta) {
  switch (resposta.tipoCampo) {
    case TipoCampo.inteiro:
      return resposta.valorInteiro?.toString() ?? '';
    case TipoCampo.decimal:
      return resposta.valorDecimal ?? '';
    case TipoCampo.texto:
      return resposta.valorTexto ?? '';
    case TipoCampo.logico:
      return resposta.valorLogico == true ? 'Sim' : 'Não';
    case TipoCampo.data:
      return resposta.valorData ?? '';
    case TipoCampo.lista:
      final rotulo = resposta.opcaoRotulo;
      if (rotulo == null || rotulo.isEmpty) return '—';
      if (resposta.opcaoAtiva == false) {
        return '$rotulo (opção inativa)';
      }
      return rotulo;
  }
}

String formatSubmissaoData(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year;
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/$y às $h:$min';
}
