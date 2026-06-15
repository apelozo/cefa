import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/moeda_br.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'inscricao_renda_linha.dart';

class InscricaoRendaFamiliarTab extends StatefulWidget {
  const InscricaoRendaFamiliarTab({
    super.key,
    required this.linhas,
    required this.onAdicionar,
    required this.onRemover,
  });

  final List<InscricaoRendaLinha> linhas;
  final VoidCallback onAdicionar;
  final void Function(int index) onRemover;

  @override
  State<InscricaoRendaFamiliarTab> createState() =>
      _InscricaoRendaFamiliarTabState();
}

class _InscricaoRendaFamiliarTabState extends State<InscricaoRendaFamiliarTab> {
  final Map<InscricaoRendaLinha, VoidCallback> _rendaListeners = {};

  @override
  void initState() {
    super.initState();
    _attachRendaListeners();
  }

  @override
  void didUpdateWidget(covariant InscricaoRendaFamiliarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linhas.length != widget.linhas.length) {
      _attachRendaListeners();
    }
  }

  @override
  void dispose() {
    _detachRendaListeners();
    super.dispose();
  }

  void _attachRendaListeners() {
    _detachRendaListeners();
    for (final linha in widget.linhas) {
      void listener() {
        if (mounted) setState(() {});
      }
      linha.renda.addListener(listener);
      _rendaListeners[linha] = listener;
    }
  }

  void _detachRendaListeners() {
    for (final entry in _rendaListeners.entries) {
      entry.key.renda.removeListener(entry.value);
    }
    _rendaListeners.clear();
  }

  double get _rendaTotal {
    var total = 0.0;
    for (final linha in widget.linhas) {
      total += parseMoedaBr(linha.renda.text);
    }
    return total;
  }

  double get _rendaPerCapita {
    if (widget.linhas.isEmpty) return 0;
    return _rendaTotal / widget.linhas.length;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        AppLayout.screenPaddingTop,
        AppLayout.screenPaddingH,
        16,
      ),
      children: [
        Text(
          'Informe os integrantes da renda familiar (sem vínculo com cadastro de assistidos).',
          style: textTheme.bodyMedium?.copyWith(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.neutralGray,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.linhas.asMap().entries.map((entry) {
          final i = entry.key;
          final linha = entry.value;
          return Padding(
            key: ObjectKey(linha),
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pessoa ${i + 1}',
                          style: textTheme.titleSmall?.copyWith(
                            fontFamily: AppTheme.fontFamily,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover',
                        onPressed: () => widget.onRemover(i),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: linha.nome,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: linha.idade,
                    decoration: const InputDecoration(labelText: 'Idade'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: linha.renda,
                    decoration: const InputDecoration(
                      labelText: 'Renda (R\$)',
                      hintText: '0,00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    onTapOutside: (_) =>
                        formatarMoedaBrNoController(linha.renda),
                    onEditingComplete: () =>
                        formatarMoedaBrNoController(linha.renda),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: linha.parentesco,
                    decoration: const InputDecoration(labelText: 'Parentesco'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: linha.profissao,
                    decoration: const InputDecoration(labelText: 'Profissão'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
          );
        }),
        AppButton(
          label: 'Adicionar pessoa',
          icon: Icons.add,
          type: AppButtonType.secondary,
          onPressed: widget.onAdicionar,
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Renda Per Capita R\$',
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              Text(
                formatMoedaBr(_rendaPerCapita),
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
