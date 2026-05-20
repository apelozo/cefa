import 'tipo_campo.dart';

class RespostaItem {
  const RespostaItem({
    required this.perguntaId,
    this.valorInteiro,
    this.valorDecimal,
    this.valorTexto,
    this.valorLogico,
    this.valorData,
    this.valorOpcaoId,
  });

  final String perguntaId;
  final int? valorInteiro;
  final String? valorDecimal;
  final String? valorTexto;
  final bool? valorLogico;
  final String? valorData;
  final String? valorOpcaoId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'perguntaId': perguntaId};
    if (valorInteiro != null) map['valorInteiro'] = valorInteiro;
    if (valorDecimal != null) map['valorDecimal'] = valorDecimal;
    if (valorTexto != null) map['valorTexto'] = valorTexto;
    if (valorLogico != null) map['valorLogico'] = valorLogico;
    if (valorData != null) map['valorData'] = valorData;
    if (valorOpcaoId != null) map['valorOpcaoId'] = valorOpcaoId;
    return map;
  }
}

class SubmissaoResumo {
  const SubmissaoResumo({
    required this.id,
    required this.createdAt,
    required this.tipoFormularioId,
    required this.tipoFormularioNome,
    required this.pessoaId,
    required this.pessoaNome,
    required this.pessoaCpfFormatado,
    required this.totalRespostas,
  });

  final String id;
  final DateTime createdAt;
  final String tipoFormularioId;
  final String tipoFormularioNome;
  final String pessoaId;
  final String pessoaNome;
  final String pessoaCpfFormatado;
  final int totalRespostas;

  factory SubmissaoResumo.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipoFormulario'] as Map<String, dynamic>?;
    final pessoa = json['pessoa'] as Map<String, dynamic>?;
    return SubmissaoResumo(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tipoFormularioId: json['tipoFormularioId'] as String,
      tipoFormularioNome: tipo?['nome'] as String? ?? '',
      pessoaId: json['pessoaId'] as String,
      pessoaNome: pessoa?['nome'] as String? ?? '',
      pessoaCpfFormatado:
          pessoa?['cpfFormatado'] as String? ?? pessoa?['cpf'] as String? ?? '',
      totalRespostas: json['totalRespostas'] as int? ?? 0,
    );
  }
}

class Submissao {
  const Submissao({
    required this.id,
    required this.createdAt,
    required this.tipoFormularioId,
    required this.tipoFormularioNome,
    required this.pessoaId,
    required this.pessoaNome,
    required this.pessoaCpfFormatado,
    required this.respostas,
  });

  final String id;
  final DateTime createdAt;
  final String tipoFormularioId;
  final String tipoFormularioNome;
  final String pessoaId;
  final String pessoaNome;
  final String pessoaCpfFormatado;
  final List<RespostaSubmissao> respostas;

  factory Submissao.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipoFormulario'] as Map<String, dynamic>?;
    final pessoa = json['pessoa'] as Map<String, dynamic>?;
    return Submissao(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tipoFormularioId: json['tipoFormularioId'] as String,
      tipoFormularioNome: tipo?['nome'] as String? ?? '',
      pessoaId: json['pessoaId'] as String,
      pessoaNome: pessoa?['nome'] as String? ?? '',
      pessoaCpfFormatado:
          pessoa?['cpfFormatado'] as String? ?? pessoa?['cpf'] as String? ?? '',
      respostas: (json['respostas'] as List<dynamic>)
          .map((e) => RespostaSubmissao.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RespostaSubmissao {
  const RespostaSubmissao({
    required this.id,
    required this.perguntaId,
    this.valorInteiro,
    this.valorDecimal,
    this.valorTexto,
    this.valorLogico,
    this.valorData,
    this.valorOpcaoId,
    this.opcaoRotulo,
    this.opcaoAtiva,
    required this.perguntaEnunciado,
    required this.tipoCampo,
    required this.perguntaOrdem,
  });

  final String id;
  final String perguntaId;
  final int? valorInteiro;
  final String? valorDecimal;
  final String? valorTexto;
  final bool? valorLogico;
  final String? valorData;
  final String? valorOpcaoId;
  final String? opcaoRotulo;
  final bool? opcaoAtiva;
  final String perguntaEnunciado;
  final TipoCampo tipoCampo;
  final int perguntaOrdem;

  factory RespostaSubmissao.fromJson(Map<String, dynamic> json) {
    final pergunta = json['pergunta'] as Map<String, dynamic>;
    final opcao = json['opcao'] as Map<String, dynamic>?;
    return RespostaSubmissao(
      id: json['id'] as String,
      perguntaId: json['perguntaId'] as String,
      valorInteiro: json['valorInteiro'] as int?,
      valorDecimal: json['valorDecimal'] as String?,
      valorTexto: json['valorTexto'] as String?,
      valorLogico: json['valorLogico'] as bool?,
      valorData: json['valorData'] as String?,
      valorOpcaoId: json['valorOpcaoId'] as String?,
      opcaoRotulo: opcao?['rotulo'] as String?,
      opcaoAtiva: opcao?['ativo'] as bool?,
      perguntaEnunciado: pergunta['enunciado'] as String,
      tipoCampo: TipoCampo.fromString(pergunta['tipoCampo'] as String),
      perguntaOrdem: pergunta['ordem'] as int? ?? 0,
    );
  }
}
