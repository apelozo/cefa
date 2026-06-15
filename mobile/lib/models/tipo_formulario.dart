import 'auditoria_campos.dart';

class TipoFormulario {
  const TipoFormulario({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
    required this.createdAt,
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime createdAt;
  final AuditoriaCampos auditoria;

  factory TipoFormulario.fromJson(Map<String, dynamic> json) {
    return TipoFormulario(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'nome': nome,
        if (descricao != null && descricao!.isNotEmpty) 'descricao': descricao,
        'ativo': ativo,
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome,
        'descricao': descricao,
        'ativo': ativo,
      };

  TipoFormulario copyWith({
    String? nome,
    String? descricao,
    bool clearDescricao = false,
    bool? ativo,
  }) {
    return TipoFormulario(
      id: id,
      nome: nome ?? this.nome,
      descricao: clearDescricao ? null : (descricao ?? this.descricao),
      ativo: ativo ?? this.ativo,
      createdAt: createdAt,
      auditoria: auditoria,
    );
  }
}
