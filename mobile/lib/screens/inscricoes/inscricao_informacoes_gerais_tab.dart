import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/telefone_formatter.dart';

class InscricaoInformacoesGeraisTab extends StatelessWidget {
  const InscricaoInformacoesGeraisTab({
    super.key,
    required this.dtCursoController,
    required this.jaFezCursoSenacSenai,
    required this.onJaFezCursoSenacSenaiChanged,
    required this.cursoSenacSenaiController,
    required this.possuiEncaminhamento,
    required this.onPossuiEncaminhamentoChanged,
    required this.orgaoEncaminhamentoController,
    required this.telefoneEncaminhamentoController,
    required this.possuiNecessidadeEspecial,
    required this.onPossuiNecessidadeEspecialChanged,
    required this.qualNecessidadeController,
    required this.fazAcompanhamentoMedico,
    required this.onFazAcompanhamentoMedicoChanged,
    required this.tomaMedicacao,
    required this.onTomaMedicacaoChanged,
    required this.quaisMedicacoesController,
    required this.vacinacaoController,
    required this.alergiasController,
  });

  final TextEditingController dtCursoController;
  final bool jaFezCursoSenacSenai;
  final ValueChanged<bool> onJaFezCursoSenacSenaiChanged;
  final TextEditingController cursoSenacSenaiController;
  final bool possuiEncaminhamento;
  final ValueChanged<bool> onPossuiEncaminhamentoChanged;
  final TextEditingController orgaoEncaminhamentoController;
  final TextEditingController telefoneEncaminhamentoController;
  final bool possuiNecessidadeEspecial;
  final ValueChanged<bool> onPossuiNecessidadeEspecialChanged;
  final TextEditingController qualNecessidadeController;
  final bool fazAcompanhamentoMedico;
  final ValueChanged<bool> onFazAcompanhamentoMedicoChanged;
  final bool tomaMedicacao;
  final ValueChanged<bool> onTomaMedicacaoChanged;
  final TextEditingController quaisMedicacoesController;
  final TextEditingController vacinacaoController;
  final TextEditingController alergiasController;

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
          'Informações Gerais',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: dtCursoController,
          decoration: const InputDecoration(labelText: 'Data de inscrição'),
          keyboardType: TextInputType.datetime,
          inputFormatters: [DataBrFormatter()],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Já fez cursos no SENAC/SENAI',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          value: jaFezCursoSenacSenai,
          onChanged: (v) => onJaFezCursoSenacSenaiChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (jaFezCursoSenacSenai) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: cursoSenacSenaiController,
            decoration: const InputDecoration(
              labelText: 'Qual curso já foi feito',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Possui encaminhamento',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          value: possuiEncaminhamento,
          onChanged: (v) => onPossuiEncaminhamentoChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (possuiEncaminhamento) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: orgaoEncaminhamentoController,
            decoration: const InputDecoration(
              labelText: 'Órgão que encaminhou',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: telefoneEncaminhamentoController,
            decoration: const InputDecoration(
              labelText: 'Telefone do encaminhamento',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [TelefoneFormatter()],
          ),
        ],
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Possui alguma necessidade especial',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          value: possuiNecessidadeEspecial,
          onChanged: (v) => onPossuiNecessidadeEspecialChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (possuiNecessidadeEspecial) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: qualNecessidadeController,
            decoration: const InputDecoration(
              labelText: 'Qual necessidade',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Faz algum acompanhamento médico',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          value: fazAcompanhamentoMedico,
          onChanged: (v) => onFazAcompanhamentoMedicoChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Toma medicação',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          value: tomaMedicacao,
          onChanged: (v) => onTomaMedicacaoChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (tomaMedicacao) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: quaisMedicacoesController,
            decoration: const InputDecoration(
              labelText: 'Quais medicações',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: vacinacaoController,
          decoration: const InputDecoration(labelText: 'Vacinação'),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: alergiasController,
          decoration: const InputDecoration(labelText: 'Alergias'),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
      ],
    );
  }
}
