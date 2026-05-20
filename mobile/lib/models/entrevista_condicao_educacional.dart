import '../constants/escolaridade_familiar.dart';

class EntrevistaCondicaoEducacional {
  const EntrevistaCondicaoEducacional({
    this.id,
    required this.nome,
    required this.idade,
    required this.escolaridade,
    this.sabeLerEscrever = false,
    this.frequentaEscola = false,
    this.ordem = 0,
  });

  final String? id;
  final String nome;
  final int idade;
  final String escolaridade;
  final bool sabeLerEscrever;
  final bool frequentaEscola;
  final int ordem;

  factory EntrevistaCondicaoEducacional.fromJson(Map<String, dynamic> json) {
    return EntrevistaCondicaoEducacional(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      idade: json['idade'] as int,
      escolaridade: json['escolaridade'] as String,
      sabeLerEscrever: json['sabeLerEscrever'] as bool? ?? false,
      frequentaEscola: json['frequentaEscola'] as bool? ?? false,
      ordem: json['ordem'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'idade': idade,
        'escolaridade': escolaridade,
        'sabeLerEscrever': sabeLerEscrever,
        'frequentaEscola': frequentaEscola,
      };

  EscolaridadeFamiliar? get escolaridadeEnum =>
      EscolaridadeFamiliar.fromApi(escolaridade);
}
