enum EscolaridadeFamiliar {
  nuncaFrequentouEscola('NUNCA_FREQUENTOU_ESCOLA', 'Nunca Frequentou Escola'),
  creche('CRECHE', 'Creche'),
  educacaoInfantil('EDUCACAO_INFANTIL', 'Educação Infantil'),
  ef1Ano('EF_1_ANO', '1º Ano Ens. Fund.'),
  ef2Ano('EF_2_ANO', '2º Ano Ens. Fund.'),
  ef3Ano('EF_3_ANO', '3º Ano Ens. Fund.'),
  ef4Ano('EF_4_ANO', '4º Ano Ens. Fund.'),
  ef5Ano('EF_5_ANO', '5º Ano Ens. Fund.'),
  ef6Ano('EF_6_ANO', '6º Ano Ens. Fund.'),
  ef7Ano('EF_7_ANO', '7º Ano Ens. Fund.'),
  ef8Ano('EF_8_ANO', '8º Ano Ens. Fund.'),
  ef9Ano('EF_9_ANO', '9º Ano Ens. Fund.'),
  em1Ano('EM_1_ANO', '1º Ano Ens. Médio'),
  em2Ano('EM_2_ANO', '2º Ano Ens. Médio'),
  em3Ano('EM_3_ANO', '3º Ano Ens. Médio'),
  superiorIncompleto('SUPERIOR_INCOMPLETO', 'Superior Incompleto'),
  superiorCompleto('SUPERIOR_COMPLETO', 'Superior Completo'),
  ejaEf('EJA_EF', 'EJA - Ens. Fundamental'),
  ejaEm('EJA_EM', 'EJA - Ens. Médio'),
  outros('OUTROS', 'Outros');

  const EscolaridadeFamiliar(this.apiValue, this.rotulo);

  final String apiValue;
  final String rotulo;

  static EscolaridadeFamiliar? fromApi(String? value) {
    if (value == null) return null;
    for (final e in values) {
      if (e.apiValue == value) return e;
    }
    return null;
  }
}
