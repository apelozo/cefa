import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/tipo_formulario.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'tipo_formulario_form_screen.dart';

class TiposFormularioListScreen extends ConsumerStatefulWidget {
  const TiposFormularioListScreen({super.key});

  @override
  ConsumerState<TiposFormularioListScreen> createState() =>
      _TiposFormularioListScreenState();
}

class _TiposFormularioListScreenState
    extends ConsumerState<TiposFormularioListScreen> {
  List<TipoFormulario>? _tipos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items =
          await ref.read(apiClientProvider).listTiposFormulario(todos: true);
      if (mounted) setState(() => _tipos = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([TipoFormulario? tipo]) async {
    final auth = ref.read(authProvider);
    if (tipo == null && !auth.podeIncluir(Programas.tiposFormulario)) return;
    if (tipo != null && !auth.podeAlterar(Programas.tiposFormulario)) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TipoFormularioFormScreen(tipo: tipo),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(TipoFormulario tipo) async {
    if (!ref.read(authProvider).podeExcluir(Programas.tiposFormulario)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tipo de formulário?'),
        content: Text(
          '"${tipo.nome}" será removido permanentemente do banco.\n\n'
          'Não é possível excluir se houver perguntas ou lançamentos vinculados.',
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
      await ref.read(apiClientProvider).deleteTipoFormulario(tipo.id);
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
    final podeIncluir = auth.podeIncluir(Programas.tiposFormulario);
    final podeAlterar = auth.podeAlterar(Programas.tiposFormulario);
    final podeExcluir = auth.podeExcluir(Programas.tiposFormulario);

    return PermissaoGate(
      programaCodigo: Programas.tiposFormulario,
      child: AppScaffold(
      appBar: AppScreenChrome.appBar(context, title: 'Tipos de formulário'),
      floatingActionButton: podeIncluir
          ? FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tipos == null || _tipos!.isEmpty
              ? Center(
                  child: Padding(
                    padding: AppLayout.screenPadding,
                    child: Text(
                      'Nenhum tipo cadastrado.\nCrie um antes de vincular às perguntas.',
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
                    itemCount: _tipos!.length,
                    itemBuilder: (context, index) {
                      final t = _tipos![index];
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.nome,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                if (!t.ativo)
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
                            if (t.descricao != null &&
                                t.descricao!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                t.descricao!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.neutralGray),
                              ),
                            ],
                            const SizedBox(height: 12),
                            RecordActionButtons(
                              onEdit: podeAlterar ? () => _openForm(t) : null,
                              onDelete: podeExcluir ? () => _delete(t) : null,
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
