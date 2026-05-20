import '../models/pergunta.dart';

int proximaOrdemDisponivel(List<Pergunta> perguntas) {
  if (perguntas.isEmpty) return 0;
  var maxOrdem = perguntas.first.ordem;
  for (final p in perguntas) {
    if (p.ordem > maxOrdem) maxOrdem = p.ordem;
  }
  return maxOrdem + 1;
}

bool ordemDuplicada({
  required List<Pergunta> perguntas,
  required int ordem,
  String? excluirPerguntaId,
}) {
  return perguntas.any(
    (p) => p.ordem == ordem && p.id != excluirPerguntaId,
  );
}
