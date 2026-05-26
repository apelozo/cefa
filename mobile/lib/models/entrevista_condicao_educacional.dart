class EntrevistaCondicaoEducacional {
  const EntrevistaCondicaoEducacional({
    this.id,
    required this.nome,
    required this.idade,
    required this.escolaridadeCodigo,
    this.escolaridadeRotulo,
    this.sabeLerEscrever = false,
    this.frequentaEscola = false,
    this.ordem = 0,
  });

  final String? id;
  final String nome;
  final int idade;
  final int escolaridadeCodigo;
  final String? escolaridadeRotulo;
  final bool sabeLerEscrever;
  final bool frequentaEscola;
  final int ordem;

  factory EntrevistaCondicaoEducacional.fromJson(Map<String, dynamic> json) {
    final codigoRaw = json['escolaridadeCodigo'];
    final codigo = codigoRaw is int
        ? codigoRaw
        : int.parse(codigoRaw.toString());

    return EntrevistaCondicaoEducacional(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      idade: json['idade'] as int,
      escolaridadeCodigo: codigo,
      escolaridadeRotulo: json['escolaridadeRotulo'] as String?,
      sabeLerEscrever: json['sabeLerEscrever'] as bool? ?? false,
      frequentaEscola: json['frequentaEscola'] as bool? ?? false,
      ordem: json['ordem'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'idade': idade,
        'escolaridadeCodigo': escolaridadeCodigo,
        'sabeLerEscrever': sabeLerEscrever,
        'frequentaEscola': frequentaEscola,
      };
}
