import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/resposta_sim_nao.dart';
import '../../constants/tipo_deficiencia_familiar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'entrevista_focus.dart';
import 'entrevista_form_linhas.dart';
import 'entrevista_text_field.dart';

class EntrevistaCondicaoSaudeTab extends StatelessWidget {
  const EntrevistaCondicaoSaudeTab({
    super.key,
    this.readOnly = false,
    required this.deficiencias,
    required this.gestantes,
    required this.saudeFamilia,
    required this.nomesDisponiveis,
    required this.onAdicionarDeficiencia,
    required this.onRemoverDeficiencia,
    required this.onAdicionarGestante,
    required this.onRemoverGestante,
    required this.onLimparGestantes,
    required this.onChanged,
    this.onAdvanceAfterTab,
  });

  final bool readOnly;
  final List<DeficienciaFamiliarLinha> deficiencias;
  final List<GestanteFamiliarLinha> gestantes;
  final SaudeFamiliaForm saudeFamilia;
  final List<String> nomesDisponiveis;
  final VoidCallback onAdicionarDeficiencia;
  final void Function(int index) onRemoverDeficiencia;
  final VoidCallback onAdicionarGestante;
  final void Function(int index) onRemoverGestante;
  final VoidCallback onLimparGestantes;
  final VoidCallback onChanged;
  final VoidCallback? onAdvanceAfterTab;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = saudeFamilia;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        AppLayout.screenPaddingTop,
        AppLayout.screenPaddingH,
        16,
      ),
      children: [
        Text(
          'Caso haja presença de pessoa com deficiência na familia, preencha o quadro abaixo',
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 16),
        if (nomesDisponiveis.isEmpty)
          Text(
            'Selecione o assistido e, se necessário, cadastre integrantes na aba Composição Familiar.',
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.neutralGray,
            ),
          )
        else
          ...deficiencias.asMap().entries.map((entry) {
            final i = entry.key;
            final linha = entry.value;
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
                            onPressed: () => onRemoverDeficiencia(i),
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
                        'saude-nome-${linha.nomeSelecionado}-$i',
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
                    DropdownButtonFormField<TipoDeficienciaFamiliar>(
                      key: ValueKey(
                        'saude-tipo-${linha.tipoDeficiencia}-$i',
                      ),
                      initialValue: linha.tipoDeficiencia,
                      decoration: const InputDecoration(
                        labelText: 'Tipos_Deficiencia',
                      ),
                      items: TipoDeficienciaFamiliar.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t.rotulo,
                                style: const TextStyle(
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
                              linha.tipoDeficiencia = v;
                              onChanged();
                            },
                      validator: (v) =>
                          v == null ? 'Selecione o tipo de deficiência' : null,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: linha.necessitaCuidadosConstantes,
                      onChanged: readOnly
                          ? null
                          : (v) {
                              linha.necessitaCuidadosConstantes = v ?? false;
                              onChanged();
                            },
                      title: Text(
                        'Necessita de Cuidados Constantes',
                        style: textTheme.bodyLarge?.copyWith(
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextFormField(
                      controller: linha.quemECuidador,
                      readOnly: readOnly,
                      onChanged: readOnly ? null : (_) => onChanged(),
                      decoration: const InputDecoration(
                        labelText: 'Quem é o cuidador ?',
                      ),
                      maxLines: 2,
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
            onPressed: onAdicionarDeficiencia,
          ),
        const SizedBox(height: 28),
        _perguntaSimNao(
          context,
          texto:
              'Algum membro da familia faz uso de remédios controlados para transtornos mentais ?',
          valor: s.remediosControladosMental,
          onChanged: readOnly
              ? null
              : (v) {
                  s.remediosControladosMental = v;
                  if (v != RespostaSimNao.sim) {
                    s.remediosControladosQuais.clear();
                  }
                  onChanged();
                },
        ),
        if (s.remediosControladosMental == RespostaSimNao.sim) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: s.remediosControladosQuais,
            readOnly: readOnly,
            onChanged: readOnly ? null : (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Quais'),
            maxLines: 2,
            validator: (v) {
              if (s.remediosControladosMental == RespostaSimNao.sim &&
                  (v == null || v.trim().isEmpty)) {
                return 'Informe quais remédios';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 20),
        _perguntaSimNao(
          context,
          texto: 'Algum membro da familia faz uso abusivo de álcool ?',
          valor: s.usoAbusivoAlcool,
          onChanged: readOnly
              ? null
              : (v) {
                  s.usoAbusivoAlcool = v;
                  onChanged();
                },
        ),
        const SizedBox(height: 20),
        _perguntaSimNao(
          context,
          texto: 'Algum membro da familia faz uso abusivo de drogas ?',
          valor: s.usoAbusivoDrogas,
          onChanged: readOnly
              ? null
              : (v) {
                  s.usoAbusivoDrogas = v;
                  if (v != RespostaSimNao.sim) {
                    s.usoAbusivoDrogasQuais.clear();
                  }
                  onChanged();
                },
        ),
        if (s.usoAbusivoDrogas == RespostaSimNao.sim) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: s.usoAbusivoDrogasQuais,
            readOnly: readOnly,
            onChanged: readOnly ? null : (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Quais'),
            maxLines: 2,
            validator: (v) {
              if (s.usoAbusivoDrogas == RespostaSimNao.sim &&
                  (v == null || v.trim().isEmpty)) {
                return 'Informe quais drogas';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 20),
        _perguntaSimNao(
          context,
          texto: 'Tem gestante na familia ?',
          valor: s.temGestante,
          onChanged: readOnly
              ? null
              : (v) {
                  s.temGestante = v;
                  if (v != RespostaSimNao.sim) {
                    onLimparGestantes();
                  } else if (gestantes.isEmpty) {
                    onAdicionarGestante();
                  }
                  onChanged();
                },
        ),
        if (s.temGestante == RespostaSimNao.sim) ...[
          const SizedBox(height: 16),
          if (nomesDisponiveis.isEmpty)
            Text(
              'Selecione o assistido e, se necessário, cadastre integrantes na aba Composição Familiar.',
              style: textTheme.bodyMedium?.copyWith(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.neutralGray,
              ),
            )
          else
            ...gestantes.asMap().entries.map((entry) {
              final i = entry.key;
              final linha = entry.value;
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
                              'Gestante ${i + 1}',
                              style: textTheme.titleSmall?.copyWith(
                                fontFamily: AppTheme.fontFamily,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          if (!readOnly)
                            IconButton(
                              tooltip: 'Remover',
                              onPressed: () => onRemoverGestante(i),
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
                          'gestante-nome-${linha.nomeSelecionado}-$i',
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
                        controller: linha.mesesGestacao,
                        focusNode: linha.focusMesesGestacao,
                        readOnly: readOnly,
                        onChanged: readOnly ? null : (_) => onChanged(),
                        onAdvance: () => onAdvanceAfterTab?.call(),
                        decoration: const InputDecoration(
                          labelText: 'Meses de Gestação',
                          hintText: 'Ex.: 6',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe os meses de gestação';
                          }
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 0 || n > 10) {
                            return 'Meses inválidos (0 a 10)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _perguntaSimNao(
                        context,
                        texto: 'Iniciou Pré Natal',
                        valor: linha.iniciouPreNatal,
                        onChanged: readOnly
                            ? null
                            : (v) {
                                linha.iniciouPreNatal = v;
                                onChanged();
                              },
                        validator: (v) {
                          if (v == null) {
                            return 'Selecione Sim ou Não';
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
              label: 'Adicionar gestante',
              type: AppButtonType.secondary,
              icon: Icons.add,
              onPressed: onAdicionarGestante,
            ),
        ],
      ],
    );
  }

  Widget _perguntaSimNao(
    BuildContext context, {
    required String texto,
    required RespostaSimNao? valor,
    required void Function(RespostaSimNao?)? onChanged,
    String? Function(RespostaSimNao?)? validator,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          texto,
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RespostaSimNao>(
          key: ValueKey('$texto-$valor'),
          initialValue: valor,
          decoration: const InputDecoration(
            labelText: 'Resposta',
          ),
          items: RespostaSimNao.values
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.rotulo),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator != null ? (v) => validator(v) : null,
        ),
      ],
    );
  }
}
