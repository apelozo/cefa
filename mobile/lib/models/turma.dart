import 'auditoria_campos.dart';

class Turma {
  const Turma({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.cursoCodigo,
    required this.cursoDescricao,
    required this.periodo,
    this.periodoRotulo,
    required this.situacao,
    this.situacaoRotulo,
    required this.ativo,
    this.auditoria = const AuditoriaCampos(),
    this.usuarioInclusaoId,
    this.dataHoraInclusao,
    this.usuarioAlteracaoId,
    this.dataHoraAlteracao,
  });

  final String id;
  final int codigo;
  final String nome;
  final int cursoCodigo;
  final String cursoDescricao;
  final String periodo;
  final String? periodoRotulo;
  final String situacao;
  final String? situacaoRotulo;
  final bool ativo;
  final AuditoriaCampos auditoria;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;

  factory Turma.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    int parseCodigo(dynamic v) {
      if (v is int) return v;
      return int.parse(v.toString());
    }

    return Turma(
      id: json['id'] as String,
      codigo: parseCodigo(json['codigo']),
      nome: json['nome'] as String,
      cursoCodigo: parseCodigo(json['cursoCodigo']),
      cursoDescricao: json['cursoDescricao'] as String,
      periodo: json['periodo'] as String,
      periodoRotulo: json['periodoRotulo'] as String?,
      situacao: json['situacao'] as String,
      situacaoRotulo: json['situacaoRotulo'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      auditoria: AuditoriaCampos.fromJson(json),
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'nome': nome,
        'cursoCodigo': cursoCodigo,
        'periodo': periodo,
        'situacao': situacao,
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome,
        'cursoCodigo': cursoCodigo,
        'periodo': periodo,
        'situacao': situacao,
      };

  String get rotuloExibicao =>
      '$codigo — $nome ($cursoDescricao, ${periodoRotulo ?? periodo})';
}
