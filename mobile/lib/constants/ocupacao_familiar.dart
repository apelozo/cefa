enum OcupacaoFamiliar {
  naoTrabalha('NAO_TRABALHA', '0 - Não Trabalha'),
  contaPropria(
    'CONTA_PROPRIA',
    '1 - Trabalhador por conta própria (bico, autônomo)',
  ),
  temporarioRural(
    'TEMPORARIO_RURAL',
    '2 - Trabalhador Temporário em área rural',
  ),
  empregadoSemCarteira(
    'EMPREGADO_SEM_CARTEIRA',
    '3 - Empregado sem carteira de trabalho assinada',
  ),
  empregadoComCarteira(
    'EMPREGADO_COM_CARTEIRA',
    '4 - Empregado com carteira de trabalho assinada',
  ),
  domesticoSemCarteira(
    'DOMESTICO_SEM_CARTEIRA',
    '5 - Trabalhador doméstico sem carteira e trabalho assinada',
  ),
  domesticoComCarteira(
    'DOMESTICO_COM_CARTEIRA',
    '6 - Trabalhador doméstico com carteira de trabalho assinada',
  ),
  naoRemunerado('NAO_REMUNERADO', '7 - Trabalhador não remunerado'),
  militarServidorPublico(
    'MILITAR_SERVIDOR_PUBLICO',
    '8 - Militar ou Servidor Público',
  ),
  empregador('EMPREGADOR', '9 - Empregador'),
  estagiario('ESTAGIARIO', '10 - Estagiário'),
  aprendiz('APRENDIZ', '11 - Aprendiz');

  const OcupacaoFamiliar(this.apiValue, this.rotulo);

  final String apiValue;
  final String rotulo;

  static OcupacaoFamiliar? fromApi(String? value) {
    if (value == null) return null;
    for (final o in values) {
      if (o.apiValue == value) return o;
    }
    return null;
  }
}
