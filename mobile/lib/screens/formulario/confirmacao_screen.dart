import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pergunta.dart';
import '../../models/submissao.dart';
import '../../models/tipo_campo.dart';
import '../../auth/programas.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';

class ConfirmacaoScreen extends ConsumerStatefulWidget {
  const ConfirmacaoScreen({
    super.key,
    required this.tipoFormularioId,
    required this.tipoFormularioNome,
    required this.pessoaId,
    required this.pessoaNome,
    required this.perguntas,
    required this.respostas,
  });

  final String tipoFormularioId;
  final String tipoFormularioNome;
  final String pessoaId;
  final String pessoaNome;
  final List<Pergunta> perguntas;
  final List<RespostaItem> respostas;

  @override
  ConsumerState<ConfirmacaoScreen> createState() =>
      _ConfirmacaoScreenState();
}

class _ConfirmacaoScreenState extends ConsumerState<ConfirmacaoScreen> {
  bool _submitting = false;

  String _formatResposta(Pergunta pergunta, RespostaItem item) {
    switch (pergunta.tipoCampo) {
      case TipoCampo.inteiro:
        return item.valorInteiro.toString();
      case TipoCampo.decimal:
        return item.valorDecimal ?? '';
      case TipoCampo.texto:
        return item.valorTexto ?? '';
      case TipoCampo.logico:
        return item.valorLogico == true ? 'Sim' : 'Não';
      case TipoCampo.data:
        return item.valorData ?? '';
      case TipoCampo.lista:
        final id = item.valorOpcaoId;
        if (id == null) return '';
        for (final o in pergunta.opcoes) {
          if (o.id == id) return o.rotulo;
        }
        return id;
    }
  }

  Future<void> _submit() async {
    if (!ref.read(authProvider).podeIncluir(Programas.lancamento)) {
      showErrorSnackBar(context, 'Sem permissão para incluir lançamentos');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).createSubmissao(
            tipoFormularioId: widget.tipoFormularioId,
            pessoaId: widget.pessoaId,
            respostas: widget.respostas,
          );
      if (mounted) {
        showSuccessSnackBar(context, 'Formulário enviado com sucesso');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perguntaMap = {for (final p in widget.perguntas) p.id: p};

    return AppScaffold(
      appBar: AppScreenChrome.appBar(context, title: 'Confirmar envio'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.screenPaddingH,
              AppLayout.screenPaddingTop,
              AppLayout.screenPaddingH,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formulário: ${widget.tipoFormularioNome}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assistido: ${widget.pessoaNome}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.neutralGray,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: AppScreenChrome.whiteTopSheet(),
              child: widget.respostas.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma resposta preenchida.\nO envio será gravado apenas com assistido e formulário.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.neutralGray,
                            ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        20,
                        AppLayout.screenPaddingH,
                        16,
                      ),
                      itemCount: widget.respostas.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = widget.respostas[index];
                        final pergunta = perguntaMap[item.perguntaId]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pergunta.enunciado,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.neutralGray,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatResposta(pergunta, item),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppLayout.screenPaddingSymmetricH.copyWith(
                top: 12,
                bottom: AppLayout.screenPaddingBottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Voltar',
                      type: AppButtonType.secondary,
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Enviar',
                      onPressed: _submitting ||
                              !ref.watch(authProvider).podeIncluir(
                                Programas.lancamento,
                              )
                          ? null
                          : _submit,
                      loading: _submitting,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
