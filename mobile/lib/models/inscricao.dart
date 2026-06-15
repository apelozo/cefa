import 'auditoria_campos.dart';

import 'inscricao_renda_familiar.dart';



class Inscricao {

  const Inscricao({

    required this.id,

    required this.codigo,

    required this.alunoId,

    required this.alunoNome,

    this.alunoCpf,

    this.alunoCpfFormatado,

    required this.turmaCodigo,

    required this.turmaNome,

    required this.cursoCodigo,

    required this.cursoDescricao,

    required this.dtCurso,

    required this.periodo,

    this.periodoRotulo,

    this.jaFezCursoSenacSenai = false,

    this.cursoSenacSenaiDescricao,

    this.possuiEncaminhamento = false,

    this.orgaoEncaminhamento,

    this.telefoneEncaminhamento,

    this.telefoneEncaminhamentoFormatado,

    this.possuiNecessidadeEspecial = false,

    this.qualNecessidade,

    this.fazAcompanhamentoMedico = false,

    this.tomaMedicacao = false,

    this.quaisMedicacoes,

    this.vacinacao,

    this.alergias,

    this.rendaFamiliar = const [],

    this.rendaPerCapita,

    this.rendaPerCapitaFormatada,

    this.matriculado = false,

    this.matriculaCancelada = false,

    this.dtInicioCurso,

    this.usuarioMatriculaId,

    this.dataHoraMatricula,

    required this.ativo,

    this.auditoria = const AuditoriaCampos(),

    this.usuarioInclusaoId,

    this.dataHoraInclusao,

    this.usuarioAlteracaoId,

    this.dataHoraAlteracao,

  });



  final String id;

  final int codigo;

  final String alunoId;

  final String alunoNome;

  final String? alunoCpf;

  final String? alunoCpfFormatado;

  final int turmaCodigo;

  final String turmaNome;

  final int cursoCodigo;

  final String cursoDescricao;

  final String dtCurso;

  final String periodo;

  final String? periodoRotulo;

  final bool jaFezCursoSenacSenai;

  final String? cursoSenacSenaiDescricao;

  final bool possuiEncaminhamento;

  final String? orgaoEncaminhamento;

  final String? telefoneEncaminhamento;

  final String? telefoneEncaminhamentoFormatado;

  final bool possuiNecessidadeEspecial;

  final String? qualNecessidade;

  final bool fazAcompanhamentoMedico;

  final bool tomaMedicacao;

  final String? quaisMedicacoes;

  final String? vacinacao;

  final String? alergias;

  final List<InscricaoRendaFamiliar> rendaFamiliar;

  final double? rendaPerCapita;

  final String? rendaPerCapitaFormatada;

  final bool matriculado;

  final bool matriculaCancelada;

  final String? dtInicioCurso;

  final String? usuarioMatriculaId;

  final DateTime? dataHoraMatricula;

  final bool ativo;

  final AuditoriaCampos auditoria;

  final String? usuarioInclusaoId;

  final DateTime? dataHoraInclusao;

  final String? usuarioAlteracaoId;

  final DateTime? dataHoraAlteracao;



  factory Inscricao.fromJson(Map<String, dynamic> json) {

    DateTime? parseOpt(String? v) =>

        v == null || v.isEmpty ? null : DateTime.tryParse(v);



    int parseCodigo(dynamic v) {

      if (v is int) return v;

      return int.parse(v.toString());

    }



    double? parseDoubleOpt(dynamic v) {

      if (v == null) return null;

      if (v is num) return v.toDouble();

      return double.tryParse(v.toString());

    }



    final rendaRaw = json['rendaFamiliar'] as List<dynamic>? ?? [];



    return Inscricao(

      id: json['id'] as String,

      codigo: parseCodigo(json['codigo']),

      alunoId: json['alunoId'] as String,

      alunoNome: json['alunoNome'] as String,

      alunoCpf: json['alunoCpf'] as String?,

      alunoCpfFormatado: json['alunoCpfFormatado'] as String?,

      turmaCodigo: parseCodigo(json['turmaCodigo']),

      turmaNome: json['turmaNome'] as String,

      cursoCodigo: parseCodigo(json['cursoCodigo']),

      cursoDescricao: json['cursoDescricao'] as String,

      dtCurso: json['dtCurso'] as String,

      periodo: json['periodo'] as String,

      periodoRotulo: json['periodoRotulo'] as String?,

      jaFezCursoSenacSenai: json['jaFezCursoSenacSenai'] as bool? ?? false,

      cursoSenacSenaiDescricao: json['cursoSenacSenaiDescricao'] as String?,

      possuiEncaminhamento: json['possuiEncaminhamento'] as bool? ?? false,

      orgaoEncaminhamento: json['orgaoEncaminhamento'] as String?,

      telefoneEncaminhamento: json['telefoneEncaminhamento'] as String?,

      telefoneEncaminhamentoFormatado:

          json['telefoneEncaminhamentoFormatado'] as String?,

      possuiNecessidadeEspecial:

          json['possuiNecessidadeEspecial'] as bool? ?? false,

      qualNecessidade: json['qualNecessidade'] as String?,

      fazAcompanhamentoMedico:

          json['fazAcompanhamentoMedico'] as bool? ?? false,

      tomaMedicacao: json['tomaMedicacao'] as bool? ?? false,

      quaisMedicacoes: json['quaisMedicacoes'] as String?,

      vacinacao: json['vacinacao'] as String?,

      alergias: json['alergias'] as String?,

      rendaFamiliar: rendaRaw

          .map(

            (e) => InscricaoRendaFamiliar.fromJson(e as Map<String, dynamic>),

          )

          .toList(),

      rendaPerCapita: parseDoubleOpt(json['rendaPerCapita']),

      rendaPerCapitaFormatada: json['rendaPerCapitaFormatada'] as String?,

      matriculado: json['matriculado'] as bool? ?? false,

      matriculaCancelada: json['matriculaCancelada'] as bool? ?? false,

      dtInicioCurso: json['dtInicioCurso'] as String?,

      usuarioMatriculaId: json['usuarioMatriculaId'] as String?,

      dataHoraMatricula: parseOpt(json['dataHoraMatricula'] as String?),

      ativo: json['ativo'] as bool? ?? true,

      auditoria: AuditoriaCampos.fromJson(json),

      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,

      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),

      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,

      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),

    );

  }



  Map<String, dynamic> toSaveJson() => {

        'alunoId': alunoId,

        'turmaCodigo': turmaCodigo,

        'dtCurso': dtCurso,

        'jaFezCursoSenacSenai': jaFezCursoSenacSenai,

        if (jaFezCursoSenacSenai &&

            cursoSenacSenaiDescricao != null &&

            cursoSenacSenaiDescricao!.trim().isNotEmpty)

          'cursoSenacSenaiDescricao': cursoSenacSenaiDescricao!.trim(),

        'possuiEncaminhamento': possuiEncaminhamento,

        if (possuiEncaminhamento &&

            orgaoEncaminhamento != null &&

            orgaoEncaminhamento!.trim().isNotEmpty)

          'orgaoEncaminhamento': orgaoEncaminhamento!.trim(),

        if (possuiEncaminhamento &&

            telefoneEncaminhamento != null &&

            telefoneEncaminhamento!.isNotEmpty)

          'telefoneEncaminhamento': telefoneEncaminhamento,

        'possuiNecessidadeEspecial': possuiNecessidadeEspecial,

        if (possuiNecessidadeEspecial &&

            qualNecessidade != null &&

            qualNecessidade!.trim().isNotEmpty)

          'qualNecessidade': qualNecessidade!.trim(),

        'fazAcompanhamentoMedico': fazAcompanhamentoMedico,

        'tomaMedicacao': tomaMedicacao,

        if (tomaMedicacao &&

            quaisMedicacoes != null &&

            quaisMedicacoes!.trim().isNotEmpty)

          'quaisMedicacoes': quaisMedicacoes!.trim(),

        if (vacinacao != null && vacinacao!.trim().isNotEmpty)

          'vacinacao': vacinacao!.trim(),

        if (alergias != null && alergias!.trim().isNotEmpty)

          'alergias': alergias!.trim(),

        'rendaFamiliar':

            rendaFamiliar.map((e) => e.toSaveJson()).toList(growable: false),

      };

}

