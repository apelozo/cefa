enum TipoDeficienciaFamiliar {
  cegueira('CEGUEIRA', 'Cegueira'),
  baixaVisao('BAIXA_VISAO', 'Baixa Visão'),
  surdezLeveModerada('SURDEZ_LEVE_MODERADA', 'Surdez leve/moderada'),
  deficienciaFisica('DEFICIENCIA_FISICA', 'Deficiencia Fisica'),
  deficienciaMentalIntelectual(
    'DEFICIENCIA_MENTAL_INTELECTUAL',
    'Deficiencia Mental ou Intelectual',
  ),
  sindromeDown('SINDROME_DOWN', 'Sindrome de Down'),
  transtornoMental('TRANSTORNO_MENTAL', 'Transtorno Mental');

  const TipoDeficienciaFamiliar(this.apiValue, this.rotulo);

  final String apiValue;
  final String rotulo;

  static TipoDeficienciaFamiliar? fromApi(String? value) {
    if (value == null) return null;
    for (final t in values) {
      if (t.apiValue == value) return t;
    }
    return null;
  }
}
