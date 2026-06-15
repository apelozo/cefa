import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/curso.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';

/// Pesquisa de cursos pelo nome (descrição).
class CursosSearchScreen extends ConsumerStatefulWidget {
  const CursosSearchScreen({
    super.key,
    this.title = 'Pesquisar curso',
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  static Future<Curso?> select(
    BuildContext context, {
    String title = 'Pesquisar curso',
    String? subtitle,
  }) {
    return Navigator.of(context).push<Curso>(
      MaterialPageRoute(
        builder: (_) => CursosSearchScreen(title: title, subtitle: subtitle),
      ),
    );
  }

  @override
  ConsumerState<CursosSearchScreen> createState() => _CursosSearchScreenState();
}

class _CursosSearchScreenState extends ConsumerState<CursosSearchScreen> {
  final _descricaoController = TextEditingController();
  late final FormEnterFocus _enterFocus;
  Timer? _debounce;

  List<Curso>? _results;
  bool _searching = false;
  String? _error;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enterFocus.fields[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _enterFocus.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  bool get _hasCriteria => _descricaoController.text.trim().isNotEmpty;

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
    final descricao = _descricaoController.text.trim();

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final items = await ref.read(apiClientProvider).listCursos(
            ativo: true,
            descricao: descricao,
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
    _descricaoController.clear();
    setState(() {
      _results = null;
      _error = null;
    });
  }

  void _select(Curso curso) {
    Navigator.of(context).pop(curso);
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
                  controller: _descricaoController,
                  focusNode: _enterFocus.fields[0],
                  decoration: const InputDecoration(
                    labelText: 'Nome do curso',
                    hintText: 'Digite o nome ou parte do nome',
                    prefixIcon: Icon(Icons.school_outlined),
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
            'Digite o nome do curso para pesquisar.',
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
            'Nenhum curso encontrado.',
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
        final curso = _results![index];
        return AppCard(
          onTap: () => _select(curso),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${curso.codigo}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  curso.descricao,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
