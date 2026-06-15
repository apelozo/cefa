class InscricaoRendaFamiliar {
  const InscricaoRendaFamiliar({
    this.id,
    this.ordem,
    required this.nome,
    this.idade,
    required this.renda,
    this.rendaFormatada,
    this.parentesco,
    this.profissao,
  });

  final String? id;
  final int? ordem;
  final String nome;
  final int? idade;
  final double renda;
  final String? rendaFormatada;
  final String? parentesco;
  final String? profissao;

  factory InscricaoRendaFamiliar.fromJson(Map<String, dynamic> json) {
    double parseRenda(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int? parseIntOpt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return InscricaoRendaFamiliar(
      id: json['id'] as String?,
      ordem: parseIntOpt(json['ordem']),
      nome: json['nome'] as String,
      idade: parseIntOpt(json['idade']),
      renda: parseRenda(json['renda']),
      rendaFormatada: json['rendaFormatada'] as String?,
      parentesco: json['parentesco'] as String?,
      profissao: json['profissao'] as String?,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'nome': nome.trim(),
        if (idade != null) 'idade': idade,
        'renda': renda,
        if (parentesco != null && parentesco!.trim().isNotEmpty)
          'parentesco': parentesco!.trim(),
        if (profissao != null && profissao!.trim().isNotEmpty)
          'profissao': profissao!.trim(),
      };
}
