enum PerfilTipoUsuario { administrador, sistema, comum }

PerfilTipoUsuario perfilFromApi(String value) {
  switch (value) {
    case 'ADMINISTRADOR':
      return PerfilTipoUsuario.administrador;
    case 'SISTEMA':
      return PerfilTipoUsuario.sistema;
    default:
      return PerfilTipoUsuario.comum;
  }
}

String perfilToApi(PerfilTipoUsuario perfil) {
  switch (perfil) {
    case PerfilTipoUsuario.administrador:
      return 'ADMINISTRADOR';
    case PerfilTipoUsuario.sistema:
      return 'SISTEMA';
    case PerfilTipoUsuario.comum:
      return 'COMUM';
  }
}

String perfilLabel(PerfilTipoUsuario perfil) {
  switch (perfil) {
    case PerfilTipoUsuario.administrador:
      return 'Administrador';
    case PerfilTipoUsuario.sistema:
      return 'Usuário do sistema';
    case PerfilTipoUsuario.comum:
      return 'Comum';
  }
}

class TipoUsuario {
  const TipoUsuario({
    required this.id,
    required this.descricao,
    required this.perfil,
    required this.ativo,
    required this.createdAt,
  });

  final String id;
  final String descricao;
  final PerfilTipoUsuario perfil;
  final bool ativo;
  final DateTime createdAt;

  factory TipoUsuario.fromJson(Map<String, dynamic> json) {
    return TipoUsuario(
      id: json['id'] as String,
      descricao: json['descricao'] as String,
      perfil: perfilFromApi(json['perfil'] as String),
      ativo: json['ativo'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'descricao': descricao,
        'perfil': perfilToApi(perfil),
        'ativo': ativo,
      };

  Map<String, dynamic> toUpdateJson() => {
        'descricao': descricao,
        'perfil': perfilToApi(perfil),
        'ativo': ativo,
      };

  TipoUsuario copyWith({
    String? descricao,
    PerfilTipoUsuario? perfil,
    bool? ativo,
  }) {
    return TipoUsuario(
      id: id,
      descricao: descricao ?? this.descricao,
      perfil: perfil ?? this.perfil,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt,
    );
  }
}
