import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/relatorio_submodulo.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'relatorio_submodulo_form_screen.dart';

class RelatorioSubmodulosListScreen extends ConsumerStatefulWidget {
  const RelatorioSubmodulosListScreen({super.key});

  @override
  ConsumerState<RelatorioSubmodulosListScreen> createState() =>
      _RelatorioSubmodulosListScreenState();
}

class _RelatorioSubmodulosListScreenState
    extends ConsumerState<RelatorioSubmodulosListScreen> {
  List<RelatorioSubmodulo>? _items;
  bool _loading = true;
  bool _mostrarInativos = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listRelatorioSubmodulos(
            ativo: _mostrarInativos ? null : true,
          );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([RelatorioSubmodulo? item]) async {
    final auth = ref.read(authProvider);
    if (item == null && !auth.podeIncluir(Programas.relatorioSubmodulos)) {
      return;
    }
    if (item != null && !auth.podeAlterar(Programas.relatorioSubmodulos)) {
      return;
    }

    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => RelatorioSubmoduloFormScreen(submodulo: item),
      ),
    );
    if (saved == true || saved is RelatorioSubmodulo) _load();
  }

  Future<void> _delete(RelatorioSubmodulo item) async {
    if (!ref.read(authProvider).podeExcluir(Programas.relatorioSubmodulos)) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir submódulo?'),
        content: Text(
          '"${item.codigo} — ${item.nome}" será excluído permanentemente.\n\n'
          'Só é possível excluir quando não houver programas vinculados.',
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
      await ref.read(apiClientProvider).deleteRelatorioSubmodulo(item.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Submódulo excluído');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.relatorioSubmodulos);
    final podeAlterar = auth.podeAlterar(Programas.relatorioSubmodulos);
    final podeExcluir = auth.podeExcluir(Programas.relatorioSubmodulos);

    return PermissaoGate(
      programaCodigo: Programas.relatorioSubmodulos,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Submódulos de relatórios',
          actions: [
            FilterChip(
              label: const Text('Inativos'),
              selected: _mostrarInativos,
              onSelected: _loading
                  ? null
                  : (v) {
                      setState(() => _mostrarInativos = v);
                      _load();
                    },
            ),
            const SizedBox(width: 8),
          ],
        ),
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
                        _mostrarInativos
                            ? 'Nenhum submódulo cadastrado.'
                            : 'Nenhum submódulo ativo.\nAtive "Inativos" para ver desativados.',
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
                        final s = _items![index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.codigo,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!s.ativo)
                                    Chip(
                                      label: Text(
                                        'Inativo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  const Spacer(),
                                  Text(
                                    'Ordem ${s.ordem}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.slate),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.nome,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (s.descricao != null &&
                                  s.descricao!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  s.descricao!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.neutralGray),
                                ),
                              ],
                              const SizedBox(height: 12),
                              RecordActionButtons(
                                onEdit: podeAlterar && s.ativo
                                    ? () => _openForm(s)
                                    : null,
                                onDelete: podeExcluir && s.ativo
                                    ? () => _delete(s)
                                    : null,
                              ),
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
