import 'auditoria_campos.dart';

class Curso {
  const Curso({
    required this.id,
    required this.codigo,
    required this.descricao,
    required this.ativo,
    this.auditoria = const AuditoriaCampos(),
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
  final AuditoriaCampos auditoria;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final DateTime? createdAt;

  factory Curso.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    final codigoRaw = json['codigo'];
    final codigo =
        codigoRaw is int ? codigoRaw : int.parse(codigoRaw.toString());

    return Curso(
      id: json['id'] as String,
      codigo: codigo,
      descricao: json['descricao'] as String,
      ativo: json['ativo'] as bool,
      auditoria: AuditoriaCampos.fromJson(json),
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
