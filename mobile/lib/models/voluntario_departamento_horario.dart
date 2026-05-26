class VoluntarioDepartamentoHorario {
  const VoluntarioDepartamentoHorario({
    required this.id,
    required this.voluntarioId,
    required this.departamentoCodigo,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaTermino,
    this.voluntarioCodigo,
    this.voluntarioNomeCracha,
    this.departamentoDescricao,
    this.diaSemanaRotulo,
    this.usuarioInclusaoId,
    this.dataHoraInclusao,
    this.usuarioAlteracaoId,
    this.dataHoraAlteracao,
    this.createdAt,
  });

  final String id;
  final String voluntarioId;
  final int departamentoCodigo;
  final String diaSemana;
  final String horaInicio;
  final String horaTermino;
  final int? voluntarioCodigo;
  final String? voluntarioNomeCracha;
  final String? departamentoDescricao;
  final String? diaSemanaRotulo;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final DateTime? createdAt;

  factory VoluntarioDepartamentoHorario.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    int parseCodigo(dynamic v) =>
        v is int ? v : int.parse(v.toString());

    return VoluntarioDepartamentoHorario(
      id: json['id'] as String,
      voluntarioId: json['voluntarioId'] as String,
      departamentoCodigo: parseCodigo(json['departamentoCodigo']),
      diaSemana: json['diaSemana'] as String,
      horaInicio: json['horaInicio'] as String,
      horaTermino: json['horaTermino'] as String,
      voluntarioCodigo: json['voluntarioCodigo'] == null
          ? null
          : parseCodigo(json['voluntarioCodigo']),
      voluntarioNomeCracha: json['voluntarioNomeCracha'] as String?,
      departamentoDescricao: json['departamentoDescricao'] as String?,
      diaSemanaRotulo: json['diaSemanaRotulo'] as String?,
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),
      createdAt: parseOpt(json['createdAt'] as String?),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'departamentoCodigo': departamentoCodigo,
        'diaSemana': diaSemana,
        'horaInicio': horaInicio,
        'horaTermino': horaTermino,
      };

  Map<String, dynamic> toUpdateJson() => {
        'departamentoCodigo': departamentoCodigo,
        'diaSemana': diaSemana,
        'horaInicio': horaInicio,
        'horaTermino': horaTermino,
      };
}
