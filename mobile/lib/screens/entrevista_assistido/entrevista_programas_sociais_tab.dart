import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';

class EntrevistaProgramasSociaisTab extends StatelessWidget {
  const EntrevistaProgramasSociaisTab({
    super.key,
    required this.readOnly,
    required this.bolsaFamilia,
    required this.peti,
    required this.bpc,
    required this.outrosProgramas,
    required this.outrosProgramasSociaisController,
    required this.cras,
    required this.centroPop,
    required this.conselhoTutelar,
    required this.ubs,
    required this.creas,
    required this.caps,
    required this.craf,
    required this.outrosAtendimentoFamilia,
    required this.outrosOrgaosSociaisController,
    required this.onBolsaFamiliaChanged,
    required this.onPetiChanged,
    required this.onBpcChanged,
    required this.onOutrosProgramasChanged,
    required this.onCrasChanged,
    required this.onCentroPopChanged,
    required this.onConselhoTutelarChanged,
    required this.onUbsChanged,
    required this.onCreasChanged,
    required this.onCapsChanged,
    required this.onCrafChanged,
    required this.onOutrosAtendimentoChanged,
  });

  final bool readOnly;
  final bool bolsaFamilia;
  final bool peti;
  final bool bpc;
  final bool outrosProgramas;
  final TextEditingController outrosProgramasSociaisController;
  final bool cras;
  final bool centroPop;
  final bool conselhoTutelar;
  final bool ubs;
  final bool creas;
  final bool caps;
  final bool craf;
  final bool outrosAtendimentoFamilia;
  final TextEditingController outrosOrgaosSociaisController;
  final ValueChanged<bool?> onBolsaFamiliaChanged;
  final ValueChanged<bool?> onPetiChanged;
  final ValueChanged<bool?> onBpcChanged;
  final ValueChanged<bool?> onOutrosProgramasChanged;
  final ValueChanged<bool?> onCrasChanged;
  final ValueChanged<bool?> onCentroPopChanged;
  final ValueChanged<bool?> onConselhoTutelarChanged;
  final ValueChanged<bool?> onUbsChanged;
  final ValueChanged<bool?> onCreasChanged;
  final ValueChanged<bool?> onCapsChanged;
  final ValueChanged<bool?> onCrafChanged;
  final ValueChanged<bool?> onOutrosAtendimentoChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tituloStyle = textTheme.bodyLarge?.copyWith(
      fontFamily: AppTheme.fontFamily,
      fontWeight: FontWeight.w600,
      color: AppColors.darkGray,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        AppLayout.screenPaddingTop,
        AppLayout.screenPaddingH,
        16,
      ),
      children: [
        Text(
          'Beneficiário(a) de algum dos seguintes Programas Sociais:',
          style: tituloStyle,
        ),
        const SizedBox(height: 12),
        _duasColunas(
          esquerda: _checkbox(
            context,
            value: bolsaFamilia,
            label: 'Bolsa Família',
            onChanged: onBolsaFamiliaChanged,
          ),
          direita: _checkbox(
            context,
            value: bpc,
            label: 'BPC',
            onChanged: onBpcChanged,
          ),
        ),
        _duasColunas(
          esquerda: _checkbox(
            context,
            value: peti,
            label: 'PETI',
            onChanged: onPetiChanged,
          ),
          direita: _colunaOutrosProgramas(context),
        ),
        const SizedBox(height: 24),
        Text(
          'A Família é atendida por algum órgão ?',
          style: tituloStyle,
        ),
        const SizedBox(height: 12),
        _duasColunas(
          esquerda: _checkbox(
            context,
            value: cras,
            label: 'CRAS',
            onChanged: onCrasChanged,
          ),
          direita: _checkbox(
            context,
            value: creas,
            label: 'CREAS',
            onChanged: onCreasChanged,
          ),
        ),
        _duasColunas(
          esquerda: _checkbox(
            context,
            value: centroPop,
            label: 'CENTRO POP',
            onChanged: onCentroPopChanged,
          ),
          direita: _checkbox(
            context,
            value: caps,
            label: 'CAPS',
            onChanged: onCapsChanged,
          ),
        ),
        _duasColunas(
          esquerda: _checkbox(
            context,
            value: conselhoTutelar,
            label: 'CONSELHO TUTELAR',
            onChanged: onConselhoTutelarChanged,
          ),
          direita: _checkbox(
            context,
            value: craf,
            label: 'CRAF (Secretaria da Mulher)',
            onChanged: onCrafChanged,
          ),
        ),
        _duasColunas(
          esquerda: _checkbox(
            context,
            value: ubs,
            label: 'UBS',
            onChanged: onUbsChanged,
          ),
          direita: _colunaOutrosOrgaos(context),
        ),
      ],
    );
  }

  Widget _colunaOutrosProgramas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _checkbox(
          context,
          value: outrosProgramas,
          label: 'Outros Programas',
          onChanged: onOutrosProgramasChanged,
        ),
        if (outrosProgramas) ...[
          const SizedBox(height: 4),
          TextFormField(
            controller: outrosProgramasSociaisController,
            readOnly: readOnly,
            decoration: const InputDecoration(
              labelText: 'Outros programas',
              hintText: 'Até 30 caracteres',
            ),
            maxLength: 30,
          ),
        ],
      ],
    );
  }

  Widget _colunaOutrosOrgaos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _checkbox(
          context,
          value: outrosAtendimentoFamilia,
          label: 'Outros',
          onChanged: onOutrosAtendimentoChanged,
        ),
        if (outrosAtendimentoFamilia) ...[
          const SizedBox(height: 4),
          TextFormField(
            controller: outrosOrgaosSociaisController,
            readOnly: readOnly,
            decoration: const InputDecoration(
              labelText: 'Outros órgãos',
              hintText: 'Até 30 caracteres',
            ),
            maxLength: 30,
          ),
        ],
      ],
    );
  }

  Widget _duasColunas({
    required Widget esquerda,
    required Widget direita,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: esquerda),
          const SizedBox(width: 8),
          Expanded(child: direita),
        ],
      ),
    );
  }

  Widget _checkbox(
    BuildContext context, {
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return CheckboxListTile(
      value: value,
      onChanged: readOnly ? null : onChanged,
      title: Text(
        label,
        style: textTheme.bodyLarge?.copyWith(
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
