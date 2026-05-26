import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/escolaridade.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'escolaridade_form_screen.dart';

class EscolaridadesListScreen extends ConsumerStatefulWidget {
  const EscolaridadesListScreen({super.key});

  @override
  ConsumerState<EscolaridadesListScreen> createState() =>
      _EscolaridadesListScreenState();
}

class _EscolaridadesListScreenState
    extends ConsumerState<EscolaridadesListScreen> {
  List<Escolaridade>? _escolaridades;
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
      final items = await ref.read(apiClientProvider).listEscolaridades(
            ativo: _mostrarInativos ? null : true,
          );
      if (mounted) setState(() => _escolaridades = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Escolaridade? escolaridade]) async {
    final auth = ref.read(authProvider);
    if (escolaridade == null && !auth.podeIncluir(Programas.escolaridades)) {
      return;
    }
    if (escolaridade != null && !auth.podeAlterar(Programas.escolaridades)) {
      return;
    }
    if (escolaridade != null && !escolaridade.ativo) {
      showErrorSnackBar(
        context,
        'Escolaridade desativada não pode ser editada.',
      );
      return;
    }

    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => EscolaridadeFormScreen(escolaridade: escolaridade),
      ),
    );
    if (saved == true || saved is Escolaridade) _load();
  }

  Future<void> _softDelete(Escolaridade escolaridade) async {
    if (!ref.read(authProvider).podeExcluir(Programas.escolaridades)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar escolaridade?'),
        content: Text(
          '"${escolaridade.codigo} — ${escolaridade.descricao}" será desativada.\n\n'
          'O registro permanece no banco (soft delete). Entrevistas já gravadas '
          'mantêm a referência.',
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
      await ref
          .read(apiClientProvider)
          .softDeleteEscolaridade(escolaridade.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Escolaridade desativada');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.escolaridades);
    final podeAlterar = auth.podeAlterar(Programas.escolaridades);
    final podeExcluir = auth.podeExcluir(Programas.escolaridades);

    return PermissaoGate(
      programaCodigo: Programas.escolaridades,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Escolaridades',
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
            : _escolaridades == null || _escolaridades!.isEmpty
                ? Center(
                    child: Padding(
                      padding: AppLayout.screenPadding,
                      child: Text(
                        _mostrarInativos
                            ? 'Nenhuma escolaridade cadastrada.'
                            : 'Nenhuma escolaridade ativa.\nAtive "Inativos" para ver desativadas.',
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
                      itemCount: _escolaridades!.length,
                      itemBuilder: (context, index) {
                        final e = _escolaridades![index];
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
                                      e.codigo.toString(),
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
                                      e.descricao,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  if (!e.ativo)
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
                                onEdit: podeAlterar && e.ativo
                                    ? () => _openForm(e)
                                    : null,
                                onDelete: podeExcluir && e.ativo
                                    ? () => _softDelete(e)
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
