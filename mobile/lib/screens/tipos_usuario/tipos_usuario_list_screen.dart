import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/tipo_usuario.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'tipo_usuario_form_screen.dart';

class TiposUsuarioListScreen extends ConsumerStatefulWidget {
  const TiposUsuarioListScreen({super.key});

  @override
  ConsumerState<TiposUsuarioListScreen> createState() =>
      _TiposUsuarioListScreenState();
}

class _TiposUsuarioListScreenState extends ConsumerState<TiposUsuarioListScreen> {
  List<TipoUsuario>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listTiposUsuario();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([TipoUsuario? item]) async {
    final auth = ref.read(authProvider);
    if (item == null && !auth.podeIncluir(Programas.tiposUsuario)) return;
    if (item != null && !auth.podeAlterar(Programas.tiposUsuario)) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TipoUsuarioFormScreen(tipo: item),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(TipoUsuario item) async {
    if (!ref.read(authProvider).podeExcluir(Programas.tiposUsuario)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tipo de usuário?'),
        content: Text(
          '"${item.descricao}" será removido permanentemente.\n\n'
          'Não é possível excluir se houver usuários vinculados.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(apiClientProvider).deleteTipoUsuario(item.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Tipo excluído');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.tiposUsuario);
    final podeAlterar = auth.podeAlterar(Programas.tiposUsuario);
    final podeExcluir = auth.podeExcluir(Programas.tiposUsuario);

    return PermissaoGate(
      programaCodigo: Programas.tiposUsuario,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(context, title: 'Tipos de usuário'),
        floatingActionButton: podeIncluir
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items == null || _items!.isEmpty
                ? Center(
                    child: Padding(
                      padding: AppLayout.screenPadding,
                      child: Text(
                        'Nenhum tipo cadastrado.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accentOrange,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        AppLayout.screenPaddingTop,
                        AppLayout.screenPaddingH,
                        88,
                      ),
                      itemCount: _items!.length,
                      itemBuilder: (context, index) {
                        final t = _items![index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.descricao,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                perfilLabel(t.perfil),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.neutralGray),
                              ),
                              if (!t.ativo) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Inativo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: Colors.red, fontSize: 12),
                                ),
                              ],
                              if (podeAlterar || podeExcluir) ...[
                                const SizedBox(height: 12),
                                RecordActionButtons(
                                  onEdit: podeAlterar ? () => _openForm(t) : null,
                                  onDelete: podeExcluir ? () => _delete(t) : null,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
