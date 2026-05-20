import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/permissao.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';

class AuthState {
  const AuthState({
    this.token,
    this.usuario,
    this.permissoes = const {},
    this.loading = true,
  });

  final String? token;
  final Usuario? usuario;
  final Map<String, ProgramaPermissao> permissoes;
  final bool loading;

  bool get isAuthenticated => token != null && usuario != null;

  AuthState copyWith({
    String? token,
    Usuario? usuario,
    Map<String, ProgramaPermissao>? permissoes,
    bool? loading,
    bool clearSession = false,
  }) {
    if (clearSession) {
      return const AuthState(loading: false);
    }
    return AuthState(
      token: token ?? this.token,
      usuario: usuario ?? this.usuario,
      permissoes: permissoes ?? this.permissoes,
      loading: loading ?? this.loading,
    );
  }

  ProgramaPermissao permissao(String codigo) =>
      permissoes[codigo] ?? ProgramaPermissao.nenhuma;

  bool podeConsultar(String codigo) =>
      isAdmin || permissao(codigo).podeConsultar;
  bool podeIncluir(String codigo) => isAdmin || permissao(codigo).podeIncluir;
  bool podeAlterar(String codigo) => isAdmin || permissao(codigo).podeAlterar;
  bool podeExcluir(String codigo) => isAdmin || permissao(codigo).podeExcluir;

  /// Exibir menu / entrar na tela quando houver qualquer permissão no programa.
  bool podeAcessar(String codigo) => isAdmin || permissao(codigo).temAcesso;

  bool get isAdmin => usuario?.isAdmin ?? false;

  bool podeConsultarAlgumAdmin() {
    if (isAdmin) return true;
    const codigos = [
      'tipos_usuario',
      'usuarios',
      'liberacao_tipo_usuario',
      'liberacao_usuario',
    ];
    return codigos.any(podeAcessar);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._storage) : super(const AuthState()) {
    _restore();
  }

  final ApiClient _api;
  final AuthStorage _storage;

  Future<void> _restore() async {
    final token = await _storage.readToken();
    if (token == null) {
      state = state.copyWith(loading: false, clearSession: true);
      return;
    }
    _api.setToken(token);
    try {
      final me = await _api.getAuthMe();
      state = AuthState(
        token: token,
        usuario: me.usuario,
        permissoes: me.permissoes,
        loading: false,
      );
    } catch (_) {
      await _storage.clearToken();
      _api.setToken(null);
      state = state.copyWith(loading: false, clearSession: true);
    }
  }

  Future<void> login(String nomeUsuario, String senha) async {
    final result = await _api.login(nomeUsuario, senha);
    await _storage.saveToken(result.token);
    _api.setToken(result.token);
    state = AuthState(
      token: result.token,
      usuario: result.usuario,
      permissoes: result.permissoes,
      loading: false,
    );
  }

  Future<void> logout() async {
    await _storage.clearToken();
    _api.setToken(null);
    state = state.copyWith(clearSession: true);
  }

  void handleUnauthorized() {
    logout();
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final notifier = AuthNotifier(api, ref.watch(authStorageProvider));
  api.onUnauthorized = notifier.handleUnauthorized;
  return notifier;
});
