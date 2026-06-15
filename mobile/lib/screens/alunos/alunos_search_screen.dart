import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/aluno.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/form_enter_focus.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';

/// Pesquisa de alunos por nome e/ou CPF (seleção única).
class AlunosSearchScreen extends ConsumerStatefulWidget {
  const AlunosSearchScreen({
    super.key,
    this.title = 'Pesquisar aluno',
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  static Future<Aluno?> select(
    BuildContext context, {
    String title = 'Pesquisar aluno',
    String? subtitle,
  }) {
    return Navigator.of(context).push<Aluno>(
      MaterialPageRoute(
        builder: (_) => AlunosSearchScreen(title: title, subtitle: subtitle),
      ),
    );
  }

  @override
  ConsumerState<AlunosSearchScreen> createState() => _AlunosSearchScreenState();
}

class _AlunosSearchScreenState extends ConsumerState<AlunosSearchScreen> {
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  late final FormEnterFocus _enterFocus;
  Timer? _debounce;

  List<Aluno>? _results;
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
    _cpfController.dispose();
    super.dispose();
  }

  bool get _hasCriteria {
    return _nomeController.text.trim().isNotEmpty ||
        normalizeCpf(_cpfController.text).isNotEmpty;
  }

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
    final cpf = _cpfController.text.trim();

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final items = await ref.read(apiClientProvider).listAlunos(
            ativo: true,
            nome: nome.isNotEmpty ? nome : null,
            cpf: cpf.isNotEmpty ? cpf : null,
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
    _cpfController.clear();
    setState(() {
      _results = null;
      _error = null;
    });
  }

  void _select(Aluno aluno) {
    Navigator.of(context).pop(aluno);
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
                TextFormField(
                  controller: _nomeController,
                  focusNode: _enterFocus.fields[0],
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Nome completo ou parte do nome',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  textCapitalization: TextCapitalization.words,
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
                  controller: _cpfController,
                  focusNode: _enterFocus.fields[1],
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    hintText: '000.000.000-00',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CpfFormatter()],
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
            'Preencha nome e/ou CPF para pesquisar.',
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
            'Nenhum aluno encontrado.',
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
        final aluno = _results![index];
        return AppCard(
          onTap: () => _select(aluno),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aluno.nome,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (aluno.cpfFormatado != null && aluno.cpfFormatado!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'CPF: ${aluno.cpfFormatado}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutralGray,
                        ),
                  ),
                ),
              if (aluno.dtNascimento != null &&
                  aluno.dtNascimento!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Nasc.: ${aluno.dtNascimento}${aluno.idade != null ? ' · ${aluno.idade} anos' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutralGray,
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
