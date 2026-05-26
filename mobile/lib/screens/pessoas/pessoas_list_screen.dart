import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/pessoa.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pessoa_tile.dart';
import 'pessoas_search_args.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'pessoa_form_screen.dart';
import 'pessoas_search_screen.dart';

class PessoasListScreen extends ConsumerStatefulWidget {
  const PessoasListScreen({super.key});

  @override
  ConsumerState<PessoasListScreen> createState() => _PessoasListScreenState();
}

class _PessoasListScreenState extends ConsumerState<PessoasListScreen> {
  List<Pessoa>? _pessoas;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listPessoas();
      if (mounted) setState(() => _pessoas = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Pessoa? pessoa]) async {
    final auth = ref.read(authProvider);
    if (pessoa == null && !auth.podeIncluir(Programas.pessoas)) return;
    if (pessoa != null && !auth.podeAlterar(Programas.pessoas)) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PessoaFormScreen(pessoa: pessoa),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Pessoa pessoa) async {
    if (!ref.read(authProvider).podeExcluir(Programas.pessoas)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir assistido?'),
        content: Text(
          '"${pessoa.nome}" será removido permanentemente do banco.\n\n'
          'Não é possível excluir se houver lançamentos vinculados.',
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
      await ref.read(apiClientProvider).deletePessoa(pessoa.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Assistido excluído');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.pessoas);
    final podeAlterar = auth.podeAlterar(Programas.pessoas);
    final podeExcluir = auth.podeExcluir(Programas.pessoas);

    return PermissaoGate(
      programaCodigo: Programas.pessoas,
      child: AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: 'Assistidos',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Pesquisar',
            onPressed: () async {
              final selected = await PessoasSearchScreen.select(
                context,
                args: const PessoasSearchArgs(onlyAtivas: false),
              );
              if (selected != null && podeAlterar) _openForm(selected);
            },
          ),
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
          : _pessoas == null || _pessoas!.isEmpty
              ? Center(
                  child: Padding(
                    padding: AppLayout.screenPadding,
                    child: Text(
                      'Nenhum assistido cadastrado.\nCadastre antes de fazer lançamentos.',
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
                    itemCount: _pessoas!.length,
                    itemBuilder: (context, index) {
                      final p = _pessoas![index];
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PessoaTileBody(pessoa: p, showChevron: false),
                            const SizedBox(height: 12),
                            RecordActionButtons(
                              onEdit: podeAlterar ? () => _openForm(p) : null,
                              onDelete: podeExcluir ? () => _delete(p) : null,
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
