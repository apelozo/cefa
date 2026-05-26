class TipoFormularioAcessoLinha {
  TipoFormularioAcessoLinha({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
    required this.liberado,
  });

  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  bool liberado;

  factory TipoFormularioAcessoLinha.fromJson(Map<String, dynamic> json) {
    return TipoFormularioAcessoLinha(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      liberado: json['liberado'] as bool? ?? false,
    );
  }

  TipoFormularioAcessoLinha copyWith({bool? liberado}) {
    return TipoFormularioAcessoLinha(
      id: id,
      nome: nome,
      descricao: descricao,
      ativo: ativo,
      liberado: liberado ?? this.liberado,
    );
  }
}

class TiposFormularioAcessoResumo {
  TiposFormularioAcessoResumo({
    required this.acessoTotal,
    required this.tipos,
    this.usaOverride,
  });

  final bool acessoTotal;
  final bool? usaOverride;
  final List<TipoFormularioAcessoLinha> tipos;

  factory TiposFormularioAcessoResumo.fromJson(Map<String, dynamic> json) {
    final list = json['tipos'] as List<dynamic>? ?? [];
    return TiposFormularioAcessoResumo(
      acessoTotal: json['acessoTotal'] as bool? ?? false,
      usaOverride: json['usaOverride'] as bool?,
      tipos: list
          .map(
            (e) => TipoFormularioAcessoLinha.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  List<String> idsLiberados() =>
      tipos.where((t) => t.liberado).map((t) => t.id).toList();
}
