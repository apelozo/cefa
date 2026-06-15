import 'auditoria_campos.dart';

class ModuloProgramaResumo {
  const ModuloProgramaResumo({
    required this.id,
    required this.codigo,
    required this.nome,
    this.autoListagem = false,
    this.relatorioSubmoduloId,
    this.relatorioSubmoduloCodigo,
    this.relatorioSubmoduloNome,
    this.relatorioSubmoduloOrdem,
  });

  final String id;
  final String codigo;
  final String nome;
  final bool autoListagem;
  final String? relatorioSubmoduloId;
  final String? relatorioSubmoduloCodigo;
  final String? relatorioSubmoduloNome;
  final int? relatorioSubmoduloOrdem;

  factory ModuloProgramaResumo.fromJson(Map<String, dynamic> json) {
    final ordemRaw = json['relatorioSubmoduloOrdem'];
    int? relatorioSubmoduloOrdem;
    if (ordemRaw is int) {
      relatorioSubmoduloOrdem = ordemRaw;
    } else if (ordemRaw is num) {
      relatorioSubmoduloOrdem = ordemRaw.toInt();
    }

    return ModuloProgramaResumo(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      autoListagem: json['autoListagem'] as bool? ?? false,
      relatorioSubmoduloId: json['relatorioSubmoduloId'] as String?,
      relatorioSubmoduloCodigo: json['relatorioSubmoduloCodigo'] as String?,
      relatorioSubmoduloNome: json['relatorioSubmoduloNome'] as String?,
      relatorioSubmoduloOrdem: relatorioSubmoduloOrdem,
    );
  }
}

class ModuloSistema {
  const ModuloSistema({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    required this.ordem,
    required this.ativo,
    required this.createdAt,
    this.programas = const [],
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final int codigo;
  final String nome;
  final String? descricao;
  final int ordem;
  final bool ativo;
  final DateTime createdAt;
  final List<ModuloProgramaResumo> programas;
  final AuditoriaCampos auditoria;

  factory ModuloSistema.fromJson(Map<String, dynamic> json) {
    final programasRaw = json['programas'] as List<dynamic>?;
    return ModuloSistema(
      id: json['id'] as String,
      codigo: _parseCodigo(json['codigo']),
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ordem: json['ordem'] as int? ?? 0,
      ativo: json['ativo'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      programas: programasRaw
              ?.map(
                (e) => ModuloProgramaResumo.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'nome': nome,
        if (descricao != null && descricao!.isNotEmpty) 'descricao': descricao,
        'ordem': ordem,
        'ativo': ativo,
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome,
        'descricao': descricao,
        'ordem': ordem,
        'ativo': ativo,
      };

  ModuloSistema copyWith({
    String? nome,
    String? descricao,
    int? ordem,
    bool? ativo,
    List<ModuloProgramaResumo>? programas,
  }) {
    return ModuloSistema(
      id: id,
      codigo: codigo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt,
      programas: programas ?? this.programas,
    );
  }
}

class ModuloMenuItem {
  const ModuloMenuItem({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    required this.ordem,
    required this.programas,
  });

  final String id;
  final int codigo;
  final String nome;
  final String? descricao;
  final int ordem;
  final List<ModuloProgramaResumo> programas;

  factory ModuloMenuItem.fromJson(Map<String, dynamic> json) {
    final programasRaw = json['programas'] as List<dynamic>;
    return ModuloMenuItem(
      id: json['id'] as String,
      codigo: _parseCodigo(json['codigo']),
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ordem: json['ordem'] as int? ?? 0,
      programas: programasRaw
          .map((e) => ModuloProgramaResumo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

int _parseCodigo(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Código de módulo inválido: $value');
}
