class Bairro {
  const Bairro({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.ativo,
    this.usuarioInclusaoId,
    this.dataHoraInclusao,
    this.usuarioAlteracaoId,
    this.dataHoraAlteracao,
    this.usuarioExclusaoId,
    this.dataHoraExclusao,
    this.createdAt,
  });

  final String id;
  final int codigo;
  final String nome;
  final bool ativo;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final String? usuarioExclusaoId;
  final DateTime? dataHoraExclusao;
  final DateTime? createdAt;

  factory Bairro.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    final codigoRaw = json['codigo'];
    final codigo = codigoRaw is int
        ? codigoRaw
        : int.parse(codigoRaw.toString());

    return Bairro(
      id: json['id'] as String,
      codigo: codigo,
      nome: json['nome'] as String,
      ativo: json['ativo'] as bool,
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),
      usuarioExclusaoId: json['usuarioExclusaoId'] as String?,
      dataHoraExclusao: parseOpt(json['dataHoraExclusao'] as String?),
      createdAt: parseOpt(json['createdAt'] as String?),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'nome': nome,
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome,
      };
}
