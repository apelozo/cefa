import 'auditoria_campos.dart';

class InscricaoAtendimento {
  const InscricaoAtendimento({
    required this.id,
    required this.inscricaoId,
    required this.dataAtendimento,
    this.descricao,
    this.descricaoResumo,
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final String inscricaoId;
  final String dataAtendimento;
  final String? descricao;
  final String? descricaoResumo;
  final AuditoriaCampos auditoria;

  factory InscricaoAtendimento.fromJson(Map<String, dynamic> json) {
    return InscricaoAtendimento(
      id: json['id'] as String,
      inscricaoId: json['inscricaoId'] as String,
      dataAtendimento: json['dataAtendimento'] as String,
      descricao: json['descricao'] as String?,
      descricaoResumo: json['descricaoResumo'] as String?,
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }
}

class InscricaoAtendimentoListaItem {
  const InscricaoAtendimentoListaItem({
    required this.id,
    required this.inscricaoId,
    required this.dataAtendimento,
    required this.descricaoResumo,
  });

  final String id;
  final String inscricaoId;
  final String dataAtendimento;
  final String descricaoResumo;

  factory InscricaoAtendimentoListaItem.fromJson(Map<String, dynamic> json) {
    return InscricaoAtendimentoListaItem(
      id: json['id'] as String,
      inscricaoId: json['inscricaoId'] as String,
      dataAtendimento: json['dataAtendimento'] as String,
      descricaoResumo: json['descricaoResumo'] as String,
    );
  }
}

class InscricaoAtendimentosContexto {
  const InscricaoAtendimentosContexto({
    required this.inscricaoId,
    required this.inscricaoCodigo,
    required this.alunoId,
    required this.alunoNome,
    required this.turmaCodigo,
    required this.turmaNome,
    required this.cursoDescricao,
    required this.atendimentos,
    this.matriculado = false,
    this.matriculaCancelada = false,
  });

  final String inscricaoId;
  final int inscricaoCodigo;
  final String alunoId;
  final String alunoNome;
  final int turmaCodigo;
  final String turmaNome;
  final String cursoDescricao;
  final List<InscricaoAtendimentoListaItem> atendimentos;
  final bool matriculado;
  final bool matriculaCancelada;

  bool get podeIncluirAtendimento => matriculado && !matriculaCancelada;

  factory InscricaoAtendimentosContexto.fromJson(Map<String, dynamic> json) {
    final lista = json['atendimentos'] as List<dynamic>? ?? [];
    return InscricaoAtendimentosContexto(
      inscricaoId: json['inscricaoId'] as String,
      inscricaoCodigo: json['inscricaoCodigo'] as int,
      alunoId: json['alunoId'] as String,
      alunoNome: json['alunoNome'] as String,
      turmaCodigo: json['turmaCodigo'] as int,
      turmaNome: json['turmaNome'] as String,
      cursoDescricao: json['cursoDescricao'] as String,
      matriculado: json['matriculado'] as bool? ?? false,
      matriculaCancelada: json['matriculaCancelada'] as bool? ?? false,
      atendimentos: lista
          .map(
            (e) => InscricaoAtendimentoListaItem.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class AlunoMatriculadoResumo {
  const AlunoMatriculadoResumo({
    required this.inscricaoId,
    required this.inscricaoCodigo,
    required this.alunoId,
    required this.alunoNome,
    this.alunoCpf,
    this.alunoCpfFormatado,
    this.matriculado = false,
    this.matriculaCancelada = false,
  });

  final String inscricaoId;
  final int inscricaoCodigo;
  final String alunoId;
  final String alunoNome;
  final String? alunoCpf;
  final String? alunoCpfFormatado;
  final bool matriculado;
  final bool matriculaCancelada;

  factory AlunoMatriculadoResumo.fromJson(Map<String, dynamic> json) {
    return AlunoMatriculadoResumo(
      inscricaoId: json['inscricaoId'] as String,
      inscricaoCodigo: json['inscricaoCodigo'] as int,
      alunoId: json['alunoId'] as String,
      alunoNome: json['alunoNome'] as String,
      alunoCpf: json['alunoCpf'] as String?,
      alunoCpfFormatado: json['alunoCpfFormatado'] as String?,
      matriculado: json['matriculado'] as bool? ?? false,
      matriculaCancelada: json['matriculaCancelada'] as bool? ?? false,
    );
  }
}
