import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/ocupacao_familiar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/moeda_br.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'entrevista_focus.dart';
import 'entrevista_form_linhas.dart';
import 'entrevista_text_field.dart';

class EntrevistaCondicaoTrabalhoTab extends StatelessWidget {
  const EntrevistaCondicaoTrabalhoTab({
    super.key,
    this.readOnly = false,
    required this.linhas,
    required this.nomesDisponiveis,
    required this.quantidadePessoasComposicao,
    required this.onAdicionar,
    required this.onRemover,
    required this.onChanged,
    this.onAdvanceAfterTab,
  });

  final bool readOnly;
  final List<CondicaoTrabalhoLinha> linhas;
  final List<String> nomesDisponiveis;
  final int quantidadePessoasComposicao;
  final VoidCallback onAdicionar;
  final void Function(int index) onRemover;
  final VoidCallback onChanged;
  final VoidCallback? onAdvanceAfterTab;

  double get _rendaTotal {
    var total = 0.0;
    for (final linha in linhas) {
      total += parseMoedaBr(linha.vrBeneficioSocial.text);
      total += parseMoedaBr(linha.rendaMensal.text);
    }
    return total;
  }

  double get _rendaPerCapita {
    final qtd = quantidadePessoasComposicao;
    if (qtd <= 0) return 0;
    return _rendaTotal / qtd;
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
        if (nomesDisponiveis.isEmpty)
          Text(
            'Selecione o assistido e, se necessário, cadastre integrantes na aba Composição Familiar.',
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.neutralGray,
            ),
          )
        else
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
                            'Registro ${i + 1}',
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
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'trab-nome-${linha.nomeSelecionado}-$i',
                      ),
                      initialValue: linha.nomeSelecionado != null &&
                              nomesDisponiveis.contains(linha.nomeSelecionado)
                          ? linha.nomeSelecionado
                          : null,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      items: nomesDisponiveis
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text(n),
                            ),
                          )
                          .toList(),
                      onChanged: readOnly
                          ? null
                          : (v) {
                              linha.nomeSelecionado = v;
                              onChanged();
                            },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Selecione o nome' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<OcupacaoFamiliar>(
                      key: ValueKey('trab-ocup-${linha.ocupacao}-$i'),
                      initialValue: linha.ocupacao,
                      decoration: const InputDecoration(labelText: 'Ocupação'),
                      items: OcupacaoFamiliar.values
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: Text(
                                o.rotulo,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: readOnly
                          ? null
                          : (v) {
                              linha.ocupacao = v;
                              onChanged();
                            },
                      validator: (v) =>
                          v == null ? 'Selecione a ocupação' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: linha.condicoesTrabalho,
                      readOnly: readOnly,
                      onChanged: readOnly ? null : (_) => onChanged(),
                      decoration: const InputDecoration(
                        labelText: 'Condições de trabalho',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    EntrevistaTextField(
                      controller: linha.vrBeneficioSocial,
                      focusNode: linha.focusVrBeneficioSocial,
                      readOnly: readOnly,
                      onChanged: readOnly ? null : (_) => onChanged(),
                      beforeAdvance: readOnly
                          ? null
                          : () {
                              formatarMoedaBrNoController(
                                linha.vrBeneficioSocial,
                              );
                              onChanged();
                            },
                      onTapOutside: readOnly
                          ? null
                          : (_) {
                              formatarMoedaBrNoController(
                                linha.vrBeneficioSocial,
                              );
                              onChanged();
                            },
                      onAdvance: () =>
                          EntrevistaFocus.advance(linha.focusRendaMensal),
                      decoration: const InputDecoration(
                        labelText: 'Vr. benefício social',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d,.\-]'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    EntrevistaTextField(
                      controller: linha.rendaMensal,
                      focusNode: linha.focusRendaMensal,
                      readOnly: readOnly,
                      onChanged: readOnly ? null : (_) => onChanged(),
                      beforeAdvance: readOnly
                          ? null
                          : () {
                              formatarMoedaBrNoController(linha.rendaMensal);
                              onChanged();
                            },
                      onTapOutside: readOnly
                          ? null
                          : (_) {
                              formatarMoedaBrNoController(linha.rendaMensal);
                              onChanged();
                            },
                      onAdvance: () {
                        if (proximaLinha != null) {
                          EntrevistaFocus.advance(
                            proximaLinha.focusVrBeneficioSocial,
                          );
                        } else {
                          onAdvanceAfterTab?.call();
                        }
                      },
                      textInputAction: proximaLinha != null
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Renda mensal',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d,.\-]'),
                        ),
                      ],
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
        const SizedBox(height: 24),
        Text(
          'Renda Total da Família: R\$ ${formatMoedaBr(_rendaTotal)}',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Renda Per Capita: R\$ ${formatMoedaBr(_rendaPerCapita)}',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
        if (quantidadePessoasComposicao > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Base: $quantidadePessoasComposicao integrante(s) na composição familiar',
              style: textTheme.bodySmall?.copyWith(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.neutralGray,
              ),
            ),
          ),
      ],
    );
  }
}
