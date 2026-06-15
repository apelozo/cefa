/// Formata usuário da auditoria: `nomeUsuario` e, se couber, nome completo.
String formatUsuarioAuditoria({
  String? nomeUsuario,
  String? nome,
}) {
  final login = nomeUsuario?.trim();
  final completo = nome?.trim();
  if (login != null && login.isNotEmpty) {
    if (completo != null &&
        completo.isNotEmpty &&
        completo.toLowerCase() != login.toLowerCase()) {
      return '$login · $completo';
    }
    return login;
  }
  if (completo != null && completo.isNotEmpty) return completo;
  return '';
}

String formatAuditoriaEvento({
  required String dataHora,
  String? nomeUsuario,
  String? nome,
}) {
  final usuario = formatUsuarioAuditoria(
    nomeUsuario: nomeUsuario,
    nome: nome,
  );
  if (usuario.isEmpty) return dataHora;
  return '$dataHora · $usuario';
}
