import '../models/permissao.dart';
import '../models/programa.dart';

/// Garante uma linha por programa cadastrado (mesma fonte que módulos do sistema).
List<PermissaoLinha> mergePermissaoLinhasComProgramas(
  List<PermissaoLinha> fromApi,
  List<Programa> todosProgramas,
) {
  final perfilAdmin =
      fromApi.isNotEmpty && fromApi.first.perfilAdmin;
  final porId = {for (final l in fromApi) l.programaId: l};

  final merged = todosProgramas
      .map(
        (p) =>
            porId[p.id] ??
            PermissaoLinha(
              programaId: p.id,
              programaCodigo: p.codigo,
              programaNome: p.nome,
              podeIncluir: false,
              podeAlterar: false,
              podeConsultar: false,
              podeExcluir: false,
              perfilAdmin: perfilAdmin,
            ),
      )
      .toList();
  merged.sort((a, b) => a.programaNome.compareTo(b.programaNome));
  return merged;
}
