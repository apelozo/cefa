import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/escolaridade.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'entrevista_focus.dart';
import 'entrevista_form_linhas.dart';
import 'entrevista_text_field.dart';

class EntrevistaCondicaoEducacionalTab extends StatelessWidget {
  const EntrevistaCondicaoEducacionalTab({
    super.key,
    this.readOnly = false,
    required this.linhas,
    required this.nomesDisponiveis,
    required this.escolaridades,
    required this.onAdicionar,
    required this.onRemover,
    required this.onChanged,
    this.onAdvanceAfterTab,
  });

  final bool readOnly;
  final List<CondicaoEducacionalLinha> linhas;
  final List<String> nomesDisponiveis;
  final List<Escolaridade> escolaridades;
  final VoidCallback onAdicionar;
  final void Function(int index) onRemover;
  final VoidCallback onChanged;
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
        if (!readOnly && escolaridades.isEmpty)
          Text(
            'Cadastre escolaridades em Cadastrar escolaridades (módulo Formulários) '
            'para preencher esta aba.',
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.neutralGray,
            ),
          ),
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
                        'educ-nome-${linha.nomeSelecionado}-$i',
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
                    EntrevistaTextField(
                      controller: linha.idade,
                      focusNode: linha.focusIdade,
                      readOnly: readOnly,
                      onChanged: readOnly ? null : (_) => onChanged(),
                      onAdvance: () {
                        if (proximaLinha != null) {
                          EntrevistaFocus.advance(proximaLinha.focusIdade);
                        } else {
                          onAdvanceAfterTab?.call();
                        }
                      },
                      textInputAction: proximaLinha != null
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Idade',
                        hintText: 'Ex.: 25',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe a idade';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0 || n > 150) {
                          return 'Idade inválida (0 a 150)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (readOnly)
                      InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Escolaridade'),
                        child: Text(
                          linha.escolaridadeRotulo ??
                              (linha.escolaridadeCodigo?.toString() ?? '—'),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        key: ValueKey(
                          'educ-esc-${linha.escolaridadeCodigo}-$i',
                        ),
                        initialValue: linha.escolaridadeCodigo != null &&
                                escolaridades.any(
                                  (e) => e.codigo == linha.escolaridadeCodigo,
                                )
                            ? linha.escolaridadeCodigo
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Escolaridade',
                        ),
                        items: escolaridades
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.codigo,
                                child: Text(
                                  e.descricao,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          linha.escolaridadeCodigo = v;
                          for (final e in escolaridades) {
                            if (e.codigo == v) {
                              linha.escolaridadeRotulo = e.descricao;
                              break;
                            }
                          }
                          onChanged();
                        },
                        validator: (v) =>
                            v == null ? 'Selecione a escolaridade' : null,
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        FilterChip(
                          label: Text(
                            'Sabe Ler e Escrever',
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          selected: linha.sabeLerEscrever,
                          onSelected: readOnly
                              ? null
                              : (v) {
                                  linha.sabeLerEscrever = v;
                                  onChanged();
                                },
                          selectedColor: AppColors.lightBlue,
                          checkmarkColor: AppColors.primaryBlue,
                        ),
                        FilterChip(
                          label: Text(
                            'Frequenta a Escola',
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          selected: linha.frequentaEscola,
                          onSelected: readOnly
                              ? null
                              : (v) {
                                  linha.frequentaEscola = v;
                                  onChanged();
                                },
                          selectedColor: AppColors.lightBlue,
                          checkmarkColor: AppColors.primaryBlue,
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
      ],
    );
  }
}
