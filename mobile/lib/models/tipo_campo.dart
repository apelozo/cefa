enum TipoCampo {
  inteiro('INTEIRO'),
  decimal('DECIMAL'),
  texto('TEXTO'),
  logico('LOGICO'),
  data('DATA'),
  lista('LISTA');

  const TipoCampo(this.value);
  final String value;

  static TipoCampo fromString(String value) {
    return TipoCampo.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Tipo de campo inválido: $value'),
    );
  }

  String get label {
    switch (this) {
      case TipoCampo.inteiro:
        return 'Inteiro';
      case TipoCampo.decimal:
        return 'Decimal';
      case TipoCampo.texto:
        return 'Texto';
      case TipoCampo.logico:
        return 'Lógico';
      case TipoCampo.data:
        return 'Data';
      case TipoCampo.lista:
        return 'Lista (seleção)';
    }
  }
}
