class EntrevistaComposicaoFamiliar {
  const EntrevistaComposicaoFamiliar({
    this.id,
    required this.nome,
    this.cpf,
    required this.dtNascimento,
    required this.parentesco,
    this.ordem = 0,
  });

  final String? id;
  final String nome;
  final String? cpf;
  final String dtNascimento;
  final String parentesco;
  final int ordem;

  factory EntrevistaComposicaoFamiliar.fromJson(Map<String, dynamic> json) {
    return EntrevistaComposicaoFamiliar(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      cpf: json['cpf'] as String?,
      dtNascimento: json['dtNascimento'] as String,
      parentesco: json['parentesco'] as String,
      ordem: json['ordem'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        if (cpf != null && cpf!.isNotEmpty) 'cpf': cpf,
        'dtNascimento': dtNascimento,
        'parentesco': parentesco,
      };
}
