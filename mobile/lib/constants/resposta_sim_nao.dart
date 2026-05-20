enum RespostaSimNao {
  sim('SIM', 'Sim'),
  nao('NAO', 'Não');

  const RespostaSimNao(this.apiValue, this.rotulo);

  final String apiValue;
  final String rotulo;

  static RespostaSimNao? fromApi(String? value) {
    if (value == null) return null;
    for (final r in values) {
      if (r.apiValue == value) return r;
    }
    return null;
  }
}
