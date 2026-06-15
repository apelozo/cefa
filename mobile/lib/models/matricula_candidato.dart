class MatriculaCandidato {
  const MatriculaCandidato({
    required this.id,
    required this.codigo,
    required this.alunoNome,
    this.alunoIdade,
    this.escolaridadeDescricao,
    this.orgaoEncaminhamento,
    this.possuiEncaminhamento = false,
    this.rendaPerCapita,
    this.rendaPerCapitaFormatada,
    this.matriculado = false,
  });

  final String id;
  final int codigo;
  final String alunoNome;
  final int? alunoIdade;
  final String? escolaridadeDescricao;
  final String? orgaoEncaminhamento;
  final bool possuiEncaminhamento;
  final double? rendaPerCapita;
  final String? rendaPerCapitaFormatada;
  final bool matriculado;

  factory MatriculaCandidato.fromJson(Map<String, dynamic> json) {
    double? parseDoubleOpt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return MatriculaCandidato(
      id: json['id'] as String,
      codigo: json['codigo'] is int
          ? json['codigo'] as int
          : int.parse(json['codigo'].toString()),
      alunoNome: json['alunoNome'] as String,
      alunoIdade: json['alunoIdade'] as int?,
      escolaridadeDescricao: json['escolaridadeDescricao'] as String?,
      orgaoEncaminhamento: json['orgaoEncaminhamento'] as String?,
      possuiEncaminhamento: json['possuiEncaminhamento'] as bool? ?? false,
      rendaPerCapita: parseDoubleOpt(json['rendaPerCapita']),
      rendaPerCapitaFormatada: json['rendaPerCapitaFormatada'] as String?,
      matriculado: json['matriculado'] as bool? ?? false,
    );
  }
}

class MatriculaCandidatosResult {
  const MatriculaCandidatosResult({
    required this.turmaCodigo,
    required this.turmaNome,
    required this.cursoCodigo,
    required this.cursoDescricao,
    required this.periodo,
    this.periodoRotulo,
    required this.totalMatriculados,
    required this.candidatos,
  });

  final int turmaCodigo;
  final String turmaNome;
  final int cursoCodigo;
  final String cursoDescricao;
  final String periodo;
  final String? periodoRotulo;
  final int totalMatriculados;
  final List<MatriculaCandidato> candidatos;

  factory MatriculaCandidatosResult.fromJson(Map<String, dynamic> json) {
    final candidatosRaw = json['candidatos'] as List<dynamic>? ?? [];
    return MatriculaCandidatosResult(
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
      candidatos: candidatosRaw
          .map(
            (e) => MatriculaCandidato.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
