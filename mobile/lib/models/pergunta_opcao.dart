class PerguntaOpcao {
  const PerguntaOpcao({
    this.id,
    required this.rotulo,
    required this.ordem,
    required this.ativo,
  });

  final String? id;
  final String rotulo;
  final int ordem;
  final bool ativo;

  factory PerguntaOpcao.fromJson(Map<String, dynamic> json) {
    return PerguntaOpcao(
      id: json['id'] as String?,
      rotulo: json['rotulo'] as String,
      ordem: json['ordem'] as int? ?? 0,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'rotulo': rotulo,
      'ordem': ordem,
      'ativo': ativo,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  PerguntaOpcao copyWith({
    String? id,
    String? rotulo,
    int? ordem,
    bool? ativo,
  }) {
    return PerguntaOpcao(
      id: id ?? this.id,
      rotulo: rotulo ?? this.rotulo,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
    );
  }
}
