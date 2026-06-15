abstract final class SituacaoRelatorioAlunos {
  static const matriculado = 'MATRICULADO';
  static const matriculaCancelada = 'MATRICULA_CANCELADA';
  static const aMatricular = 'A_MATRICULAR';
  static const todas = 'TODAS';

  static const opcoes = <String, String>{
    matriculado: 'Matriculados',
    matriculaCancelada: 'Matrículas canceladas',
    aMatricular: 'A matricular',
    todas: 'Todas as opções',
  };

  static String rotulo(String? valor) =>
      valor == null ? '' : (opcoes[valor] ?? valor);
}

abstract final class TipoRelatorioAlunosTurma {
  static const resumido = 'RESUMIDO';
  static const detalhado = 'DETALHADO';

  static const opcoes = <String, String>{
    resumido: 'Resumido',
    detalhado: 'Detalhado',
  };

  static String rotulo(String? valor) =>
      valor == null ? '' : (opcoes[valor] ?? valor);
}
