import 'auditoria_campos.dart';

class RelatorioSubmodulo {
  const RelatorioSubmodulo({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    required this.ordem,
    required this.ativo,
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final String codigo;
  final String nome;
  final String? descricao;
  final int ordem;
  final bool ativo;
  final AuditoriaCampos auditoria;

  factory RelatorioSubmodulo.fromJson(Map<String, dynamic> json) {
    return RelatorioSubmodulo(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ordem: json['ordem'] as int? ?? 0,
      ativo: json['ativo'] as bool? ?? true,
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'codigo': codigo.trim().toLowerCase(),
        'nome': nome.trim(),
        if (descricao != null && descricao!.trim().isNotEmpty)
          'descricao': descricao!.trim(),
        'ordem': ordem,
        'ativo': ativo,
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome.trim(),
        'descricao': descricao?.trim().isEmpty ?? true ? null : descricao!.trim(),
        'ordem': ordem,
        'ativo': ativo,
      };

  RelatorioSubmodulo copyWith({
    String? nome,
    String? descricao,
    int? ordem,
    bool? ativo,
  }) {
    return RelatorioSubmodulo(
      id: id,
      codigo: codigo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      auditoria: auditoria,
    );
  }
}
