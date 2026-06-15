import 'auditoria_campos.dart';

class Programa {
  const Programa({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.autoListagem,
    this.moduloSistemaId,
    this.moduloCodigo,
    this.moduloNome,
    this.relatorioSubmoduloId,
    this.relatorioSubmoduloCodigo,
    this.relatorioSubmoduloNome,
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final String codigo;
  final String nome;
  final bool autoListagem;
  final String? moduloSistemaId;
  final int? moduloCodigo;
  final String? moduloNome;
  final String? relatorioSubmoduloId;
  final String? relatorioSubmoduloCodigo;
  final String? relatorioSubmoduloNome;
  final AuditoriaCampos auditoria;

  Map<String, dynamic> toCreateJson() => {
        'codigo': codigo,
        'nome': nome,
        'autoListagem': autoListagem,
        if (moduloSistemaId != null) 'moduloSistemaId': moduloSistemaId,
        if (relatorioSubmoduloId != null)
          'relatorioSubmoduloId': relatorioSubmoduloId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome,
        'autoListagem': autoListagem,
        'moduloSistemaId': moduloSistemaId,
        'relatorioSubmoduloId': relatorioSubmoduloId,
      };

  factory Programa.fromJson(Map<String, dynamic> json) {
    final moduloCodigoRaw = json['moduloCodigo'];
    int? moduloCodigo;
    if (moduloCodigoRaw is int) {
      moduloCodigo = moduloCodigoRaw;
    } else if (moduloCodigoRaw is num) {
      moduloCodigo = moduloCodigoRaw.toInt();
    } else if (moduloCodigoRaw is String) {
      moduloCodigo = int.tryParse(moduloCodigoRaw);
    }

    return Programa(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      autoListagem: json['autoListagem'] as bool? ?? false,
      moduloSistemaId: json['moduloSistemaId'] as String?,
      moduloCodigo: moduloCodigo,
      moduloNome: json['moduloNome'] as String?,
      relatorioSubmoduloId: json['relatorioSubmoduloId'] as String?,
      relatorioSubmoduloCodigo: json['relatorioSubmoduloCodigo'] as String?,
      relatorioSubmoduloNome: json['relatorioSubmoduloNome'] as String?,
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }
}
