import 'auditoria_campos.dart';

class Cidade {
  const Cidade({
    required this.id,
    required this.codigo,
    required this.nomeMunicipio,
    required this.estado,
    required this.ativo,
    this.auditoria = const AuditoriaCampos(),
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
  final String nomeMunicipio;
  final String estado;
  final bool ativo;
  final AuditoriaCampos auditoria;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final String? usuarioExclusaoId;
  final DateTime? dataHoraExclusao;
  final DateTime? createdAt;

  String get rotuloSelect => '$codigo — $nomeMunicipio ($estado)';

  factory Cidade.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    final codigoRaw = json['codigo'];
    final codigo = codigoRaw is int
        ? codigoRaw
        : int.parse(codigoRaw.toString());

    return Cidade(
      id: json['id'] as String,
      codigo: codigo,
      nomeMunicipio: json['nomeMunicipio'] as String,
      estado: json['estado'] as String,
      ativo: json['ativo'] as bool,
      auditoria: AuditoriaCampos.fromJson(json),
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
        'nomeMunicipio': nomeMunicipio,
        'estado': estado,
      };

  Map<String, dynamic> toUpdateJson() => {
        'nomeMunicipio': nomeMunicipio,
        'estado': estado,
      };
}
