import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/cidade.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'cidade_form_screen.dart';

class CidadesListScreen extends ConsumerStatefulWidget {
  const CidadesListScreen({super.key});

  @override
  ConsumerState<CidadesListScreen> createState() => _CidadesListScreenState();
}

class _CidadesListScreenState extends ConsumerState<CidadesListScreen> {
  List<Cidade>? _cidades;
  bool _loading = true;
  bool _mostrarInativas = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listCidades(
            ativo: _mostrarInativas ? null : true,
          );
      if (mounted) setState(() => _cidades = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Cidade? cidade]) async {
    final auth = ref.read(authProvider);
    if (cidade == null && !auth.podeIncluir(Programas.cidades)) return;
    if (cidade != null && !auth.podeAlterar(Programas.cidades)) return;
    if (cidade != null && !cidade.ativo) {
      showErrorSnackBar(context, 'Cidade desativada não pode ser editada.');
      return;
    }

    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => CidadeFormScreen(cidade: cidade),
      ),
    );
    if (saved == true || saved is Cidade) _load();
  }

  Future<void> _softDelete(Cidade cidade) async {
    if (!ref.read(authProvider).podeExcluir(Programas.cidades)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar cidade?'),
        content: Text(
          '"${cidade.nomeMunicipio} - ${cidade.estado}" será desativada.\n\n'
          'O registro permanece no banco (soft delete), com usuário e data/hora da desativação.',
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
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(apiClientProvider).softDeleteCidade(cidade.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Cidade desativada');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.cidades);
    final podeAlterar = auth.podeAlterar(Programas.cidades);
    final podeExcluir = auth.podeExcluir(Programas.cidades);

    return PermissaoGate(
      programaCodigo: Programas.cidades,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Cidades',
          actions: [
            FilterChip(
              label: const Text('Inativas'),
              selected: _mostrarInativas,
              onSelected: _loading
                  ? null
                  : (v) {
                      setState(() => _mostrarInativas = v);
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
                label: const Text('Nova'),
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _cidades == null || _cidades!.isEmpty
                ? Center(
                    child: Padding(
                      padding: AppLayout.screenPadding,
                      child: Text(
                        _mostrarInativas
                            ? 'Nenhuma cidade cadastrada.'
                            : 'Nenhuma cidade ativa.\nAtive "Inativas" para ver desativadas.',
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
                      itemCount: _cidades!.length,
                      itemBuilder: (context, index) {
                        final c = _cidades![index];
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
                                      c.codigo.toString(),
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
                                  Expanded(
                                    child: Text(
                                      c.nomeMunicipio,
                                      style:
                                          Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
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
                                      c.estado,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  if (!c.ativo) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Inativa',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              RecordActionButtons(
                                onEdit: podeAlterar && c.ativo
                                    ? () => _openForm(c)
                                    : null,
                                onDelete: podeExcluir && c.ativo
                                    ? () => _softDelete(c)
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
