import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/permissao.dart';
import '../../models/programa.dart';
import '../../models/tipo_usuario.dart';
import '../../models/tipos_formulario_acesso.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/permissao_linhas_merge.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/permissoes_editor.dart';
import '../../widgets/tipos_formulario_acesso_editor.dart';

class LiberacaoTipoUsuarioScreen extends ConsumerStatefulWidget {
  const LiberacaoTipoUsuarioScreen({super.key});

  @override
  ConsumerState<LiberacaoTipoUsuarioScreen> createState() =>
      _LiberacaoTipoUsuarioScreenState();
}

class _LiberacaoTipoUsuarioScreenState
    extends ConsumerState<LiberacaoTipoUsuarioScreen>
    with SingleTickerProviderStateMixin {
  List<TipoUsuario> _tipos = [];
  TipoUsuario? _selected;
  List<PermissaoLinha> _linhas = [];
  List<TipoFormularioAcessoLinha> _tiposFormulario = [];
  bool _loadingTipos = true;
  bool _loadingPerm = false;
  bool _saving = false;
  bool _adminTotal = false;
  bool _acessoTotalTipos = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadTipos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.getPermissoesTipoUsuario(tipo.id),
        api.listProgramas(),
        api.getTiposFormularioAcessoTipoUsuario(tipo.id),
      ]);
      final linhas = mergePermissaoLinhasComProgramas(
        results[0] as List<PermissaoLinha>,
        results[1] as List<Programa>,
      );
      final acessoTipos = results[2] as TiposFormularioAcessoResumo;
      if (mounted) {
        setState(() {
          _linhas = linhas;
          _adminTotal =
              linhas.isNotEmpty && linhas.first.perfilAdmin;
          _acessoTotalTipos = acessoTipos.acessoTotal;
          _tiposFormulario = acessoTipos.tipos;
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
      final api = ref.read(apiClientProvider);
      if (_tabController.index == 0) {
        await api.setPermissoesTipoUsuario(_selected!.id, _linhas);
        if (mounted) showSuccessSnackBar(context, 'Permissões de programas salvas');
      } else {
        final resumo = await api.setTiposFormularioAcessoTipoUsuario(
          _selected!.id,
          _tiposFormulario.where((t) => t.liberado).map((t) => t.id).toList(),
        );
        if (mounted) {
          setState(() {
            _tiposFormulario = resumo.tipos;
            _acessoTotalTipos = resumo.acessoTotal;
          });
          showSuccessSnackBar(context, 'Tipos de formulário salvos');
        }
      }
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
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Programas'),
                        Tab(text: 'Tipos de formulário'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          if (_tabController.index == 0) {
                            return PermissoesEditor(
                              linhas: _linhas,
                              adminTotal: _adminTotal,
                              readOnly: !podeAlterar || _adminTotal,
                              onChanged: (index, linha) {
                                setState(() => _linhas[index] = linha);
                              },
                            );
                          }
                          return TiposFormularioAcessoEditor(
                            tipos: _tiposFormulario,
                            acessoTotal: _acessoTotalTipos,
                            readOnly:
                                !podeAlterar || _acessoTotalTipos || _adminTotal,
                            onChanged: (index, linha) {
                              setState(() => _tiposFormulario[index] = linha);
                            },
                          );
                        },
                      ),
                    ),
                    if (podeAlterar && !_adminTotal) ...[
                      const SizedBox(height: 24),
                      AppButton(
                        label: _saving
                            ? 'Salvando...'
                            : _tabController.index == 0
                                ? 'Salvar programas'
                                : 'Salvar tipos de formulário',
                        onPressed: (_saving ||
                                (_tabController.index == 1 &&
                                    _acessoTotalTipos))
                            ? null
                            : _save,
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}
