class AlunoCapacitacaoRendaFamiliar {
  const AlunoCapacitacaoRendaFamiliar({
    this.id,
    this.ordem = 0,
    required this.nome,
    this.idade,
    this.renda = 0,
    this.parentesco,
    this.profissao,
  });

  final String? id;
  final int ordem;
  final String nome;
  final int? idade;
  final double renda;
  final String? parentesco;
  final String? profissao;

  factory AlunoCapacitacaoRendaFamiliar.fromJson(Map<String, dynamic> json) {
    final rendaRaw = json['renda'];
    final renda = rendaRaw is num
        ? rendaRaw.toDouble()
        : double.tryParse(rendaRaw?.toString() ?? '') ?? 0;

    return AlunoCapacitacaoRendaFamiliar(
      id: json['id'] as String?,
      ordem: json['ordem'] is int
          ? json['ordem'] as int
          : int.parse(json['ordem'].toString()),
      nome: json['nome'] as String,
      idade: json['idade'] == null
          ? null
          : (json['idade'] is int
              ? json['idade'] as int
              : int.tryParse(json['idade'].toString())),
      renda: renda,
      parentesco: json['parentesco'] as String?,
      profissao: json['profissao'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (nome.trim().isNotEmpty) 'nome': nome.trim(),
        if (idade != null) 'idade': idade,
        'renda': renda,
        if (parentesco != null && parentesco!.trim().isNotEmpty)
          'parentesco': parentesco!.trim(),
        if (profissao != null && profissao!.trim().isNotEmpty)
          'profissao': profissao!.trim(),
      };
}
