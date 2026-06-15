abstract final class SituacaoTurma {
  static const aberta = 'ABERTA';
  static const fechada = 'FECHADA';

  static const opcoes = <String, String>{
    aberta: 'Aberta',
    fechada: 'Fechada',
  };

  static String rotulo(String? valor) =>
      valor == null ? '' : (opcoes[valor] ?? valor);
}
