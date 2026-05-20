import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/permissao.dart';
import '../../models/usuario.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/permissoes_editor.dart';

class LiberacaoUsuarioScreen extends ConsumerStatefulWidget {
  const LiberacaoUsuarioScreen({super.key});

  @override
  ConsumerState<LiberacaoUsuarioScreen> createState() =>
      _LiberacaoUsuarioScreenState();
}

class _LiberacaoUsuarioScreenState extends ConsumerState<LiberacaoUsuarioScreen> {
  List<Usuario> _usuarios = [];
  Usuario? _selected;
  List<PermissaoLinha> _linhas = [];
  bool _loadingUsuarios = true;
  bool _loadingPerm = false;
  bool _saving = false;
  bool _adminTotal = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    try {
      final usuarios = await ref.read(apiClientProvider).listUsuarios();
      if (mounted) {
        setState(() {
          _usuarios = usuarios;
          _loadingUsuarios = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUsuarios = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _loadPermissoes(Usuario usuario) async {
    setState(() {
      _loadingPerm = true;
      _selected = usuario;
    });
    try {
      final linhas =
          await ref.read(apiClientProvider).getPermissoesUsuario(usuario.id);
      if (mounted) {
        setState(() {
          _linhas = linhas;
          _adminTotal =
              linhas.isNotEmpty && linhas.first.perfilAdmin;
          _loadingPerm = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPerm = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    if (!ref.read(authProvider).podeAlterar(Programas.liberacaoUsuario)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).setPermissoesUsuario(
            _selected!.id,
            _linhas,
          );
      if (mounted) showSuccessSnackBar(context, 'Permissões salvas');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final podeAlterar =
        ref.watch(authProvider).podeAlterar(Programas.liberacaoUsuario);

    return PermissaoGate(
      programaCodigo: Programas.liberacaoUsuario,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Liberação por usuário',
        ),
        body: _loadingUsuarios
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppLayout.screenPadding,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selected?.id,
                    decoration: const InputDecoration(labelText: 'Usuário'),
                    items: _usuarios
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.nome} (@${u.nomeUsuario})'),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      final u = _usuarios.where((x) => x.id == id).firstOrNull;
                      if (u != null) _loadPermissoes(u);
                    },
                  ),
                  if (_loadingPerm) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_selected != null && !_loadingPerm) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: PermissoesEditor(
                        linhas: _linhas,
                        adminTotal: _adminTotal,
                        readOnly: !podeAlterar || _adminTotal,
                        onChanged: (index, linha) {
                          setState(() => _linhas[index] = linha);
                        },
                      ),
                    ),
                    if (podeAlterar && !_adminTotal) ...[
                      const SizedBox(height: 24),
                      AppButton(
                        label: _saving ? 'Salvando...' : 'Salvar permissões',
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}
