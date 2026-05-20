import '../constants/ocupacao_familiar.dart';

class EntrevistaCondicaoTrabalho {
  const EntrevistaCondicaoTrabalho({
    this.id,
    required this.nome,
    required this.ocupacao,
    this.condicoesTrabalho,
    this.vrBeneficioSocial = '0',
    this.rendaMensal = '0',
    this.ordem = 0,
  });

  final String? id;
  final String nome;
  final String ocupacao;
  final String? condicoesTrabalho;
  final String vrBeneficioSocial;
  final String rendaMensal;
  final int ordem;

  factory EntrevistaCondicaoTrabalho.fromJson(Map<String, dynamic> json) {
    return EntrevistaCondicaoTrabalho(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      ocupacao: json['ocupacao'] as String,
      condicoesTrabalho: json['condicoesTrabalho'] as String?,
      vrBeneficioSocial: json['vrBeneficioSocial']?.toString() ?? '0',
      rendaMensal: json['rendaMensal']?.toString() ?? '0',
      ordem: json['ordem'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'ocupacao': ocupacao,
        if (condicoesTrabalho != null && condicoesTrabalho!.trim().isNotEmpty)
          'condicoesTrabalho': condicoesTrabalho!.trim(),
        'vrBeneficioSocial': vrBeneficioSocial,
        'rendaMensal': rendaMensal,
      };

  OcupacaoFamiliar? get ocupacaoEnum => OcupacaoFamiliar.fromApi(ocupacao);
}
