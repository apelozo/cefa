import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/modulo_sistema.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'modulo_sistema_form_screen.dart';

class ModulosSistemaListScreen extends ConsumerStatefulWidget {
  const ModulosSistemaListScreen({super.key});

  @override
  ConsumerState<ModulosSistemaListScreen> createState() =>
      _ModulosSistemaListScreenState();
}

class _ModulosSistemaListScreenState
    extends ConsumerState<ModulosSistemaListScreen> {
  List<ModuloSistema>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listModulosSistema();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([ModuloSistema? item]) async {
    final auth = ref.read(authProvider);
    if (item == null && !auth.podeIncluir(Programas.modulosSistema)) return;
    if (item != null && !auth.podeAlterar(Programas.modulosSistema)) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ModuloSistemaFormScreen(modulo: item),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(ModuloSistema item) async {
    if (!ref.read(authProvider).podeExcluir(Programas.modulosSistema)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir módulo?'),
        content: Text(
          '"${item.nome}" será removido permanentemente.\n\n'
          'Não é possível excluir se houver programas vinculados.',
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
      await ref.read(apiClientProvider).deleteModuloSistema(item.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Módulo excluído');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.modulosSistema);
    final podeAlterar = auth.podeAlterar(Programas.modulosSistema);
    final podeExcluir = auth.podeExcluir(Programas.modulosSistema);

    return PermissaoGate(
      programaCodigo: Programas.modulosSistema,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(context, title: 'Módulos do sistema'),
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
                        'Nenhum módulo cadastrado.',
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
                        final m = _items![index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.nome,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Código: ${m.codigo} · Ordem: ${m.ordem}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.neutralGray),
                              ),
                              if (m.descricao != null &&
                                  m.descricao!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  m.descricao!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              if (m.programas.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${m.programas.length} programa(s) vinculado(s)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: AppColors.primaryBlue,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                              if (!m.ativo) ...[
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
                                  onEdit:
                                      podeAlterar ? () => _openForm(m) : null,
                                  onDelete:
                                      podeExcluir ? () => _delete(m) : null,
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
