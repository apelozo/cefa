class CancelamentoMatriculaAluno {
  const CancelamentoMatriculaAluno({
    required this.id,
    required this.codigo,
    required this.alunoNome,
    this.alunoCpf,
    this.alunoCpfFormatado,
    this.dataMatricula,
    this.alunoIdade,
    this.escolaridadeDescricao,
    this.orgaoEncaminhamento,
    this.matriculado = true,
    this.matriculaCancelada = false,
  });

  final String id;
  final int codigo;
  final String alunoNome;
  final String? alunoCpf;
  final String? alunoCpfFormatado;
  final String? dataMatricula;
  final int? alunoIdade;
  final String? escolaridadeDescricao;
  final String? orgaoEncaminhamento;
  final bool matriculado;
  final bool matriculaCancelada;

  factory CancelamentoMatriculaAluno.fromJson(Map<String, dynamic> json) {
    return CancelamentoMatriculaAluno(
      id: json['id'] as String,
      codigo: json['codigo'] is int
          ? json['codigo'] as int
          : int.parse(json['codigo'].toString()),
      alunoNome: json['alunoNome'] as String,
      alunoCpf: json['alunoCpf'] as String?,
      alunoCpfFormatado: json['alunoCpfFormatado'] as String?,
      dataMatricula: json['dataMatricula'] as String?,
      alunoIdade: json['alunoIdade'] as int?,
      escolaridadeDescricao: json['escolaridadeDescricao'] as String?,
      orgaoEncaminhamento: json['orgaoEncaminhamento'] as String?,
      matriculado: json['matriculado'] as bool? ?? true,
      matriculaCancelada: json['matriculaCancelada'] as bool? ?? false,
    );
  }
}

class CancelamentoMatriculaResult {
  const CancelamentoMatriculaResult({
    required this.turmaCodigo,
    required this.turmaNome,
    required this.cursoCodigo,
    required this.cursoDescricao,
    required this.periodo,
    this.periodoRotulo,
    required this.totalMatriculados,
    required this.matriculados,
  });

  final int turmaCodigo;
  final String turmaNome;
  final int cursoCodigo;
  final String cursoDescricao;
  final String periodo;
  final String? periodoRotulo;
  final int totalMatriculados;
  final List<CancelamentoMatriculaAluno> matriculados;

  factory CancelamentoMatriculaResult.fromJson(Map<String, dynamic> json) {
    final matriculadosRaw = json['matriculados'] as List<dynamic>? ?? [];
    return CancelamentoMatriculaResult(
      turmaCodigo: json['turmaCodigo'] is int
          ? json['turmaCodigo'] as int
          : int.parse(json['turmaCodigo'].toString()),
      turmaNome: json['turmaNome'] as String,
      cursoCodigo: json['cursoCodigo'] is int
          ? json['cursoCodigo'] as int
          : int.parse(json['cursoCodigo'].toString()),
      cursoDescricao: json['cursoDescricao'] as String,
      periodo: json['periodo'] as String,
      periodoRotulo: json['periodoRotulo'] as String?,
      totalMatriculados: json['totalMatriculados'] as int? ?? 0,
      matriculados: matriculadosRaw
          .map(
            (e) => CancelamentoMatriculaAluno.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
