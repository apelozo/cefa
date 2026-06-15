abstract final class PeriodoInscricao {
  static const manha = 'MANHA';
  static const tarde = 'TARDE';
  static const noite = 'NOITE';

  static const opcoes = <String, String>{
    manha: 'Manhã',
    tarde: 'Tarde',
    noite: 'Noite',
  };

  static String rotulo(String? valor) =>
      valor == null ? '' : (opcoes[valor] ?? valor);
}
