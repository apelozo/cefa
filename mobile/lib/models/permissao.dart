class ProgramaPermissao {
  const ProgramaPermissao({
    required this.podeIncluir,
    required this.podeAlterar,
    required this.podeConsultar,
    required this.podeExcluir,
  });

  final bool podeIncluir;
  final bool podeAlterar;
  final bool podeConsultar;
  final bool podeExcluir;

  factory ProgramaPermissao.fromJson(Map<String, dynamic> json) {
    return ProgramaPermissao(
      podeIncluir: json['podeIncluir'] as bool? ?? false,
      podeAlterar: json['podeAlterar'] as bool? ?? false,
      podeConsultar: json['podeConsultar'] as bool? ?? false,
      podeExcluir: json['podeExcluir'] as bool? ?? false,
    );
  }

  static const nenhuma = ProgramaPermissao(
    podeIncluir: false,
    podeAlterar: false,
    podeConsultar: false,
    podeExcluir: false,
  );

  /// Qualquer flag liberada — suficiente para ver o programa no menu e abrir a listagem.
  bool get temAcesso =>
      podeIncluir || podeAlterar || podeConsultar || podeExcluir;
}

class PermissaoLinha {
  const PermissaoLinha({
    required this.programaId,
    required this.programaCodigo,
    required this.programaNome,
    required this.podeIncluir,
    required this.podeAlterar,
    required this.podeConsultar,
    required this.podeExcluir,
    this.perfilAdmin = false,
  });

  final String programaId;
  final String programaCodigo;
  final String programaNome;
  final bool podeIncluir;
  final bool podeAlterar;
  final bool podeConsultar;
  final bool podeExcluir;
  final bool perfilAdmin;

  factory PermissaoLinha.fromJson(Map<String, dynamic> json) {
    return PermissaoLinha(
      programaId: json['programaId'] as String,
      programaCodigo: json['programaCodigo'] as String,
      programaNome: json['programaNome'] as String,
      podeIncluir: json['podeIncluir'] as bool? ?? false,
      podeAlterar: json['podeAlterar'] as bool? ?? false,
      podeConsultar: json['podeConsultar'] as bool? ?? false,
      podeExcluir: json['podeExcluir'] as bool? ?? false,
      perfilAdmin: json['perfilAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'programaId': programaId,
        'podeIncluir': podeIncluir,
        'podeAlterar': podeAlterar,
        'podeConsultar': podeConsultar,
        'podeExcluir': podeExcluir,
      };

  PermissaoLinha copyWith({
    bool? podeIncluir,
    bool? podeAlterar,
    bool? podeConsultar,
    bool? podeExcluir,
  }) {
    return PermissaoLinha(
      programaId: programaId,
      programaCodigo: programaCodigo,
      programaNome: programaNome,
      podeIncluir: podeIncluir ?? this.podeIncluir,
      podeAlterar: podeAlterar ?? this.podeAlterar,
      podeConsultar: podeConsultar ?? this.podeConsultar,
      podeExcluir: podeExcluir ?? this.podeExcluir,
      perfilAdmin: perfilAdmin,
    );
  }
}
