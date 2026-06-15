/// Campos de auditoria expostos pela API (inclusão, alteração e soft delete).
class AuditoriaCampos {
  const AuditoriaCampos({
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
  });

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

  factory AuditoriaCampos.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isEmpty) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return AuditoriaCampos(
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao']) ??
          parseOpt(json['createdAt']),
      usuarioInclusaoNomeUsuario:
          json['usuarioInclusaoNomeUsuario'] as String?,
      usuarioInclusaoNome: json['usuarioInclusaoNome'] as String?,
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao']),
      usuarioAlteracaoNomeUsuario:
          json['usuarioAlteracaoNomeUsuario'] as String?,
      usuarioAlteracaoNome: json['usuarioAlteracaoNome'] as String?,
      usuarioExclusaoId: json['usuarioExclusaoId'] as String?,
      dataHoraExclusao: parseOpt(json['dataHoraExclusao']),
      usuarioExclusaoNomeUsuario:
          json['usuarioExclusaoNomeUsuario'] as String?,
      usuarioExclusaoNome: json['usuarioExclusaoNome'] as String?,
    );
  }

  bool get temAlgumRegistro =>
      dataHoraInclusao != null ||
      dataHoraAlteracao != null ||
      dataHoraExclusao != null;
}
