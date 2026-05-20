import 'pergunta_opcao.dart';
import 'tipo_campo.dart';

class Pergunta {
  const Pergunta({
    required this.id,
    required this.enunciado,
    required this.tipoCampo,
    this.tamanhoCampo,
    this.linhasCampo,
    required this.tipoFormularioId,
    this.tipoFormularioNome,
    required this.ordem,
    required this.ativo,
    required this.createdAt,
    this.opcoes = const [],
  });

  final String id;
  final String enunciado;
  final TipoCampo tipoCampo;
  final int? tamanhoCampo;
  final int? linhasCampo;
  final String tipoFormularioId;
  final String? tipoFormularioNome;
  final int ordem;
  final bool ativo;
  final DateTime createdAt;
  final List<PerguntaOpcao> opcoes;

  List<PerguntaOpcao> get opcoesAtivas =>
      opcoes.where((o) => o.ativo).toList(growable: false);

  factory Pergunta.fromJson(Map<String, dynamic> json) {
    final tipoForm = json['tipoFormulario'] as Map<String, dynamic>?;
    final opcoesJson = json['opcoes'] as List<dynamic>?;
    return Pergunta(
      id: json['id'] as String,
      enunciado: json['enunciado'] as String,
      tipoCampo: TipoCampo.fromString(json['tipoCampo'] as String),
      tamanhoCampo: json['tamanhoCampo'] as int?,
      linhasCampo: json['linhasCampo'] as int?,
      tipoFormularioId: json['tipoFormularioId'] as String,
      tipoFormularioNome: tipoForm?['nome'] as String?,
      ordem: json['ordem'] as int,
      ativo: json['ativo'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      opcoes: opcoesJson != null
          ? opcoesJson
              .map((e) => PerguntaOpcao.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toCreateJson() {
    final map = <String, dynamic>{
      'enunciado': enunciado,
      'tipoCampo': tipoCampo.value,
      'tipoFormularioId': tipoFormularioId,
      'ordem': ordem,
      'ativo': ativo,
    };
    if (tipoCampo == TipoCampo.texto) {
      if (tamanhoCampo != null) map['tamanhoCampo'] = tamanhoCampo;
      if (linhasCampo != null) map['linhasCampo'] = linhasCampo;
    }
    if (tipoCampo == TipoCampo.lista) {
      map['opcoes'] = opcoes.map((o) => o.toJson()).toList();
    }
    return map;
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{
      'enunciado': enunciado,
      'tipoCampo': tipoCampo.value,
      'tipoFormularioId': tipoFormularioId,
      'ordem': ordem,
      'ativo': ativo,
    };
    if (tipoCampo == TipoCampo.texto) {
      map['tamanhoCampo'] = tamanhoCampo;
      map['linhasCampo'] = linhasCampo;
    } else {
      map['tamanhoCampo'] = null;
      map['linhasCampo'] = null;
    }
    if (tipoCampo == TipoCampo.lista) {
      map['opcoes'] = opcoes.map((o) => o.toJson()).toList();
    }
    return map;
  }

  Pergunta copyWith({
    String? enunciado,
    TipoCampo? tipoCampo,
    int? tamanhoCampo,
    bool clearTamanho = false,
    int? linhasCampo,
    bool clearLinhas = false,
    String? tipoFormularioId,
    String? tipoFormularioNome,
    int? ordem,
    bool? ativo,
    List<PerguntaOpcao>? opcoes,
  }) {
    return Pergunta(
      id: id,
      enunciado: enunciado ?? this.enunciado,
      tipoCampo: tipoCampo ?? this.tipoCampo,
      tamanhoCampo: clearTamanho ? null : (tamanhoCampo ?? this.tamanhoCampo),
      linhasCampo: clearLinhas ? null : (linhasCampo ?? this.linhasCampo),
      tipoFormularioId: tipoFormularioId ?? this.tipoFormularioId,
      tipoFormularioNome: tipoFormularioNome ?? this.tipoFormularioNome,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt,
      opcoes: opcoes ?? this.opcoes,
    );
  }
}
