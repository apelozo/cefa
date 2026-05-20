import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/permissao.dart';
import '../../models/tipo_usuario.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/permissoes_editor.dart';

class LiberacaoTipoUsuarioScreen extends ConsumerStatefulWidget {
  const LiberacaoTipoUsuarioScreen({super.key});

  @override
  ConsumerState<LiberacaoTipoUsuarioScreen> createState() =>
      _LiberacaoTipoUsuarioScreenState();
}

class _LiberacaoTipoUsuarioScreenState
    extends ConsumerState<LiberacaoTipoUsuarioScreen> {
  List<TipoUsuario> _tipos = [];
  TipoUsuario? _selected;
  List<PermissaoLinha> _linhas = [];
  bool _loadingTipos = true;
  bool _loadingPerm = false;
  bool _saving = false;
  bool _adminTotal = false;

  @override
  void initState() {
    super.initState();
    _loadTipos();
  }

  Future<void> _loadTipos() async {
    try {
      final tipos = await ref.read(apiClientProvider).listTiposUsuario();
      if (mounted) {
        setState(() {
          _tipos = tipos;
          _loadingTipos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTipos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _loadPermissoes(TipoUsuario tipo) async {
    setState(() {
      _loadingPerm = true;
      _selected = tipo;
    });
    try {
      final linhas =
          await ref.read(apiClientProvider).getPermissoesTipoUsuario(tipo.id);
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
    if (!ref.read(authProvider).podeAlterar(Programas.liberacaoTipoUsuario)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).setPermissoesTipoUsuario(
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
        ref.watch(authProvider).podeAlterar(Programas.liberacaoTipoUsuario);

    return PermissaoGate(
      programaCodigo: Programas.liberacaoTipoUsuario,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Liberação por tipo',
        ),
        body: _loadingTipos
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppLayout.screenPadding,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selected?.id,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de usuário',
                    ),
                    items: _tipos
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.descricao),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      final tipo = _tipos.where((t) => t.id == id).firstOrNull;
                      if (tipo != null) _loadPermissoes(tipo);
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
