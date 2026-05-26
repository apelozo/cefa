/// Tipo de moradia do aluno de capacitação (valores da API).
abstract final class TipoCasaAlunoCapacitacao {
  static const propria = 'PROPRIA';
  static const cedida = 'CEDIDA';
  static const aluguel = 'ALUGUEL';

  static const opcoes = <String, String>{
    propria: 'Própria',
    cedida: 'Cedida',
    aluguel: 'Aluguel',
  };

  static String? rotulo(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    return opcoes[valor];
  }
}
