import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/entrevista_assistido.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'entrevista_assistido_screen.dart';

class EntrevistasAssistidoListScreen extends ConsumerStatefulWidget {
  const EntrevistasAssistidoListScreen({super.key});

  @override
  ConsumerState<EntrevistasAssistidoListScreen> createState() =>
      _EntrevistasAssistidoListScreenState();
}

class _EntrevistasAssistidoListScreenState
    extends ConsumerState<EntrevistasAssistidoListScreen> {
  List<EntrevistaAssistidoResumo>? _items;
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  late final FormEnterFocus _enterFocus;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(2);
    _load();
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listEntrevistasAssistido(
            nome: _nomeController.text.trim().isNotEmpty
                ? _nomeController.text.trim()
                : null,
            cpf: _cpfController.text.trim().isNotEmpty
                ? _cpfController.text.trim()
                : null,
          );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({
    String? entrevistaId,
    bool readOnly = false,
  }) async {
    final auth = ref.read(authProvider);
    if (entrevistaId == null && !auth.podeIncluir(Programas.entrevistaAssistido)) {
      return;
    }
    if (entrevistaId != null &&
        !readOnly &&
        !auth.podeAlterar(Programas.entrevistaAssistido)) {
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntrevistaAssistidoScreen(
          entrevistaId: entrevistaId,
          readOnly: readOnly,
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(EntrevistaAssistidoResumo item) async {
    if (!ref.read(authProvider).podeExcluir(Programas.entrevistaAssistido)) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir entrevista?'),
        content: Text(
          'A entrevista de ${item.pessoaNome} em ${item.dataEntrevista} '
          'será removida permanentemente.',
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
      await ref.read(apiClientProvider).deleteEntrevistaAssistido(item.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Entrevista excluída');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.entrevistaAssistido);
    final podeAlterar = auth.podeAlterar(Programas.entrevistaAssistido);
    final podeExcluir = auth.podeExcluir(Programas.entrevistaAssistido);
    final podeConsultar = auth.podeConsultar(Programas.entrevistaAssistido);

    return PermissaoGate(
      programaCodigo: Programas.entrevistaAssistido,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Entrevista com o Assistido',
        ),
        floatingActionButton: podeIncluir
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Nova'),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                AppLayout.screenPaddingTop,
                AppLayout.screenPaddingH,
                0,
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    focusNode: _enterFocus.fields[0],
                    textInputAction: _enterFocus.inputAction(0),
                    onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
                    decoration: const InputDecoration(
                      labelText: 'Nome do assistido',
                      prefixIcon: Icon(Icons.person_search),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cpfController,
                    focusNode: _enterFocus.fields[1],
                    textInputAction: _enterFocus.inputAction(1),
                    onFieldSubmitted: (_) => _enterFocus.onSubmitted(1),
                  onEditingComplete: _enterFocus.editingComplete(1),
                    decoration: const InputDecoration(
                      labelText: 'CPF do assistido',
                      hintText: '000.000.000-00',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfFormatter()],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Buscar',
                    focusNode: _enterFocus.submitFocusNode,
                    onPressed: _loading ? null : _load,
                    loading: _loading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList(podeAlterar, podeExcluir, podeConsultar)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    bool podeAlterar,
    bool podeExcluir,
    bool podeConsultar,
  ) {
    if (_loading && _items == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items == null) {
      return const SizedBox.shrink();
    }

    if (_items!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            'Nenhuma entrevista encontrada.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.screenPaddingH,
          0,
          AppLayout.screenPaddingH,
          88,
        ),
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final e = _items![index];
          return AppCard(
            onTap: podeConsultar
                ? () => _openForm(entrevistaId: e.id, readOnly: true)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.pessoaNome,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'CPF: ${e.pessoaCpfFormatado}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutralGray,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data da entrevista: ${e.dataEntrevista}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${e.totalFormasAcesso} forma(s) de acesso · '
                  '${e.totalComposicaoFamiliar} na composição · '
                  '${e.totalCondicoesTrabalho} em trabalho/renda · '
                  '${e.totalCondicoesEducacionais} em educação · '
                  '${e.totalDeficienciasFamilia} em saúde',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutralGray,
                      ),
                ),
                const SizedBox(height: 12),
                RecordActionButtons(
                  onEdit: podeAlterar
                      ? () => _openForm(entrevistaId: e.id)
                      : null,
                  onDelete: podeExcluir ? () => _delete(e) : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
