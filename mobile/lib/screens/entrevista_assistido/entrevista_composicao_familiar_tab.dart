import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/data_br_formatter.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'entrevista_focus.dart';
import 'entrevista_form_linhas.dart';
import 'entrevista_text_field.dart';

class EntrevistaComposicaoFamiliarTab extends StatelessWidget {
  const EntrevistaComposicaoFamiliarTab({
    super.key,
    this.readOnly = false,
    required this.linhas,
    required this.onAdicionar,
    required this.onRemover,
    required this.onLinhaChanged,
    this.onAdvanceAfterTab,
  });

  final bool readOnly;
  final List<ComposicaoFamiliarLinha> linhas;
  final VoidCallback onAdicionar;
  final void Function(int index) onRemover;
  final void Function(int index) onLinhaChanged;
  final VoidCallback? onAdvanceAfterTab;

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
          'Integrantes da família do assistido (além da pessoa selecionada no início). '
          'Ao adicionar um integrante, uma linha correspondente é criada na aba Trabalho e Renda.',
          style: textTheme.bodyMedium?.copyWith(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.neutralGray,
          ),
        ),
        const SizedBox(height: 16),
        ...linhas.asMap().entries.map((entry) {
          final i = entry.key;
          final linha = entry.value;
          final proximaLinha =
              i + 1 < linhas.length ? linhas[i + 1] : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Integrante ${i + 1}',
                          style: textTheme.titleSmall?.copyWith(
                            fontFamily: AppTheme.fontFamily,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      if (!readOnly)
                        IconButton(
                          tooltip: 'Remover',
                          onPressed: () => onRemover(i),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  EntrevistaTextField(
                    controller: linha.nome,
                    focusNode: linha.focusNome,
                    readOnly: readOnly,
                    onChanged: readOnly ? null : (_) => onLinhaChanged(i),
                    onAdvance: () =>
                        EntrevistaFocus.advance(linha.focusCpf),
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  EntrevistaTextField(
                    controller: linha.cpf,
                    focusNode: linha.focusCpf,
                    readOnly: readOnly,
                    onChanged: readOnly ? null : (_) => onLinhaChanged(i),
                    onAdvance: () =>
                        EntrevistaFocus.advance(linha.focusDtNascimento),
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfFormatter()],
                    validator: validateCpfOpcional,
                  ),
                  const SizedBox(height: 12),
                  EntrevistaTextField(
                    controller: linha.dtNascimento,
                    focusNode: linha.focusDtNascimento,
                    readOnly: readOnly,
                    onChanged: readOnly ? null : (_) => onLinhaChanged(i),
                    onAdvance: () =>
                        EntrevistaFocus.advance(linha.focusParentesco),
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      hintText: 'dd/mm/aa',
                    ),
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [DataBrFormatter()],
                    validator: validateDataBr,
                  ),
                  const SizedBox(height: 12),
                  EntrevistaTextField(
                    controller: linha.parentesco,
                    focusNode: linha.focusParentesco,
                    readOnly: readOnly,
                    onChanged: readOnly ? null : (_) => onLinhaChanged(i),
                    onAdvance: () {
                      if (proximaLinha != null) {
                        EntrevistaFocus.advance(proximaLinha.focusNome);
                      } else {
                        onAdvanceAfterTab?.call();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Parentesco',
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: proximaLinha != null
                        ? TextInputAction.next
                        : TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o parentesco';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        if (!readOnly)
          AppButton(
            label: 'Adicionar',
            type: AppButtonType.secondary,
            icon: Icons.add,
            onPressed: onAdicionar,
          ),
      ],
    );
  }
}
