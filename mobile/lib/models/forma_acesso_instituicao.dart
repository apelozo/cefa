enum FormaAcessoInstituicao {
  demandaEspontanea('DEMANDA_ESPONTANEA', 'Por Demanda Espontânea'),
  buscaAtiva('BUSCA_ATIVA', 'Busca Ativa Realizada'),
  encaminhamentoAssistenciaSocial(
    'ENCAMINHAMENTO_ASSISTENCIA_SOCIAL',
    'Encaminhamento da Assistência Social',
  ),
  encaminhamentoSaude(
    'ENCAMINHAMENTO_SAUDE',
    'Encaminhamento da Saúde',
  ),
  encaminhamentoEducacao(
    'ENCAMINHAMENTO_EDUCACAO',
    'Encaminhamento da Educação',
  ),
  encaminhamentoConselhoTutelar(
    'ENCAMINHAMENTO_CONSELHO_TUTELAR',
    'Encaminhamento do Conselho Tutelar',
  ),
  encaminhamentoGarantiaDireitos(
    'ENCAMINHAMENTO_GARANTIA_DIREITOS',
    'Encaminhamento Sistema de Garantia de Direitos',
  ),
  outros('OUTROS', 'Outros');

  const FormaAcessoInstituicao(this.apiValue, this.rotulo);

  final String apiValue;
  final String rotulo;

  static const textoFixoAssistencia =
      'De que forma a família (ou membro da família) acessou a instituição para o primeiro atendimento?';

  static List<FormaAcessoInstituicao> get opcoesAssistencia => values;

  static FormaAcessoInstituicao? fromApi(String? value) {
    if (value == null) return null;
    for (final f in values) {
      if (f.apiValue == value) return f;
    }
    return null;
  }
}
