import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/cancelamento_matricula.dart';
import '../../models/turma.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/matriculados_pdf.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/pdf_export_menu_button.dart';
import '../../widgets/permissao_gate.dart';
import '../turmas/turmas_search_screen.dart';

class CancelamentoMatriculaAlunosScreen extends ConsumerStatefulWidget {
  const CancelamentoMatriculaAlunosScreen({super.key});

  @override
  ConsumerState<CancelamentoMatriculaAlunosScreen> createState() =>
      _CancelamentoMatriculaAlunosScreenState();
}

class _CancelamentoMatriculaAlunosScreenState
    extends ConsumerState<CancelamentoMatriculaAlunosScreen> {
  Turma? _turma;
  CancelamentoMatriculaResult? _resultado;
  final Set<String> _selecionados = {};
  bool _loading = false;
  bool _saving = false;
  bool _exportandoPdf = false;

  int get _totalSelecionados => _selecionados.length;

  Future<void> _pesquisarTurma() async {
    final turma = await TurmasSearchScreen.select(
      context,
      title: 'Selecionar turma',
      subtitle: 'Cancelar matrícula de alunos no curso',
    );
    if (turma == null || !mounted) return;
    setState(() {
      _turma = turma;
      _resultado = null;
      _selecionados.clear();
    });
  }

  Future<void> _carregar() async {
    if (_turma == null) {
      showErrorSnackBar(context, 'Selecione a turma antes de carregar');
      return;
    }

    setState(() => _loading = true);
    try {
      final resultado = await ref
          .read(apiClientProvider)
          .listCancelamentoMatriculaMatriculados(turmaCodigo: _turma!.codigo);
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _selecionados.clear();
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSelecao(CancelamentoMatriculaAluno aluno, bool? value) {
    setState(() {
      if (value == true) {
        _selecionados.add(aluno.id);
      } else {
        _selecionados.remove(aluno.id);
      }
    });
  }

  Future<void> _gerarPdf({required bool visualizar}) async {
    final resultado = _resultado;
    if (resultado == null || _exportandoPdf) return;
    if (resultado.totalMatriculados == 0) {
      showErrorSnackBar(
        context,
        'Não há alunos matriculados para gerar o relatório',
      );
      return;
    }

    final usuario = ref.read(authProvider).usuario;
    final geradoPor = nomeGeradorRelatorio(
      nome: usuario?.nome,
      nomeUsuario: usuario?.nomeUsuario,
    );

    setState(() => _exportandoPdf = true);
    try {
      if (visualizar) {
        await MatriculadosPdf.visualizar(resultado, geradoPor: geradoPor);
      } else {
        await MatriculadosPdf.exportar(resultado, geradoPor: geradoPor);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Não foi possível gerar o PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _exportandoPdf = false);
    }
  }

  Future<void> _gravar() async {
    if (!ref
        .read(authProvider)
        .podeAlterar(Programas.cancelamentoMatriculaAlunos)) {
      return;
    }

    if (_turma == null || _resultado == null) {
      showErrorSnackBar(context, 'Carregue os alunos matriculados antes de gravar');
      return;
    }
    if (_selecionados.isEmpty) {
      showErrorSnackBar(
        context,
        'Selecione ao menos um aluno para cancelar a matrícula',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final resultado =
          await ref.read(apiClientProvider).gravarCancelamentoMatricula(
                turmaCodigo: _turma!.codigo,
                inscricaoIds: _selecionados.toList(growable: false),
              );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _selecionados.clear();
      });
      showSuccessSnackBar(context, 'Cancelamento de matrícula gravado com sucesso');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _labelTurma(Turma turma) =>
      '${turma.codigo} — ${turma.nome} (${turma.cursoDescricao})';

  Widget _buildMatriculadoLinha(CancelamentoMatriculaAluno aluno) {
    final selecionado = _selecionados.contains(aluno.id);
    final idade = aluno.alunoIdade != null ? '${aluno.alunoIdade} anos' : '—';
    final escolaridade = aluno.escolaridadeDescricao ?? '—';
    final orgao = aluno.orgaoEncaminhamento ?? '—';
    final dataMatricula = aluno.dataMatricula ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Cancelar',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: selecionado,
                onChanged: (v) => _toggleSelecao(aluno, v),
              ),
            ),
            _campoLinha('Nome', aluno.alunoNome, destaque: true),
            _campoLinha('Data da matrícula', dataMatricula),
            _campoLinha('Idade', idade),
            _campoLinha('Escolaridade', escolaridade),
            _campoLinha('Órgão encaminhamento', orgao),
          ],
        ),
      ),
    );
  }

  Widget _campoLinha(String label, String valor, {bool destaque = false}) {
    final styleBase = destaque
        ? Theme.of(context).textTheme.bodyLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: RichText(
        text: TextSpan(
          style: styleBase?.copyWith(color: AppColors.darkGray),
          children: [
            TextSpan(
              text: '$label: ',
              style: styleBase?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podeAlterar = ref
        .watch(authProvider)
        .podeAlterar(Programas.cancelamentoMatriculaAlunos);

    return PermissaoGate(
      programaCodigo: Programas.cancelamentoMatriculaAlunos,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Cancelar Matrícula de Alunos no Curso',
          actions: [
            PdfExportMenuButton(
              enabled: _resultado != null && _resultado!.totalMatriculados > 0,
              loading: _exportandoPdf,
              onVisualizar: () => _gerarPdf(visualizar: true),
              onExportar: () => _gerarPdf(visualizar: false),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppLayout.screenPadding,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Turma / curso',
                          ),
                          child: Text(
                            _turma != null
                                ? _labelTurma(_turma!)
                                : 'Nenhuma turma selecionada',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Pesquisar turma',
                          onPressed: _pesquisarTurma,
                          type: AppButtonType.secondary,
                          icon: Icons.search,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: _loading
                              ? 'Carregando…'
                              : 'Carregar alunos matriculados',
                          onPressed: (_loading || _turma == null)
                              ? null
                              : _carregar,
                        ),
                        if (_turma == null && _resultado == null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Selecione a turma e toque em Carregar alunos matriculados.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.slate,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_resultado != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_resultado!.cursoDescricao} — ${_resultado!.turmaNome}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_resultado!.periodoRotulo != null)
                            Text(
                              'Período: ${_resultado!.periodoRotulo}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Matriculados: ${_resultado!.totalMatriculados}'
                            ' · A cancelar: $_totalSelecionados',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const Divider(height: 24),
                          if (_resultado!.matriculados.isEmpty)
                            Text(
                              'Nenhum aluno matriculado ativo nesta turma.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else
                            ..._resultado!.matriculados
                                .map(_buildMatriculadoLinha),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (podeAlterar)
              Padding(
                padding: AppLayout.screenPadding,
                child: AppButton(
                  label: _saving ? 'Gravando…' : 'Gravar cancelamento',
                  onPressed: (_saving ||
                          _resultado == null ||
                          _selecionados.isEmpty)
                      ? null
                      : _gravar,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
