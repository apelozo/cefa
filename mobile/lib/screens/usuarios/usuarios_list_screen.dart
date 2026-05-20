import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/usuario.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'usuario_form_screen.dart';

class UsuariosListScreen extends ConsumerStatefulWidget {
  const UsuariosListScreen({super.key});

  @override
  ConsumerState<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends ConsumerState<UsuariosListScreen> {
  List<Usuario>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listUsuarios();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Usuario? item]) async {
    final auth = ref.read(authProvider);
    if (item == null && !auth.podeIncluir(Programas.usuarios)) return;
    if (item != null && !auth.podeAlterar(Programas.usuarios)) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UsuarioFormScreen(usuario: item)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Usuario item) async {
    if (!ref.read(authProvider).podeExcluir(Programas.usuarios)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir usuário?'),
        content: Text(
          '"${item.nome}" será removido permanentemente.',
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
      await ref.read(apiClientProvider).deleteUsuario(item.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Usuário excluído');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.usuarios);
    final podeAlterar = auth.podeAlterar(Programas.usuarios);
    final podeExcluir = auth.podeExcluir(Programas.usuarios);

    return PermissaoGate(
      programaCodigo: Programas.usuarios,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(context, title: 'Usuários'),
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
                        'Nenhum usuário cadastrado.',
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
                        final u = _items![index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.nome,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${u.nomeUsuario} · ${u.email}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.neutralGray),
                              ),
                              Text(
                                u.tipoUsuario.descricao,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.neutralGray),
                              ),
                              if (!u.ativo) ...[
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
                                  onEdit: podeAlterar ? () => _openForm(u) : null,
                                  onDelete: podeExcluir ? () => _delete(u) : null,
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
