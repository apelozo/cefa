import 'auditoria_campos.dart';
import 'entrevista_composicao_familiar.dart';
import 'entrevista_condicao_educacional.dart';
import 'entrevista_condicao_trabalho.dart';
import 'entrevista_deficiencia_familiar.dart';
import 'entrevista_gestante_familiar.dart';
import 'entrevista_programas_sociais.dart';
import 'entrevista_saude_familia.dart';
import 'pessoa.dart';

class EntrevistaAssistidoResumo {
  const EntrevistaAssistidoResumo({
    required this.id,
    required this.pessoaId,
    required this.dataEntrevista,
    required this.pessoaNome,
    required this.pessoaCpfFormatado,
    required this.totalFormasAcesso,
    required this.totalComposicaoFamiliar,
    required this.totalCondicoesTrabalho,
    required this.totalCondicoesEducacionais,
    required this.totalDeficienciasFamilia,
    required this.totalGestantesFamilia,
    required this.createdAt,
  });

  final String id;
  final String pessoaId;
  final String dataEntrevista;
  final String pessoaNome;
  final String pessoaCpfFormatado;
  final int totalFormasAcesso;
  final int totalComposicaoFamiliar;
  final int totalCondicoesTrabalho;
  final int totalCondicoesEducacionais;
  final int totalDeficienciasFamilia;
  final int totalGestantesFamilia;
  final DateTime createdAt;

  factory EntrevistaAssistidoResumo.fromJson(Map<String, dynamic> json) {
    final pessoa = json['pessoa'] as Map<String, dynamic>?;
    return EntrevistaAssistidoResumo(
      id: json['id'] as String,
      pessoaId: json['pessoaId'] as String,
      dataEntrevista: json['dataEntrevista'] as String,
      pessoaNome: pessoa?['nome'] as String? ?? '',
      pessoaCpfFormatado: pessoa?['cpfFormatado'] as String? ?? '',
      totalFormasAcesso: json['totalFormasAcesso'] as int? ?? 0,
      totalComposicaoFamiliar: json['totalComposicaoFamiliar'] as int? ?? 0,
      totalCondicoesTrabalho: json['totalCondicoesTrabalho'] as int? ?? 0,
      totalCondicoesEducacionais:
          json['totalCondicoesEducacionais'] as int? ?? 0,
      totalDeficienciasFamilia: json['totalDeficienciasFamilia'] as int? ?? 0,
      totalGestantesFamilia: json['totalGestantesFamilia'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class EntrevistaAssistido {
  EntrevistaAssistido({
    required this.id,
    required this.pessoaId,
    required this.dataEntrevista,
    this.outrosTexto,
    required this.pessoaNome,
    required this.pessoaCpf,
    this.pessoaCpfFormatado,
    required this.formasAcesso,
    required this.composicaoFamiliar,
    required this.condicoesTrabalho,
    required this.condicoesEducacionais,
    required this.deficienciasFamilia,
    required this.gestantesFamilia,
    required this.programasSociais,
    required this.saudeFamilia,
    this.pessoaCompleta,
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final AuditoriaCampos auditoria;
  final String pessoaId;
  final String dataEntrevista;
  final String? outrosTexto;
  final String pessoaNome;
  final String pessoaCpf;
  final String? pessoaCpfFormatado;
  final List<EntrevistaFormaAcessoItem> formasAcesso;
  final List<EntrevistaComposicaoFamiliar> composicaoFamiliar;
  final List<EntrevistaCondicaoTrabalho> condicoesTrabalho;
  final List<EntrevistaCondicaoEducacional> condicoesEducacionais;
  final List<EntrevistaDeficienciaFamiliar> deficienciasFamilia;
  final List<EntrevistaGestanteFamiliar> gestantesFamilia;
  final EntrevistaProgramasSociais programasSociais;
  final EntrevistaSaudeFamilia saudeFamilia;
  final Pessoa? pessoaCompleta;

  factory EntrevistaAssistido.fromJson(Map<String, dynamic> json) {
    final pessoa = json['pessoa'] as Map<String, dynamic>?;
    Pessoa? pessoaCompleta;
    if (pessoa != null && pessoa['dtNascimento'] != null) {
      pessoaCompleta = Pessoa.fromJson(pessoa);
    }
    return EntrevistaAssistido(
      id: json['id'] as String,
      pessoaId: json['pessoaId'] as String,
      dataEntrevista: json['dataEntrevista'] as String,
      outrosTexto: json['outrosTexto'] as String?,
      pessoaNome: pessoa?['nome'] as String? ?? '',
      pessoaCpf: pessoa?['cpf'] as String? ?? '',
      pessoaCpfFormatado: pessoa?['cpfFormatado'] as String?,
      formasAcesso: (json['formasAcesso'] as List<dynamic>)
          .map(
            (e) => EntrevistaFormaAcessoItem.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      composicaoFamiliar: (json['composicaoFamiliar'] as List<dynamic>? ?? [])
          .map(
            (e) => EntrevistaComposicaoFamiliar.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      condicoesTrabalho: (json['condicoesTrabalho'] as List<dynamic>? ?? [])
          .map(
            (e) => EntrevistaCondicaoTrabalho.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      condicoesEducacionais:
          (json['condicoesEducacionais'] as List<dynamic>? ?? [])
              .map(
                (e) => EntrevistaCondicaoEducacional.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      deficienciasFamilia:
          (json['deficienciasFamilia'] as List<dynamic>? ?? [])
              .map(
                (e) => EntrevistaDeficienciaFamiliar.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      gestantesFamilia: (json['gestantesFamilia'] as List<dynamic>? ?? [])
          .map(
            (e) => EntrevistaGestanteFamiliar.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      programasSociais: EntrevistaProgramasSociais.fromJson(
        json['programasSociais'] as Map<String, dynamic>?,
      ),
      saudeFamilia: EntrevistaSaudeFamilia.fromJson(
        json['saudeFamilia'] as Map<String, dynamic>?,
      ),
      pessoaCompleta: pessoaCompleta,
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }

  /// Mescla dados para geração do PDF (ex.: programas sociais da tela atual).
  EntrevistaAssistido copyWith({
    EntrevistaProgramasSociais? programasSociais,
    EntrevistaSaudeFamilia? saudeFamilia,
    List<EntrevistaGestanteFamiliar>? gestantesFamilia,
  }) {
    return EntrevistaAssistido(
      id: id,
      pessoaId: pessoaId,
      dataEntrevista: dataEntrevista,
      outrosTexto: outrosTexto,
      pessoaNome: pessoaNome,
      pessoaCpf: pessoaCpf,
      pessoaCpfFormatado: pessoaCpfFormatado,
      formasAcesso: formasAcesso,
      composicaoFamiliar: composicaoFamiliar,
      condicoesTrabalho: condicoesTrabalho,
      condicoesEducacionais: condicoesEducacionais,
      deficienciasFamilia: deficienciasFamilia,
      gestantesFamilia: gestantesFamilia ?? this.gestantesFamilia,
      programasSociais: programasSociais ?? this.programasSociais,
      saudeFamilia: saudeFamilia ?? this.saudeFamilia,
      pessoaCompleta: pessoaCompleta,
      auditoria: auditoria,
    );
  }
}

class EntrevistaFormaAcessoItem {
  EntrevistaFormaAcessoItem({
    required this.id,
    required this.formaAcesso,
    required this.rotulo,
  });

  final String id;
  final String formaAcesso;
  final String rotulo;

  factory EntrevistaFormaAcessoItem.fromJson(Map<String, dynamic> json) {
    return EntrevistaFormaAcessoItem(
      id: json['id'] as String,
      formaAcesso: json['formaAcesso'] as String,
      rotulo: json['rotulo'] as String,
    );
  }
}
