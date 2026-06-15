import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/periodo_inscricao.dart';
import '../../constants/situacao_turma.dart';
import '../../models/turma.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';

/// Pesquisa de turmas por nome e/ou nome do curso.
class TurmasSearchScreen extends ConsumerStatefulWidget {
  const TurmasSearchScreen({
    super.key,
    this.title = 'Pesquisar turma',
    this.subtitle,
    this.somenteAbertas = false,
  });

  final String title;
  final String? subtitle;
  final bool somenteAbertas;

  static Future<Turma?> select(
    BuildContext context, {
    String title = 'Pesquisar turma',
    String? subtitle,
    bool somenteAbertas = false,
  }) {
    return Navigator.of(context).push<Turma>(
      MaterialPageRoute(
        builder: (_) => TurmasSearchScreen(
          title: title,
          subtitle: subtitle,
          somenteAbertas: somenteAbertas,
        ),
      ),
    );
  }

  @override
  ConsumerState<TurmasSearchScreen> createState() => _TurmasSearchScreenState();
}

class _TurmasSearchScreenState extends ConsumerState<TurmasSearchScreen> {
  final _nomeController = TextEditingController();
  final _cursoController = TextEditingController();
  late final FormEnterFocus _enterFocus;
  Timer? _debounce;

  List<Turma>? _results;
  bool _searching = false;
  String? _error;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enterFocus.fields[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _enterFocus.dispose();
    _nomeController.dispose();
    _cursoController.dispose();
    super.dispose();
  }

  bool get _hasCriteria =>
      _nomeController.text.trim().isNotEmpty ||
      _cursoController.text.trim().isNotEmpty;

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  Future<void> _runSearch() async {
    if (!_hasCriteria) {
      setState(() {
        _results = null;
        _error = null;
        _searching = false;
      });
      return;
    }

    final generation = ++_searchGeneration;
    final nome = _nomeController.text.trim();
    final curso = _cursoController.text.trim();

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final items = await ref.read(apiClientProvider).listTurmas(
            ativo: true,
            nome: nome.isEmpty ? null : nome,
            cursoDescricao: curso.isEmpty ? null : curso,
            situacao: widget.somenteAbertas ? SituacaoTurma.aberta : null,
          );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = items;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searching = false;
        _error = e.toString();
        _results = [];
      });
    }
  }

  void _clear() {
    _nomeController.clear();
    _cursoController.clear();
    setState(() {
      _results = null;
      _error = null;
    });
  }

  void _select(Turma turma) {
    Navigator.of(context).pop(turma);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppScreenChrome.appBar(context, title: widget.title),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.subtitle != null) ...[
                  Text(
                    widget.subtitle!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.somenteAbertas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Somente turmas abertas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutralGray,
                          ),
                    ),
                  ),
                TextFormField(
                  controller: _nomeController,
                  focusNode: _enterFocus.fields[0],
                  decoration: const InputDecoration(
                    labelText: 'Nome da turma',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: _enterFocus.inputAction(0),
                  onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
                  onChanged: (_) {
                    setState(() {});
                    _scheduleSearch();
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cursoController,
                  focusNode: _enterFocus.fields[1],
                  decoration: const InputDecoration(
                    labelText: 'Nome do curso',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: _enterFocus.inputAction(1),
                  onFieldSubmitted: (_) => _enterFocus.onSubmitted(1),
                  onEditingComplete: _enterFocus.editingComplete(1),
                  onChanged: (_) {
                    setState(() {});
                    _scheduleSearch();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Pesquisar',
                        focusNode: _enterFocus.submitFocusNode,
                        onPressed: _searching ? null : _runSearch,
                        loading: _searching,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Limpar',
                        type: AppButtonType.secondary,
                        onPressed: _hasCriteria ? _clear : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasCriteria) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            'Digite o nome da turma e/ou do curso para pesquisar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.neutralGray,
                ),
          ),
        ),
      );
    }

    if (_searching && _results == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (_results == null || _results!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            'Nenhuma turma encontrada.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        0,
        AppLayout.screenPaddingH,
        AppLayout.screenPaddingBottom,
      ),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final turma = _results![index];
        return AppCard(
          onTap: () => _select(turma),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${turma.codigo}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      turma.nome,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                turma.cursoDescricao,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                children: [
                  Text(
                    PeriodoInscricao.rotulo(turma.periodo),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    SituacaoTurma.rotulo(turma.situacao),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: turma.situacao == SituacaoTurma.aberta
                              ? Colors.green.shade700
                              : AppColors.neutralGray,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
