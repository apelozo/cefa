class Departamento {
  const Departamento({
    required this.id,
    required this.codigo,
    required this.descricao,
    required this.ativo,
    this.usuarioInclusaoId,
    this.dataHoraInclusao,
    this.usuarioAlteracaoId,
    this.dataHoraAlteracao,
    this.createdAt,
  });

  final String id;
  final int codigo;
  final String descricao;
  final bool ativo;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final DateTime? createdAt;

  factory Departamento.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    final codigoRaw = json['codigo'];
    final codigo = codigoRaw is int
        ? codigoRaw
        : int.parse(codigoRaw.toString());

    return Departamento(
      id: json['id'] as String,
      codigo: codigo,
      descricao: json['descricao'] as String,
      ativo: json['ativo'] as bool,
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),
      createdAt: parseOpt(json['createdAt'] as String?),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'descricao': descricao,
      };

  Map<String, dynamic> toUpdateJson() => {
        'descricao': descricao,
      };
}
