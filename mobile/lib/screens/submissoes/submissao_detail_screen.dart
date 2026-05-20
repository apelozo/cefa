import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/submissao.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/resposta_display.dart';
import '../../utils/snackbar.dart';
import '../../utils/submissao_pdf.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';

class SubmissaoDetailScreen extends ConsumerStatefulWidget {
  const SubmissaoDetailScreen({super.key, required this.submissaoId});

  final String submissaoId;

  @override
  ConsumerState<SubmissaoDetailScreen> createState() =>
      _SubmissaoDetailScreenState();
}

class _SubmissaoDetailScreenState extends ConsumerState<SubmissaoDetailScreen> {
  Submissao? _submissao;
  bool _loading = true;
  bool _exportandoPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s =
          await ref.read(apiClientProvider).getSubmissao(widget.submissaoId);
      if (mounted) setState(() => _submissao = s);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _gerarPdf({required bool visualizar}) async {
    final s = _submissao;
    if (s == null || _exportandoPdf) return;

    setState(() => _exportandoPdf = true);
    try {
      if (visualizar) {
        await SubmissaoPdf.visualizar(s);
      } else {
        await SubmissaoPdf.exportar(s);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Não foi possível gerar o PDF: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _exportandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissaoGate(
      programaCodigo: Programas.submissoes,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Consulta de respostas',
          actions: [
            if (_submissao != null)
              PopupMenuButton<String>(
                tooltip: 'PDF',
                enabled: !_exportandoPdf,
                icon: _exportandoPdf
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                onSelected: (value) {
                  if (value == 'visualizar') {
                    _gerarPdf(visualizar: true);
                  } else if (value == 'exportar') {
                    _gerarPdf(visualizar: false);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'visualizar',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Visualizar PDF'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'exportar',
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Baixar / compartilhar PDF'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _submissao == null
                ? const Center(child: Text('Submissão não encontrada'))
                : _buildContent(context, _submissao!),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Submissao s) {
    final respostas = [...s.respostas]
      ..sort((a, b) => a.perguntaOrdem.compareTo(b.perguntaOrdem));

    return Column(
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
              Text(
                s.tipoFormularioNome,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Pessoa: ${s.pessoaNome}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'CPF: ${s.pessoaCpfFormatado}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutralGray,
                    ),
              ),
              Text(
                'Enviado em ${formatSubmissaoData(s.createdAt)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutralGray,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${respostas.length} resposta(s) · use o ícone PDF no topo para exportar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutralGray,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: AppScreenChrome.whiteTopSheet(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                20,
                AppLayout.screenPaddingH,
                AppLayout.screenPaddingBottom,
              ),
              itemCount: respostas.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = respostas[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.perguntaOrdem}. ${r.perguntaEnunciado}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatRespostaSubmissao(r),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
