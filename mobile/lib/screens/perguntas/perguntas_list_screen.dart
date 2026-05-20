import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/pergunta.dart';
import '../../models/tipo_campo.dart';
import '../../models/tipo_formulario.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'pergunta_form_screen.dart';

class PerguntasListScreen extends ConsumerStatefulWidget {
  const PerguntasListScreen({super.key});

  @override
  ConsumerState<PerguntasListScreen> createState() =>
      _PerguntasListScreenState();
}

class _PerguntasListScreenState extends ConsumerState<PerguntasListScreen> {
  List<TipoFormulario> _tipos = [];
  List<Pergunta>? _perguntas;
  String? _tipoFormularioId;
  bool _loadingTipos = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadTipos();
    if (mounted) await _load();
  }

  Future<void> _loadTipos() async {
    try {
      final tipos = await ref.read(apiClientProvider).listTiposFormulario();
      if (mounted) {
        setState(() {
          _tipos = tipos;
          _loadingTipos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTipos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listPerguntas(
            tipoFormularioId: _tipoFormularioId,
          );
      if (mounted) setState(() => _perguntas = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTipoChanged(String? tipoId) {
    setState(() {
      _tipoFormularioId = tipoId;
      _perguntas = null;
    });
    _load();
  }

  Future<void> _openForm([Pergunta? pergunta]) async {
    final auth = ref.read(authProvider);
    if (pergunta == null && !auth.podeIncluir(Programas.perguntas)) return;
    if (pergunta != null && !auth.podeAlterar(Programas.perguntas)) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PerguntaFormScreen(pergunta: pergunta),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Pergunta pergunta) async {
    if (!ref.read(authProvider).podeExcluir(Programas.perguntas)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir pergunta?'),
        content: Text(
          'A pergunta "${pergunta.enunciado}" será removida permanentemente do banco.\n\n'
          'Não é possível excluir se já existirem respostas vinculadas.',
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
      await ref.read(apiClientProvider).deletePergunta(pergunta.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Pergunta excluída');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  String _emptyMessage() {
    if (_tipoFormularioId != null) {
      final nome = _tipos
          .where((t) => t.id == _tipoFormularioId)
          .map((t) => t.nome)
          .firstOrNull;
      if (nome != null) {
        return 'Nenhuma pergunta cadastrada em "$nome".\n'
            'Toque em Nova para criar ou escolha outro tipo.';
      }
      return 'Nenhuma pergunta neste tipo de formulário.\n'
          'Toque em Nova para criar.';
    }
    return 'Nenhuma pergunta cadastrada.\nToque em Nova para criar.';
  }

  Widget _buildList() {
    if (_loading && (_perguntas == null || _perguntas!.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_perguntas == null || _perguntas!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            _emptyMessage(),
            textAlign: TextAlign.center,
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
          AppLayout.screenPaddingTop,
          AppLayout.screenPaddingH,
          88,
        ),
        itemCount: _perguntas!.length,
        itemBuilder: (context, index) {
          final p = _perguntas![index];
          return _PerguntaCard(
            pergunta: p,
            onEdit: ref.read(authProvider).podeAlterar(Programas.perguntas)
                ? () => _openForm(p)
                : null,
            onDelete: ref.read(authProvider).podeExcluir(Programas.perguntas)
                ? () => _delete(p)
                : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.perguntas);

    return PermissaoGate(
      programaCodigo: Programas.perguntas,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(context, title: 'Perguntas'),
        floatingActionButton: podeIncluir
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Nova'),
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                AppLayout.screenPaddingTop,
                AppLayout.screenPaddingH,
                0,
              ),
              child: _loadingTipos
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<String?>(
                      key: ValueKey(_tipoFormularioId),
                      initialValue: _tipoFormularioId,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de formulário',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ..._tipos.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.nome),
                          ),
                        ),
                      ],
                      onChanged: _loading ? null : _onTipoChanged,
                    ),
            ),
            if (_loading && !_loadingTipos)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }
}

class _PerguntaCard extends StatelessWidget {
  const _PerguntaCard({
    required this.pergunta,
    this.onEdit,
    this.onDelete,
  });

  final Pergunta pergunta;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pergunta.tipoFormularioNome != null)
                Chip(label: Text(pergunta.tipoFormularioNome!)),
              Chip(label: Text(pergunta.tipoCampo.label)),
              if (pergunta.tipoCampo == TipoCampo.texto &&
                  pergunta.tamanhoCampo != null)
                Chip(
                  label: Text(
                    '${pergunta.tamanhoCampo} chars'
                    '${pergunta.linhasCampo != null ? ', ${pergunta.linhasCampo} linha(s)' : ''}',
                  ),
                ),
              if (pergunta.tipoCampo == TipoCampo.lista)
                Chip(
                  label: Text(
                    '${pergunta.opcoes.length} opções '
                    '(${pergunta.opcoesAtivas.length} ativas)',
                  ),
                ),
              Chip(label: Text('Ordem ${pergunta.ordem}')),
              if (!pergunta.ativo)
                Text(
                  'Inativa',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pergunta.enunciado, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          RecordActionButtons(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}
