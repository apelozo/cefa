import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// Opção para [AppSearchableSelectField].
class SearchableSelectOption<T> {
  const SearchableSelectOption({
    required this.value,
    required this.label,
    String? searchText,
  }) : searchText = searchText ?? label;

  final T? value;
  final String label;
  final String searchText;
}

/// Campo de seleção com pesquisa (modal inferior com filtro).
class AppSearchableSelectField<T> extends StatelessWidget {
  const AppSearchableSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.hintText = 'Toque para selecionar',
    this.searchLabel = 'Pesquisar',
    this.emptyListMessage,
    this.onCadastrar,
    this.cadastrarLabel = 'Cadastrar',
  });

  final String label;
  final List<SearchableSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String hintText;
  final String searchLabel;
  final String? emptyListMessage;
  /// Quando informado, exibe botão para abrir cadastro e retorna o valor criado.
  final Future<T?> Function()? onCadastrar;
  final String cadastrarLabel;

  SearchableSelectOption<T>? _selectedOption() {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || onChanged == null) return;

    final picked = await showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _SearchableSelectSheet<T>(
          options: options,
          searchLabel: searchLabel,
          emptyListMessage: emptyListMessage,
          onCadastrar: onCadastrar,
          cadastrarLabel: cadastrarLabel,
        );
      },
    );

    if (picked != value) {
      onChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption();
    final displayText = selected?.label ?? hintText;
    final isPlaceholder = selected == null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            displayText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: AppTheme.fontFamily,
                  color: isPlaceholder ? Colors.grey.shade600 : null,
                ),
          ),
        ),
      ),
    );
  }
}

class _SearchableSelectSheet<T> extends StatefulWidget {
  const _SearchableSelectSheet({
    required this.options,
    required this.searchLabel,
    this.emptyListMessage,
    this.onCadastrar,
    required this.cadastrarLabel,
  });

  final List<SearchableSelectOption<T>> options;
  final String searchLabel;
  final String? emptyListMessage;
  final Future<T?> Function()? onCadastrar;
  final String cadastrarLabel;

  @override
  State<_SearchableSelectSheet<T>> createState() =>
      _SearchableSelectSheetState<T>();
}

class _SearchableSelectSheetState<T> extends State<_SearchableSelectSheet<T>> {
  final _searchController = TextEditingController();
  late List<SearchableSelectOption<T>> _filtered;
  bool _cadastrando = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCadastrar() async {
    final cadastrar = widget.onCadastrar;
    if (cadastrar == null || _cadastrando) return;

    setState(() => _cadastrando = true);
    try {
      final created = await cadastrar();
      if (!mounted) return;
      if (created != null) {
        Navigator.pop(context, created);
      }
    } finally {
      if (mounted) setState(() => _cadastrando = false);
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.options;
        return;
      }
      _filtered = widget.options
          .where((o) => o.searchText.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.65;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: widget.searchLabel,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyListMessage ??
                            'Nenhum resultado para a pesquisa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final option = _filtered[index];
                        return ListTile(
                          title: Text(
                            option.label,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          onTap: () =>
                              Navigator.pop(context, option.value),
                        );
                      },
                    ),
            ),
            if (widget.onCadastrar != null) ...[
              const SizedBox(height: 8),
              AppButton(
                label: widget.cadastrarLabel,
                type: AppButtonType.secondary,
                icon: Icons.add,
                loading: _cadastrando,
                onPressed: _cadastrando ? null : _handleCadastrar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
