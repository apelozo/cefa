import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/modulo_sistema.dart';
import '../models/pergunta.dart';
import '../models/permissao.dart';
import '../models/bairro.dart';
import '../models/departamento.dart';
import '../models/curso.dart';
import '../models/turma.dart';
import '../models/aluno.dart';
import '../models/inscricao.dart';
import '../models/inscricao_atendimento.dart';
import '../models/matricula_candidato.dart';
import '../models/cancelamento_matricula.dart';
import '../models/relatorio_alunos_turma.dart';
import '../models/voluntario.dart';
import '../models/voluntario_departamento_horario.dart';
import '../models/escolaridade.dart';
import '../models/cidade.dart';
import '../models/pessoa.dart';
import '../models/programa.dart';
import '../models/relatorio_submodulo.dart';
import '../models/entrevista_assistido.dart';
import '../models/submissao.dart';
import '../models/tipo_formulario.dart';
import '../models/tipos_formulario_acesso.dart';
import '../models/tipo_usuario.dart';
import '../models/usuario.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthLoginResult {
  const AuthLoginResult({
    required this.token,
    required this.usuario,
    required this.permissoes,
  });

  final String token;
  final Usuario usuario;
  final Map<String, ProgramaPermissao> permissoes;
}

class AuthMeResult {
  const AuthMeResult({
    required this.usuario,
    required this.permissoes,
  });

  final Usuario usuario;
  final Map<String, ProgramaPermissao> permissoes;
}

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {Headers.acceptHeader: 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  String? _token;
  void Function()? onUnauthorized;

  void setToken(String? token) => _token = token;

  static Map<String, ProgramaPermissao> _parsePermissoes(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null) return {};
    return raw.map(
      (k, v) => MapEntry(
        k,
        ProgramaPermissao.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  static final _jsonOptions = Options(contentType: Headers.jsonContentType);

  /// DELETE sem corpo: não enviar Content-Type (evita 400 no Fastify).
  static final _deleteOptions = Options(
    contentType: null,
    responseType: ResponseType.json,
  );

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['error'] != null) {
        final err = data['error'].toString();
        final details = data['details'];
        if (details != null) {
          return '$err\n$details';
        }
        return err;
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Não foi possível conectar à API em ${ApiConfig.baseUrl}. '
          '1) Abra um terminal e rode: cd backend && npm run dev\n'
          '2) Teste no navegador: ${ApiConfig.baseUrl}/health\n'
          '3) Reinicie o app Flutter (hot reload não atualiza a URL).';
    }
    final status = e.response?.statusCode;
    if (status != null) {
      return 'Erro HTTP $status: ${e.response?.statusMessage ?? e.message}';
    }
    return e.message ?? 'Erro de comunicação com a API';
  }

  // --- Auth ---

  Future<AuthLoginResult> login(String nomeUsuario, String senha) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'nomeUsuario': nomeUsuario, 'senha': senha},
        options: _jsonOptions,
      );
      final data = response.data!;
      return AuthLoginResult(
        token: data['token'] as String,
        usuario: Usuario.fromJson(data['usuario'] as Map<String, dynamic>),
        permissoes: _parsePermissoes(
          data['permissoes'] as Map<String, dynamic>?,
        ),
      );
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<AuthMeResult> getAuthMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data!;
      return AuthMeResult(
        usuario: Usuario.fromJson(data['usuario'] as Map<String, dynamic>),
        permissoes: _parsePermissoes(
          data['permissoes'] as Map<String, dynamic>?,
        ),
      );
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Módulos do sistema ---

  Future<List<ModuloMenuItem>> getMenuModulos() async {
    try {
      final response = await _dio.get<List<dynamic>>('/modulos-sistema/menu');
      return (response.data ?? [])
          .map((e) => ModuloMenuItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<ModuloSistema>> listModulosSistema({bool? ativo}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/modulos-sistema',
        queryParameters: ativo != null ? {'ativo': ativo.toString()} : null,
      );
      return (response.data ?? [])
          .map((e) => ModuloSistema.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<ModuloSistema> getModuloSistema(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/modulos-sistema/$id');
      return ModuloSistema.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<ModuloSistema> createModuloSistema(ModuloSistema modulo) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/modulos-sistema',
        data: modulo.toCreateJson(),
        options: _jsonOptions,
      );
      return ModuloSistema.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<ModuloSistema> updateModuloSistema(ModuloSistema modulo) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/modulos-sistema/${modulo.id}',
        data: modulo.toUpdateJson(),
        options: _jsonOptions,
      );
      return ModuloSistema.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<ModuloSistema> deleteModuloSistema(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/modulos-sistema/$id',
        options: _deleteOptions,
      );
      return ModuloSistema.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<ModuloSistema> setModuloProgramas(
    String moduloId,
    List<String> programaIds,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/modulos-sistema/$moduloId/programas',
        data: {'programaIds': programaIds},
        options: _jsonOptions,
      );
      return ModuloSistema.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<Programa>> listProgramas() async {
    try {
      final response = await _dio.get<List<dynamic>>('/programas');
      return (response.data ?? [])
          .map((e) => Programa.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Programa> createPrograma(Programa programa) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/programas',
        data: programa.toCreateJson(),
        options: _jsonOptions,
      );
      return Programa.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Programa> updatePrograma(Programa programa) async {
    if (programa.id.isEmpty) {
      throw ApiException('ID do programa inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/programas/${programa.id}',
        data: programa.toUpdateJson(),
        options: _jsonOptions,
      );
      return Programa.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Submódulos de relatórios ---

  Future<List<RelatorioSubmodulo>> listRelatorioSubmodulos({
    bool? ativo,
    String? codigo,
    String? nome,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null && codigo.trim().isNotEmpty) {
        params['codigo'] = codigo.trim().toLowerCase();
      }
      if (nome != null && nome.trim().isNotEmpty) {
        params['nome'] = nome.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/relatorio-submodulos',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => RelatorioSubmodulo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<RelatorioSubmodulo> createRelatorioSubmodulo(
    RelatorioSubmodulo submodulo,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/relatorio-submodulos',
        data: submodulo.toCreateJson(),
        options: _jsonOptions,
      );
      return RelatorioSubmodulo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<RelatorioSubmodulo> updateRelatorioSubmodulo(
    RelatorioSubmodulo submodulo,
  ) async {
    if (submodulo.id.isEmpty) {
      throw ApiException('ID do submódulo inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/relatorio-submodulos/${submodulo.id}',
        data: submodulo.toUpdateJson(),
        options: _jsonOptions,
      );
      return RelatorioSubmodulo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> deleteRelatorioSubmodulo(String id) async {
    try {
      await _dio.delete<void>(
        '/relatorio-submodulos/$id',
        options: _deleteOptions,
      );
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Tipos de usuário ---

  Future<List<TipoUsuario>> listTiposUsuario({bool? ativo}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/tipos-usuario',
        queryParameters: ativo != null ? {'ativo': ativo.toString()} : null,
      );
      return (response.data ?? [])
          .map((e) => TipoUsuario.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TipoUsuario> createTipoUsuario(TipoUsuario tipo) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/tipos-usuario',
        data: tipo.toCreateJson(),
        options: _jsonOptions,
      );
      return TipoUsuario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TipoUsuario> updateTipoUsuario(TipoUsuario tipo) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/tipos-usuario/${tipo.id}',
        data: tipo.toUpdateJson(),
        options: _jsonOptions,
      );
      return TipoUsuario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TipoUsuario> deleteTipoUsuario(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/tipos-usuario/$id',
        options: _deleteOptions,
      );
      return TipoUsuario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<PermissaoLinha>> getPermissoesTipoUsuario(String tipoId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/tipos-usuario/$tipoId/permissoes');
      final list = response.data!['permissoes'] as List<dynamic>;
      return list
          .map((e) => PermissaoLinha.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<PermissaoLinha>> setPermissoesTipoUsuario(
    String tipoId,
    List<PermissaoLinha> linhas,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/tipos-usuario/$tipoId/permissoes',
        data: {
          'permissoes': linhas
              .where(
                (l) =>
                    l.podeIncluir ||
                    l.podeAlterar ||
                    l.podeConsultar ||
                    l.podeExcluir,
              )
              .map((l) => l.toSaveJson())
              .toList(),
        },
        options: _jsonOptions,
      );
      final list = response.data!['permissoes'] as List<dynamic>;
      return list
          .map((e) => PermissaoLinha.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Usuários ---

  Future<List<Usuario>> listUsuarios({bool? ativo}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/usuarios',
        queryParameters: ativo != null ? {'ativo': ativo.toString()} : null,
      );
      return (response.data ?? [])
          .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Usuario> createUsuario(Usuario usuario, {required String senha}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/usuarios',
        data: usuario.toCreateJson(senha: senha),
        options: _jsonOptions,
      );
      return Usuario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Usuario> updateUsuario(Usuario usuario, {String? senha}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/usuarios/${usuario.id}',
        data: usuario.toUpdateJson(senha: senha),
        options: _jsonOptions,
      );
      return Usuario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Usuario> deleteUsuario(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/usuarios/$id',
        options: _deleteOptions,
      );
      return Usuario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<PermissaoLinha>> getPermissoesUsuario(String usuarioId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/usuarios/$usuarioId/permissoes');
      final list = response.data!['permissoes'] as List<dynamic>;
      return list
          .map((e) => PermissaoLinha.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<PermissaoLinha>> setPermissoesUsuario(
    String usuarioId,
    List<PermissaoLinha> linhas,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/usuarios/$usuarioId/permissoes',
        data: {
          'permissoes': linhas
              .where(
                (l) =>
                    l.podeIncluir ||
                    l.podeAlterar ||
                    l.podeConsultar ||
                    l.podeExcluir,
              )
              .map((l) => l.toSaveJson())
              .toList(),
        },
        options: _jsonOptions,
      );
      final list = response.data!['permissoes'] as List<dynamic>;
      return list
          .map((e) => PermissaoLinha.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Tipos de formulário ---

  Future<TiposFormularioAcessoResumo> getTiposFormularioAcessoTipoUsuario(
    String tipoId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tipos-usuario/$tipoId/tipos-formulario-acesso',
      );
      return TiposFormularioAcessoResumo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TiposFormularioAcessoResumo> setTiposFormularioAcessoTipoUsuario(
    String tipoId,
    List<String> tipoFormularioIds,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/tipos-usuario/$tipoId/tipos-formulario-acesso',
        data: {'tipoFormularioIds': tipoFormularioIds},
        options: _jsonOptions,
      );
      return TiposFormularioAcessoResumo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TiposFormularioAcessoResumo> getTiposFormularioAcessoUsuario(
    String usuarioId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/usuarios/$usuarioId/tipos-formulario-acesso',
      );
      return TiposFormularioAcessoResumo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TiposFormularioAcessoResumo> setTiposFormularioAcessoUsuario(
    String usuarioId,
    List<String> tipoFormularioIds,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/usuarios/$usuarioId/tipos-formulario-acesso',
        data: {'tipoFormularioIds': tipoFormularioIds},
        options: _jsonOptions,
      );
      return TiposFormularioAcessoResumo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<TipoFormulario>> listTiposFormulario({
    bool? ativo,
    bool todos = false,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (todos) params['todos'] = 'true';
      final response = await _dio.get<List<dynamic>>(
        '/tipos-formulario',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => TipoFormulario.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TipoFormulario> createTipoFormulario(TipoFormulario tipo) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/tipos-formulario',
        data: tipo.toCreateJson(),
        options: _jsonOptions,
      );
      return TipoFormulario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TipoFormulario> updateTipoFormulario(TipoFormulario tipo) async {
    if (tipo.id.isEmpty) {
      throw ApiException('ID do tipo de formulário inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/tipos-formulario/${tipo.id}',
        data: tipo.toUpdateJson(),
        options: _jsonOptions,
      );
      return TipoFormulario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<TipoFormulario> deleteTipoFormulario(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/tipos-formulario/$id',
        options: _deleteOptions,
      );
      return TipoFormulario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Perguntas ---

  Future<List<Pergunta>> listPerguntas({
    bool? ativo,
    String? tipoFormularioId,
    bool opcoesAtivas = false,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (tipoFormularioId != null) {
        params['tipoFormularioId'] = tipoFormularioId;
      }
      if (opcoesAtivas) params['opcoesAtivas'] = 'true';
      final response = await _dio.get<List<dynamic>>(
        '/perguntas',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Pergunta.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pergunta> getPergunta(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/perguntas/$id');
      return Pergunta.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pergunta> createPergunta(Pergunta pergunta) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/perguntas',
        data: pergunta.toCreateJson(),
        options: _jsonOptions,
      );
      return Pergunta.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pergunta> updatePergunta(Pergunta pergunta) async {
    if (pergunta.id.isEmpty) {
      throw ApiException('ID da pergunta inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/perguntas/${pergunta.id}',
        data: pergunta.toUpdateJson(),
        options: _jsonOptions,
      );
      return Pergunta.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pergunta> deletePergunta(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/perguntas/$id',
        options: _deleteOptions,
      );
      return Pergunta.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Pessoas ---

  Future<List<Pessoa>> listPessoas({
    bool? ativo,
    String? q,
    String? nome,
    String? cpf,
    String? rg,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (nome != null && nome.trim().isNotEmpty) params['nome'] = nome.trim();
      if (cpf != null && cpf.trim().isNotEmpty) params['cpf'] = cpf.trim();
      if (rg != null && rg.trim().isNotEmpty) params['rg'] = rg.trim();
      final response = await _dio.get<List<dynamic>>(
        '/pessoas',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Pessoa.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pessoa> getPessoa(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/pessoas/$id');
      return Pessoa.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pessoa> createPessoa(Pessoa pessoa) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/pessoas',
        data: pessoa.toCreateJson(),
        options: _jsonOptions,
      );
      return Pessoa.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pessoa> updatePessoa(Pessoa pessoa) async {
    if (pessoa.id.isEmpty) {
      throw ApiException('ID do assistido inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/pessoas/${pessoa.id}',
        data: pessoa.toUpdateJson(),
        options: _jsonOptions,
      );
      return Pessoa.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Pessoa> deletePessoa(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/pessoas/$id',
        options: _deleteOptions,
      );
      return Pessoa.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Cidades ---

  Future<List<Cidade>> listCidades({
    bool? ativo,
    String? nome,
    String? estado,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (nome != null && nome.trim().isNotEmpty) params['nome'] = nome.trim();
      if (estado != null && estado.trim().isNotEmpty) {
        params['estado'] = estado.trim().toUpperCase();
      }
      final response = await _dio.get<List<dynamic>>(
        '/cidades',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Cidade.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Cidade> createCidade(Cidade cidade) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cidades',
        data: cidade.toCreateJson(),
        options: _jsonOptions,
      );
      return Cidade.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Cidade> updateCidade(Cidade cidade) async {
    if (cidade.id.isEmpty) {
      throw ApiException('ID da cidade inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/cidades/${cidade.id}',
        data: cidade.toUpdateJson(),
        options: _jsonOptions,
      );
      return Cidade.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Cidade> softDeleteCidade(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/cidades/$id',
        options: _deleteOptions,
      );
      return Cidade.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Bairros ---

  Future<List<Bairro>> listBairros({
    bool? ativo,
    int? codigo,
    String? nome,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null) {
        params['codigo'] = codigo.toString();
      }
      if (nome != null && nome.trim().isNotEmpty) params['nome'] = nome.trim();
      final response = await _dio.get<List<dynamic>>(
        '/bairros',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Bairro.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Bairro> createBairro(Bairro bairro) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/bairros',
        data: bairro.toCreateJson(),
        options: _jsonOptions,
      );
      return Bairro.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Bairro> updateBairro(Bairro bairro) async {
    if (bairro.id.isEmpty) {
      throw ApiException('ID do bairro inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/bairros/${bairro.id}',
        data: bairro.toUpdateJson(),
        options: _jsonOptions,
      );
      return Bairro.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Bairro> softDeleteBairro(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/bairros/$id',
        options: _deleteOptions,
      );
      return Bairro.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Escolaridades ---

  Future<List<Escolaridade>> listEscolaridades({
    bool? ativo,
    int? codigo,
    String? descricao,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null) params['codigo'] = codigo.toString();
      if (descricao != null && descricao.trim().isNotEmpty) {
        params['descricao'] = descricao.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/escolaridades',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Escolaridade.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Escolaridade> createEscolaridade(Escolaridade escolaridade) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/escolaridades',
        data: escolaridade.toCreateJson(),
        options: _jsonOptions,
      );
      return Escolaridade.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Escolaridade> updateEscolaridade(Escolaridade escolaridade) async {
    if (escolaridade.id.isEmpty) {
      throw ApiException('ID da escolaridade inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/escolaridades/${escolaridade.id}',
        data: escolaridade.toUpdateJson(),
        options: _jsonOptions,
      );
      return Escolaridade.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Escolaridade> softDeleteEscolaridade(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/escolaridades/$id',
        options: _deleteOptions,
      );
      return Escolaridade.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Departamentos ---

  Future<List<Departamento>> listDepartamentos({
    bool? ativo,
    int? codigo,
    String? descricao,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null) params['codigo'] = codigo.toString();
      if (descricao != null && descricao.trim().isNotEmpty) {
        params['descricao'] = descricao.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/departamentos',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Departamento.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Departamento> createDepartamento(Departamento departamento) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/departamentos',
        data: departamento.toCreateJson(),
        options: _jsonOptions,
      );
      return Departamento.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Departamento> updateDepartamento(Departamento departamento) async {
    if (departamento.id.isEmpty) {
      throw ApiException('ID do departamento inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/departamentos/${departamento.id}',
        data: departamento.toUpdateJson(),
        options: _jsonOptions,
      );
      return Departamento.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Departamento> desativarDepartamento(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/departamentos/$id',
        options: _deleteOptions,
      );
      return Departamento.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Cursos ---

  Future<List<Curso>> listCursos({
    bool? ativo,
    int? codigo,
    String? descricao,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null) params['codigo'] = codigo.toString();
      if (descricao != null && descricao.trim().isNotEmpty) {
        params['descricao'] = descricao.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/cursos',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Curso.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Curso> createCurso(Curso curso) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cursos',
        data: curso.toCreateJson(),
        options: _jsonOptions,
      );
      return Curso.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Curso> updateCurso(Curso curso) async {
    if (curso.id.isEmpty) {
      throw ApiException('ID do curso inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/cursos/${curso.id}',
        data: curso.toUpdateJson(),
        options: _jsonOptions,
      );
      return Curso.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Curso> desativarCurso(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/cursos/$id',
        options: _deleteOptions,
      );
      return Curso.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Turmas ---

  Future<List<Turma>> listTurmas({
    bool? ativo,
    int? codigo,
    String? nome,
    int? cursoCodigo,
    String? cursoDescricao,
    String? periodo,
    String? situacao,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null) params['codigo'] = codigo.toString();
      if (nome != null && nome.trim().isNotEmpty) {
        params['nome'] = nome.trim();
      }
      if (cursoCodigo != null) params['cursoCodigo'] = cursoCodigo.toString();
      if (cursoDescricao != null && cursoDescricao.trim().isNotEmpty) {
        params['cursoDescricao'] = cursoDescricao.trim();
      }
      if (periodo != null && periodo.trim().isNotEmpty) {
        params['periodo'] = periodo.trim();
      }
      if (situacao != null && situacao.trim().isNotEmpty) {
        params['situacao'] = situacao.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/turmas',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Turma.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Turma> getTurma(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/turmas/$id');
      return Turma.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Turma> createTurma(Turma turma) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/turmas',
        data: turma.toCreateJson(),
        options: _jsonOptions,
      );
      return Turma.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Turma> updateTurma(Turma turma) async {
    if (turma.id.isEmpty) {
      throw ApiException('ID da turma inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/turmas/${turma.id}',
        data: turma.toUpdateJson(),
        options: _jsonOptions,
      );
      return Turma.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Turma> desativarTurma(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/turmas/$id',
        options: _deleteOptions,
      );
      return Turma.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Alunos ---

  Future<List<Aluno>> listAlunos({
    bool? ativo,
    String? nome,
    String? cpf,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (nome != null && nome.trim().isNotEmpty) {
        params['nome'] = nome.trim();
      }
      if (cpf != null && cpf.trim().isNotEmpty) {
        params['cpf'] = cpf.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/alunos',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Aluno.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Aluno> getAluno(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/alunos/$id',
      );
      return Aluno.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Aluno> createAluno(Aluno aluno) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/alunos',
        data: aluno.toSaveJson(),
        options: _jsonOptions,
      );
      return Aluno.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Aluno> updateAluno(Aluno aluno) async {
    if (aluno.id.isEmpty) {
      throw ApiException('ID do aluno inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/alunos/${aluno.id}',
        data: aluno.toSaveJson(),
        options: _jsonOptions,
      );
      return Aluno.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Aluno> desativarAluno(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/alunos/$id',
        options: _deleteOptions,
      );
      return Aluno.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Inscrições (aluno em curso) ---

  Future<List<Inscricao>> listInscricoes({
    bool? ativo,
    int? codigo,
    String? alunoId,
    String? alunoNome,
    String? alunoCpf,
    int? turmaCodigo,
    String? turmaNome,
    int? cursoCodigo,
    String? cursoDescricao,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null) params['codigo'] = codigo.toString();
      if (alunoId != null && alunoId.trim().isNotEmpty) {
        params['alunoId'] = alunoId.trim();
      }
      if (alunoNome != null && alunoNome.trim().isNotEmpty) {
        params['alunoNome'] = alunoNome.trim();
      }
      if (alunoCpf != null && alunoCpf.trim().isNotEmpty) {
        params['alunoCpf'] = alunoCpf.trim();
      }
      if (turmaCodigo != null) {
        params['turmaCodigo'] = turmaCodigo.toString();
      }
      if (turmaNome != null && turmaNome.trim().isNotEmpty) {
        params['turmaNome'] = turmaNome.trim();
      }
      if (cursoCodigo != null) {
        params['cursoCodigo'] = cursoCodigo.toString();
      }
      if (cursoDescricao != null && cursoDescricao.trim().isNotEmpty) {
        params['cursoDescricao'] = cursoDescricao.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/inscricoes',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Inscricao.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Inscricao> getInscricao(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inscricoes/$id',
      );
      return Inscricao.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Inscricao> createInscricao(Inscricao inscricao) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inscricoes',
        data: inscricao.toSaveJson(),
        options: _jsonOptions,
      );
      return Inscricao.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Inscricao> updateInscricao(Inscricao inscricao) async {
    if (inscricao.id.isEmpty) {
      throw ApiException('ID da inscrição inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inscricoes/${inscricao.id}',
        data: inscricao.toSaveJson(),
        options: _jsonOptions,
      );
      return Inscricao.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Inscricao> desativarInscricao(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/inscricoes/$id',
        options: _deleteOptions,
      );
      return Inscricao.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<MatriculaCandidatosResult> listMatriculaCandidatos({
    required int turmaCodigo,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inscricoes/matricula/candidatos',
        queryParameters: {'turmaCodigo': turmaCodigo.toString()},
      );
      return MatriculaCandidatosResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<MatriculaCandidatosResult> gravarMatricula({
    required int turmaCodigo,
    required String dtInicioCurso,
    required int vagas,
    required List<String> inscricaoIds,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inscricoes/matricula',
        data: {
          'turmaCodigo': turmaCodigo,
          'dtInicioCurso': dtInicioCurso,
          'vagas': vagas,
          'inscricaoIds': inscricaoIds,
        },
        options: _jsonOptions,
      );
      return MatriculaCandidatosResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<CancelamentoMatriculaResult> listCancelamentoMatriculaMatriculados({
    required int turmaCodigo,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inscricoes/cancelamento-matricula/matriculados',
        queryParameters: {'turmaCodigo': turmaCodigo.toString()},
      );
      return CancelamentoMatriculaResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<CancelamentoMatriculaResult> gravarCancelamentoMatricula({
    required int turmaCodigo,
    required List<String> inscricaoIds,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inscricoes/cancelamento-matricula',
        data: {
          'turmaCodigo': turmaCodigo,
          'inscricaoIds': inscricaoIds,
        },
        options: _jsonOptions,
      );
      return CancelamentoMatriculaResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<RelatorioAlunosTurmaResult> relatorioAlunosTurma({
    int? cursoCodigo,
    int? turmaCodigo,
    required String situacao,
  }) async {
    try {
      final params = <String, String>{'situacao': situacao};
      if (cursoCodigo != null) {
        params['cursoCodigo'] = cursoCodigo.toString();
      }
      if (turmaCodigo != null) {
        params['turmaCodigo'] = turmaCodigo.toString();
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/inscricoes/relatorio-alunos-turma',
        queryParameters: params,
      );
      return RelatorioAlunosTurmaResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<Curso>> listRelatorioAlunosTurmaCursos() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/inscricoes/relatorio-alunos-turma/cursos',
      );
      return (response.data ?? [])
          .map((e) => Curso.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<Turma>> listRelatorioAlunosTurmaTurmas({
    required int cursoCodigo,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/inscricoes/relatorio-alunos-turma/turmas',
        queryParameters: {'cursoCodigo': cursoCodigo.toString()},
      );
      return (response.data ?? [])
          .map((e) => Turma.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Atendimento de alunos matriculados ---

  Future<List<AlunoMatriculadoResumo>> listAlunosMatriculados({
    required int turmaCodigo,
    String? nome,
    String? cpf,
  }) async {
    try {
      final params = <String, String>{
        'turmaCodigo': turmaCodigo.toString(),
      };
      if (nome != null && nome.trim().isNotEmpty) {
        params['nome'] = nome.trim();
      }
      if (cpf != null && cpf.trim().isNotEmpty) {
        params['cpf'] = cpf.trim();
      }
      final response = await _dio.get<List<dynamic>>(
        '/inscricao-atendimentos/alunos-matriculados',
        queryParameters: params,
        options: _jsonOptions,
      );
      return (response.data ?? [])
          .map(
            (e) => AlunoMatriculadoResumo.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<InscricaoAtendimentosContexto> listInscricaoAtendimentos({
    String? inscricaoId,
    int? turmaCodigo,
    String? alunoId,
  }) async {
    try {
      final params = <String, String>{};
      if (inscricaoId != null && inscricaoId.trim().isNotEmpty) {
        params['inscricaoId'] = inscricaoId.trim();
      }
      if (turmaCodigo != null) {
        params['turmaCodigo'] = turmaCodigo.toString();
      }
      if (alunoId != null && alunoId.trim().isNotEmpty) {
        params['alunoId'] = alunoId.trim();
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/inscricao-atendimentos',
        queryParameters: params,
        options: _jsonOptions,
      );
      return InscricaoAtendimentosContexto.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<InscricaoAtendimento> getInscricaoAtendimento(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/inscricao-atendimentos/$id',
        options: _jsonOptions,
      );
      return InscricaoAtendimento.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<InscricaoAtendimento> createInscricaoAtendimento({
    String? inscricaoId,
    int? turmaCodigo,
    String? alunoId,
    required String dataAtendimento,
    required String descricao,
  }) async {
    try {
      final data = <String, dynamic>{
        'dataAtendimento': dataAtendimento,
        'descricao': descricao,
      };
      if (inscricaoId != null) data['inscricaoId'] = inscricaoId;
      if (turmaCodigo != null) data['turmaCodigo'] = turmaCodigo;
      if (alunoId != null) data['alunoId'] = alunoId;
      final response = await _dio.post<Map<String, dynamic>>(
        '/inscricao-atendimentos',
        data: data,
        options: _jsonOptions,
      );
      return InscricaoAtendimento.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<InscricaoAtendimento> updateInscricaoAtendimento({
    required String id,
    required String dataAtendimento,
    required String descricao,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inscricao-atendimentos/$id',
        data: {
          'dataAtendimento': dataAtendimento,
          'descricao': descricao,
        },
        options: _jsonOptions,
      );
      return InscricaoAtendimento.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> deleteInscricaoAtendimento(String id) async {
    try {
      await _dio.delete<void>(
        '/inscricao-atendimentos/$id',
        options: _jsonOptions,
      );
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Voluntários ---

  Future<List<Voluntario>> listVoluntarios({
    bool? ativo,
    int? codigo,
    String? nome,
    String? nomeCracha,
    String? empresa,
    String? cpf,
    int? departamentoCodigo,
  }) async {
    try {
      final params = <String, String>{};
      if (ativo != null) params['ativo'] = ativo.toString();
      if (codigo != null) params['codigo'] = codigo.toString();
      final nomeBusca = (nome ?? nomeCracha)?.trim();
      if (nomeBusca != null && nomeBusca.isNotEmpty) {
        params['nome'] = nomeBusca;
      }
      if (empresa != null && empresa.trim().isNotEmpty) {
        params['empresa'] = empresa.trim();
      }
      if (cpf != null && cpf.trim().isNotEmpty) {
        params['cpf'] = cpf.trim();
      }
      if (departamentoCodigo != null) {
        params['departamentoCodigo'] = departamentoCodigo.toString();
      }
      final response = await _dio.get<List<dynamic>>(
        '/voluntarios',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => Voluntario.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Voluntario> createVoluntario(Voluntario voluntario) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/voluntarios',
        data: voluntario.toCreateJson(),
        options: _jsonOptions,
      );
      return Voluntario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Voluntario> updateVoluntario(Voluntario voluntario) async {
    if (voluntario.id.isEmpty) {
      throw ApiException('ID do voluntário inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/voluntarios/${voluntario.id}',
        data: voluntario.toUpdateJson(),
        options: _jsonOptions,
      );
      return Voluntario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Voluntario> desativarVoluntario(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/voluntarios/$id',
        options: _deleteOptions,
      );
      return Voluntario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Voluntário × departamento (horários) ---

  Future<List<VoluntarioDepartamentoHorario>> listVoluntarioDepartamentoHorarios(
    String voluntarioId,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/voluntarios/$voluntarioId/departamento-horarios',
      );
      return (response.data ?? [])
          .map(
            (e) => VoluntarioDepartamentoHorario.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<VoluntarioDepartamentoHorario> createVoluntarioDepartamentoHorario(
    String voluntarioId,
    VoluntarioDepartamentoHorario horario,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/voluntarios/$voluntarioId/departamento-horarios',
        data: horario.toCreateJson(),
        options: _jsonOptions,
      );
      return VoluntarioDepartamentoHorario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<VoluntarioDepartamentoHorario> updateVoluntarioDepartamentoHorario(
    VoluntarioDepartamentoHorario horario,
  ) async {
    if (horario.id.isEmpty) {
      throw ApiException('ID do vínculo inválido');
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/voluntario-departamento-horarios/${horario.id}',
        data: horario.toUpdateJson(),
        options: _jsonOptions,
      );
      return VoluntarioDepartamentoHorario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<VoluntarioDepartamentoHorario> deleteVoluntarioDepartamentoHorario(
    String id,
  ) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/voluntario-departamento-horarios/$id',
        options: _deleteOptions,
      );
      return VoluntarioDepartamentoHorario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  // --- Submissões ---

  Future<List<SubmissaoResumo>> listSubmissoes({
    String? tipoFormularioId,
    String? pessoaId,
    String? nome,
    String? cpf,
  }) async {
    try {
      final params = <String, String>{};
      if (tipoFormularioId != null) {
        params['tipoFormularioId'] = tipoFormularioId;
      }
      if (pessoaId != null) params['pessoaId'] = pessoaId;
      if (nome != null && nome.trim().isNotEmpty) params['nome'] = nome.trim();
      if (cpf != null && cpf.trim().isNotEmpty) params['cpf'] = cpf.trim();
      final response = await _dio.get<List<dynamic>>(
        '/submissoes',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map((e) => SubmissaoResumo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Submissao> createSubmissao({
    required String tipoFormularioId,
    required String pessoaId,
    required List<RespostaItem> respostas,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/submissoes',
        data: {
          'tipoFormularioId': tipoFormularioId,
          'pessoaId': pessoaId,
          'respostas': respostas.map((r) => r.toJson()).toList(),
        },
        options: _jsonOptions,
      );
      return Submissao.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Submissao> getSubmissao(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/submissoes/$id');
      return Submissao.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<EntrevistaAssistidoResumo>> listEntrevistasAssistido({
    String? nome,
    String? cpf,
    String? pessoaId,
  }) async {
    try {
      final params = <String, String>{};
      if (pessoaId != null) params['pessoaId'] = pessoaId;
      if (nome != null && nome.trim().isNotEmpty) params['nome'] = nome.trim();
      if (cpf != null && cpf.trim().isNotEmpty) params['cpf'] = cpf.trim();
      final response = await _dio.get<List<dynamic>>(
        '/entrevistas-assistido',
        queryParameters: params.isEmpty ? null : params,
      );
      return (response.data ?? [])
          .map(
            (e) => EntrevistaAssistidoResumo.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<EntrevistaAssistido> getEntrevistaAssistido(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/entrevistas-assistido/$id',
      );
      return EntrevistaAssistido.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<EntrevistaAssistido> createEntrevistaAssistido({
    required String pessoaId,
    required String dataEntrevista,
    required List<String> formasAcesso,
    String? outrosTexto,
    List<Map<String, dynamic>> composicaoFamiliar = const [],
    List<Map<String, dynamic>> condicoesTrabalho = const [],
    List<Map<String, dynamic>> condicoesEducacionais = const [],
    List<Map<String, dynamic>> deficienciasFamilia = const [],
    List<Map<String, dynamic>> gestantesFamilia = const [],
    Map<String, dynamic>? programasSociais,
    Map<String, dynamic>? saudeFamilia,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/entrevistas-assistido',
        data: _entrevistaBody(
          pessoaId: pessoaId,
          dataEntrevista: dataEntrevista,
          formasAcesso: formasAcesso,
          outrosTexto: outrosTexto,
          composicaoFamiliar: composicaoFamiliar,
          condicoesTrabalho: condicoesTrabalho,
          condicoesEducacionais: condicoesEducacionais,
          deficienciasFamilia: deficienciasFamilia,
          gestantesFamilia: gestantesFamilia,
          programasSociais: programasSociais,
          saudeFamilia: saudeFamilia,
        ),
        options: _jsonOptions,
      );
      return EntrevistaAssistido.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<EntrevistaAssistido> updateEntrevistaAssistido({
    required String id,
    required String pessoaId,
    required String dataEntrevista,
    required List<String> formasAcesso,
    String? outrosTexto,
    List<Map<String, dynamic>> composicaoFamiliar = const [],
    List<Map<String, dynamic>> condicoesTrabalho = const [],
    List<Map<String, dynamic>> condicoesEducacionais = const [],
    List<Map<String, dynamic>> deficienciasFamilia = const [],
    List<Map<String, dynamic>> gestantesFamilia = const [],
    Map<String, dynamic>? programasSociais,
    Map<String, dynamic>? saudeFamilia,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/entrevistas-assistido/$id',
        data: _entrevistaBody(
          pessoaId: pessoaId,
          dataEntrevista: dataEntrevista,
          formasAcesso: formasAcesso,
          outrosTexto: outrosTexto,
          composicaoFamiliar: composicaoFamiliar,
          condicoesTrabalho: condicoesTrabalho,
          condicoesEducacionais: condicoesEducacionais,
          deficienciasFamilia: deficienciasFamilia,
          gestantesFamilia: gestantesFamilia,
          programasSociais: programasSociais,
          saudeFamilia: saudeFamilia,
        ),
        options: _jsonOptions,
      );
      return EntrevistaAssistido.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> deleteEntrevistaAssistido(String id) async {
    try {
      await _dio.delete<void>(
        '/entrevistas-assistido/$id',
        options: _deleteOptions,
      );
    } on DioException catch (e) {
      throw ApiException(_extractError(e), statusCode: e.response?.statusCode);
    }
  }

  Map<String, dynamic> _entrevistaBody({
    required String pessoaId,
    required String dataEntrevista,
    required List<String> formasAcesso,
    String? outrosTexto,
    List<Map<String, dynamic>> composicaoFamiliar = const [],
    List<Map<String, dynamic>> condicoesTrabalho = const [],
    List<Map<String, dynamic>> condicoesEducacionais = const [],
    List<Map<String, dynamic>> deficienciasFamilia = const [],
    List<Map<String, dynamic>> gestantesFamilia = const [],
    Map<String, dynamic>? programasSociais,
    Map<String, dynamic>? saudeFamilia,
  }) =>
      {
        'pessoaId': pessoaId,
        'dataEntrevista': dataEntrevista,
        'formasAcesso': formasAcesso,
        if (outrosTexto != null && outrosTexto.trim().isNotEmpty)
          'outrosTexto': outrosTexto.trim(),
        'composicaoFamiliar': composicaoFamiliar,
        'condicoesTrabalho': condicoesTrabalho,
        'condicoesEducacionais': condicoesEducacionais,
        'deficienciasFamilia': deficienciasFamilia,
        'gestantesFamilia': gestantesFamilia,
        'programasSociais': programasSociais ?? {},
        'saudeFamilia': saudeFamilia ?? {},
      };
}
