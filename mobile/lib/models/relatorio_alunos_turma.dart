class RelatorioAlunosTurmaAluno {
  const RelatorioAlunosTurmaAluno({
    required this.inscricaoId,
    required this.alunoNome,
    this.alunoCpf,
    this.alunoCpfFormatado,
    this.alunoIdade,
    this.escolaridadeDescricao,
    required this.dataInscricao,
    this.dataMatricula,
    this.dataCancelamento,
    required this.situacao,
    required this.situacaoCodigo,
    required this.dataUltSituacao,
    required this.quantidadeAtendimentos,
  });

  final String inscricaoId;
  final String alunoNome;
  final String? alunoCpf;
  final String? alunoCpfFormatado;
  final int? alunoIdade;
  final String? escolaridadeDescricao;
  final String dataInscricao;
  final String? dataMatricula;
  final String? dataCancelamento;
  final String situacao;
  final String situacaoCodigo;
  final String dataUltSituacao;
  final int quantidadeAtendimentos;

  factory RelatorioAlunosTurmaAluno.fromJson(Map<String, dynamic> json) {
    int? parseIdade(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return RelatorioAlunosTurmaAluno(
      inscricaoId: json['inscricaoId'] as String,
      alunoNome: json['alunoNome'] as String,
      alunoCpf: json['alunoCpf'] as String?,
      alunoCpfFormatado: json['alunoCpfFormatado'] as String?,
      alunoIdade: parseIdade(json['alunoIdade']),
      escolaridadeDescricao: json['escolaridadeDescricao'] as String?,
      dataInscricao: json['dataInscricao'] as String,
      dataMatricula: json['dataMatricula'] as String?,
      dataCancelamento: json['dataCancelamento'] as String?,
      situacao: json['situacao'] as String,
      situacaoCodigo: json['situacaoCodigo'] as String,
      dataUltSituacao: json['dataUltSituacao'] as String,
      quantidadeAtendimentos: json['quantidadeAtendimentos'] as int? ?? 0,
    );
  }
}

class RelatorioAlunosTurmaResumoSecao {
  const RelatorioAlunosTurmaResumoSecao({
    required this.matriculados,
    required this.matriculasCanceladas,
    this.aMatricular,
  });

  final int matriculados;
  final int matriculasCanceladas;
  final int? aMatricular;

  factory RelatorioAlunosTurmaResumoSecao.fromJson(Map<String, dynamic> json) {
    return RelatorioAlunosTurmaResumoSecao(
      matriculados: json['matriculados'] as int? ?? 0,
      matriculasCanceladas: json['matriculasCanceladas'] as int? ?? 0,
      aMatricular: json['aMatricular'] as int?,
    );
  }
}

class RelatorioAlunosTurmaSecao {
  const RelatorioAlunosTurmaSecao({
    required this.cursoCodigo,
    required this.cursoDescricao,
    required this.turmaCodigo,
    required this.turmaNome,
    required this.periodo,
    this.periodoRotulo,
    required this.situacaoTurma,
    this.situacaoTurmaRotulo,
    required this.alunos,
    required this.resumo,
  });

  final int cursoCodigo;
  final String cursoDescricao;
  final int turmaCodigo;
  final String turmaNome;
  final String periodo;
  final String? periodoRotulo;
  final String situacaoTurma;
  final String? situacaoTurmaRotulo;
  final List<RelatorioAlunosTurmaAluno> alunos;
  final RelatorioAlunosTurmaResumoSecao resumo;

  factory RelatorioAlunosTurmaSecao.fromJson(Map<String, dynamic> json) {
    int parseCodigo(dynamic v) {
      if (v is int) return v;
      return int.parse(v.toString());
    }

    return RelatorioAlunosTurmaSecao(
      cursoCodigo: parseCodigo(json['cursoCodigo']),
      cursoDescricao: json['cursoDescricao'] as String,
      turmaCodigo: parseCodigo(json['turmaCodigo']),
      turmaNome: json['turmaNome'] as String,
      periodo: json['periodo'] as String,
      periodoRotulo: json['periodoRotulo'] as String?,
      situacaoTurma: json['situacaoTurma'] as String,
      situacaoTurmaRotulo: json['situacaoTurmaRotulo'] as String?,
      alunos: (json['alunos'] as List<dynamic>? ?? [])
          .map(
            (e) => RelatorioAlunosTurmaAluno.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      resumo: RelatorioAlunosTurmaResumoSecao.fromJson(
        json['resumo'] as Map<String, dynamic>,
      ),
    );
  }
}

class RelatorioAlunosTurmaResumoGeral {
  const RelatorioAlunosTurmaResumoGeral({
    required this.cursoCodigo,
    required this.cursoDescricao,
    required this.turmaCodigo,
    required this.turmaNome,
    this.periodoRotulo,
    required this.situacaoTurma,
    this.situacaoTurmaRotulo,
    required this.matriculados,
    required this.matriculasCanceladas,
    this.aMatricular,
  });

  final int cursoCodigo;
  final String cursoDescricao;
  final int turmaCodigo;
  final String turmaNome;
  final String? periodoRotulo;
  final String situacaoTurma;
  final String? situacaoTurmaRotulo;
  final int matriculados;
  final int matriculasCanceladas;
  final int? aMatricular;

  factory RelatorioAlunosTurmaResumoGeral.fromJson(Map<String, dynamic> json) {
    int parseCodigo(dynamic v) {
      if (v is int) return v;
      return int.parse(v.toString());
    }

    return RelatorioAlunosTurmaResumoGeral(
      cursoCodigo: parseCodigo(json['cursoCodigo']),
      cursoDescricao: json['cursoDescricao'] as String,
      turmaCodigo: parseCodigo(json['turmaCodigo']),
      turmaNome: json['turmaNome'] as String,
      periodoRotulo: json['periodoRotulo'] as String?,
      situacaoTurma: json['situacaoTurma'] as String,
      situacaoTurmaRotulo: json['situacaoTurmaRotulo'] as String?,
      matriculados: json['matriculados'] as int? ?? 0,
      matriculasCanceladas: json['matriculasCanceladas'] as int? ?? 0,
      aMatricular: json['aMatricular'] as int?,
    );
  }
}

class RelatorioAlunosTurmaResult {
  const RelatorioAlunosTurmaResult({
    required this.todosCursos,
    required this.todasTurmas,
    this.cursoCodigo,
    this.turmaCodigo,
    required this.situacao,
    required this.secoes,
    required this.resumoGeral,
  });

  final bool todosCursos;
  final bool todasTurmas;
  final int? cursoCodigo;
  final int? turmaCodigo;
  final String situacao;
  final List<RelatorioAlunosTurmaSecao> secoes;
  final List<RelatorioAlunosTurmaResumoGeral> resumoGeral;

  factory RelatorioAlunosTurmaResult.fromJson(Map<String, dynamic> json) {
    final filtros = json['filtros'] as Map<String, dynamic>;

    int? parseCodigoOpt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return RelatorioAlunosTurmaResult(
      todosCursos: filtros['todosCursos'] as bool? ?? false,
      todasTurmas: filtros['todasTurmas'] as bool? ?? false,
      cursoCodigo: parseCodigoOpt(filtros['cursoCodigo']),
      turmaCodigo: parseCodigoOpt(filtros['turmaCodigo']),
      situacao: filtros['situacao'] as String? ?? 'TODAS',
      secoes: (json['secoes'] as List<dynamic>? ?? [])
          .map(
            (e) => RelatorioAlunosTurmaSecao.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      resumoGeral: (json['resumoGeral'] as List<dynamic>? ?? [])
          .map(
            (e) => RelatorioAlunosTurmaResumoGeral.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
