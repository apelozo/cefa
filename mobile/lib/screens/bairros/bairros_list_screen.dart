import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/bairro.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'bairro_form_screen.dart';

class BairrosListScreen extends ConsumerStatefulWidget {
  const BairrosListScreen({super.key});

  @override
  ConsumerState<BairrosListScreen> createState() => _BairrosListScreenState();
}

class _BairrosListScreenState extends ConsumerState<BairrosListScreen> {
  List<Bairro>? _bairros;
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
      final items = await ref.read(apiClientProvider).listBairros(
            ativo: _mostrarInativos ? null : true,
          );
      if (mounted) setState(() => _bairros = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Bairro? bairro]) async {
    final auth = ref.read(authProvider);
    if (bairro == null && !auth.podeIncluir(Programas.bairros)) return;
    if (bairro != null && !auth.podeAlterar(Programas.bairros)) return;
    if (bairro != null && !bairro.ativo) {
      showErrorSnackBar(context, 'Bairro desativado não pode ser editado.');
      return;
    }

    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => BairroFormScreen(bairro: bairro),
      ),
    );
    if (saved == true || saved is Bairro) _load();
  }

  Future<void> _softDelete(Bairro bairro) async {
    if (!ref.read(authProvider).podeExcluir(Programas.bairros)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar bairro?'),
        content: Text(
          '"${bairro.codigo} — ${bairro.nome}" será desativado.\n\n'
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
      await ref.read(apiClientProvider).softDeleteBairro(bairro.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Bairro desativado');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.bairros);
    final podeAlterar = auth.podeAlterar(Programas.bairros);
    final podeExcluir = auth.podeExcluir(Programas.bairros);

    return PermissaoGate(
      programaCodigo: Programas.bairros,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Bairros',
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
            : _bairros == null || _bairros!.isEmpty
                ? Center(
                    child: Padding(
                      padding: AppLayout.screenPadding,
                      child: Text(
                        _mostrarInativos
                            ? 'Nenhum bairro cadastrado.'
                            : 'Nenhum bairro ativo.\nAtive "Inativos" para ver desativados.',
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
                      itemCount: _bairros!.length,
                      itemBuilder: (context, index) {
                        final b = _bairros![index];
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
                                      b.codigo.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      b.nome,
                                      style:
                                          Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  if (!b.ativo)
                                    Text(
                                      'Inativo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              RecordActionButtons(
                                onEdit: podeAlterar && b.ativo
                                    ? () => _openForm(b)
                                    : null,
                                onDelete: podeExcluir && b.ativo
                                    ? () => _softDelete(b)
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
