import 'auditoria_campos.dart';
import 'tipo_usuario.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nomeUsuario,
    required this.nome,
    required this.email,
    required this.tipoUsuarioId,
    required this.tipoUsuario,
    required this.ativo,
    required this.createdAt,
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final String nomeUsuario;
  final String nome;
  final String email;
  final String tipoUsuarioId;
  final TipoUsuarioResumo tipoUsuario;
  final bool ativo;
  final DateTime createdAt;
  final AuditoriaCampos auditoria;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nomeUsuario: json['nomeUsuario'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      tipoUsuarioId: json['tipoUsuarioId'] as String,
      tipoUsuario: TipoUsuarioResumo.fromJson(
        json['tipoUsuario'] as Map<String, dynamic>,
      ),
      ativo: json['ativo'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }

  Map<String, dynamic> toCreateJson({required String senha}) => {
        'nomeUsuario': nomeUsuario,
        'nome': nome,
        'email': email,
        'senha': senha,
        'tipoUsuarioId': tipoUsuarioId,
        'ativo': ativo,
      };

  Map<String, dynamic> toUpdateJson({String? senha}) => {
        'nomeUsuario': nomeUsuario,
        'nome': nome,
        'email': email,
        'tipoUsuarioId': tipoUsuarioId,
        'ativo': ativo,
        if (senha != null && senha.isNotEmpty) 'senha': senha,
      };

  bool get isAdmin =>
      tipoUsuario.perfil == PerfilTipoUsuario.administrador;
}

class TipoUsuarioResumo {
  const TipoUsuarioResumo({
    required this.id,
    required this.descricao,
    required this.perfil,
    required this.ativo,
  });

  final String id;
  final String descricao;
  final PerfilTipoUsuario perfil;
  final bool ativo;

  factory TipoUsuarioResumo.fromJson(Map<String, dynamic> json) {
    return TipoUsuarioResumo(
      id: json['id'] as String,
      descricao: json['descricao'] as String,
      perfil: perfilFromApi(json['perfil'] as String),
      ativo: json['ativo'] as bool,
    );
  }
}
