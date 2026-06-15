import 'auditoria_campos.dart';

class Bairro {
  const Bairro({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.ativo,
    this.auditoria = const AuditoriaCampos(),
    this.usuarioInclusaoId,
    this.dataHoraInclusao,
    this.usuarioInclusaoNomeUsuario,
    this.usuarioInclusaoNome,
    this.usuarioAlteracaoId,
    this.dataHoraAlteracao,
    this.usuarioAlteracaoNomeUsuario,
    this.usuarioAlteracaoNome,
    this.usuarioExclusaoId,
    this.dataHoraExclusao,
    this.usuarioExclusaoNomeUsuario,
    this.usuarioExclusaoNome,
    this.createdAt,
  });

  final String id;
  final int codigo;
  final String nome;
  final bool ativo;
  final AuditoriaCampos auditoria;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioInclusaoNomeUsuario;
  final String? usuarioInclusaoNome;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final String? usuarioAlteracaoNomeUsuario;
  final String? usuarioAlteracaoNome;
  final String? usuarioExclusaoId;
  final DateTime? dataHoraExclusao;
  final String? usuarioExclusaoNomeUsuario;
  final String? usuarioExclusaoNome;
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
      auditoria: AuditoriaCampos.fromJson(json),
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),
      usuarioInclusaoNomeUsuario:
          json['usuarioInclusaoNomeUsuario'] as String?,
      usuarioInclusaoNome: json['usuarioInclusaoNome'] as String?,
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),
      usuarioAlteracaoNomeUsuario:
          json['usuarioAlteracaoNomeUsuario'] as String?,
      usuarioAlteracaoNome: json['usuarioAlteracaoNome'] as String?,
      usuarioExclusaoId: json['usuarioExclusaoId'] as String?,
      dataHoraExclusao: parseOpt(json['dataHoraExclusao'] as String?),
      usuarioExclusaoNomeUsuario:
          json['usuarioExclusaoNomeUsuario'] as String?,
      usuarioExclusaoNome: json['usuarioExclusaoNome'] as String?,
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
