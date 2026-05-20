import '../constants/resposta_sim_nao.dart';

class EntrevistaGestanteFamiliar {
  const EntrevistaGestanteFamiliar({
    this.id,
    required this.nome,
    required this.mesesGestacao,
    required this.iniciouPreNatal,
    this.ordem = 0,
  });

  final String? id;
  final String nome;
  final int mesesGestacao;
  final String iniciouPreNatal;
  final int ordem;

  factory EntrevistaGestanteFamiliar.fromJson(Map<String, dynamic> json) {
    return EntrevistaGestanteFamiliar(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      mesesGestacao: json['mesesGestacao'] as int,
      iniciouPreNatal: json['iniciouPreNatal'] as String,
      ordem: json['ordem'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'mesesGestacao': mesesGestacao,
        'iniciouPreNatal': iniciouPreNatal,
      };

  RespostaSimNao? get preNatalEnum =>
      RespostaSimNao.fromApi(iniciouPreNatal);
}
