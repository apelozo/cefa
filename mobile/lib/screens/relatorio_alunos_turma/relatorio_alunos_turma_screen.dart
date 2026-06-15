import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../constants/relatorio_alunos_turma.dart';
import '../../models/curso.dart';
import '../../models/relatorio_alunos_turma.dart';
import '../../models/turma.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/relatorio_alunos_turma_pdf.dart';
import '../../utils/matriculados_pdf.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/pdf_export_menu_button.dart';
import '../../widgets/permissao_gate.dart';

class RelatorioAlunosTurmaScreen extends ConsumerStatefulWidget {
  const RelatorioAlunosTurmaScreen({super.key});

  @override
  ConsumerState<RelatorioAlunosTurmaScreen> createState() =>
      _RelatorioAlunosTurmaScreenState();
}

class _RelatorioAlunosTurmaScreenState
    extends ConsumerState<RelatorioAlunosTurmaScreen> {
  static const _todosCursos = -1;
  static const _todasTurmas = -1;

  List<Curso> _cursos = [];
  List<Turma> _turmas = [];
  bool _loadingCursos = true;
  bool _loadingTurmas = false;
  bool _gerando = false;
  bool _exportandoPdf = false;
  bool _pendingTurmaFocus = false;

  final _cursoFocusNode = FocusNode();
  final _turmaFocusNode = FocusNode();

  int _cursoCodigo = _todosCursos;
  int _turmaCodigo = _todasTurmas;
  String _situacao = SituacaoRelatorioAlunos.todas;
  String _tipoRelatorio = TipoRelatorioAlunosTurma.resumido;

  RelatorioAlunosTurmaResult? _resultado;

  bool get _todosCursosSelecionado => _cursoCodigo == _todosCursos;

  bool _cursosLoadIniciado = false;

  @override
  void initState() {
    super.initState();
    _cursoFocusNode.addListener(_onCursoFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cursosLoadIniciado) {
      _cursosLoadIniciado = true;
      _loadCursos();
    }
  }

  @override
  void dispose() {
    _cursoFocusNode.removeListener(_onCursoFocusChange);
    _cursoFocusNode.dispose();
    _turmaFocusNode.dispose();
    super.dispose();
  }

  void _onCursoFocusChange() {
    if (_cursoFocusNode.hasFocus) return;
    _aoSairFocoCurso();
  }

  void _aoSairFocoCurso() {
    if (_todosCursosSelecionado) return;
    _pendingTurmaFocus = true;
    if (_loadingTurmas) return;
    if (_turmas.isEmpty) {
      _loadTurmas(_cursoCodigo);
      return;
    }
    _pendingTurmaFocus = false;
    _requestTurmaFocus();
  }

  void _requestTurmaFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _todosCursosSelecionado) return;
      _turmaFocusNode.requestFocus();
    });
  }

  void _maybeFocusTurmaAfterLoad() {
    if (!_pendingTurmaFocus || _todosCursosSelecionado || !mounted) return;
    _pendingTurmaFocus = false;
    _requestTurmaFocus();
  }

  Future<void> _loadCursos() async {
    if (!mounted) return;
    setState(() => _loadingCursos = true);
    try {
      final items =
          await ref.read(apiClientProvider).listRelatorioAlunosTurmaCursos();
      if (!mounted) return;
      setState(() {
        _cursos = items..sort((a, b) => a.descricao.compareTo(b.descricao));
        _loadingCursos = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCursos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _loadTurmas(int cursoCodigo) async {
    setState(() {
      _loadingTurmas = true;
      _turmas = [];
      _turmaCodigo = _todasTurmas;
      _resultado = null;
    });
    try {
      final items = await ref.read(apiClientProvider).listRelatorioAlunosTurmaTurmas(
            cursoCodigo: cursoCodigo,
          );
      if (!mounted) return;
      setState(() {
        _turmas = items..sort((a, b) => a.codigo.compareTo(b.codigo));
        _loadingTurmas = false;
      });
      _maybeFocusTurmaAfterLoad();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTurmas = false;
          _pendingTurmaFocus = false;
        });
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  void _onCursoChanged(int? value) {
    if (value == null) return;
    setState(() {
      _cursoCodigo = value;
      _turmaCodigo = _todasTurmas;
      _resultado = null;
      _turmas = [];
      if (value == _todosCursos) {
        _pendingTurmaFocus = false;
      }
    });
    if (value != _todosCursos) {
      _loadTurmas(value);
    }
  }

  void _onTurmaChanged(int? value) {
    if (value == null) return;
    setState(() {
      _turmaCodigo = value;
      _resultado = null;
    });
  }

  void _onSituacaoChanged(String? value) {
    if (value == null) return;
    setState(() {
      _situacao = value;
      _resultado = null;
    });
  }

  void _onTipoRelatorioChanged(String? value) {
    if (value == null) return;
    setState(() {
      _tipoRelatorio = value;
      _resultado = null;
    });
  }

  Future<void> _gerarRelatorio() async {
    setState(() {
      _gerando = true;
      _resultado = null;
    });
    try {
      final resultado = await ref.read(apiClientProvider).relatorioAlunosTurma(
            cursoCodigo: _todosCursosSelecionado ? null : _cursoCodigo,
            turmaCodigo:
                _todosCursosSelecionado || _turmaCodigo == _todasTurmas
                    ? null
                    : _turmaCodigo,
            situacao: _situacao,
          );
      if (!mounted) return;
      setState(() => _resultado = resultado);
      if (resultado.secoes.isEmpty) {
        showErrorSnackBar(
          context,
          'Nenhuma turma encontrada para os filtros selecionados.',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  String get _geradoPor {
    final auth = ref.read(authProvider);
    return nomeGeradorRelatorio(
      nome: auth.usuario?.nome,
      nomeUsuario: auth.usuario?.nomeUsuario,
    );
  }

  Future<void> _visualizarPdf() async {
    final dados = _resultado;
    if (dados == null) return;
    setState(() => _exportandoPdf = true);
    try {
      await RelatorioAlunosTurmaPdf.visualizar(
        dados,
        tipoRelatorio: _tipoRelatorio,
        geradoPor: _geradoPor,
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _exportandoPdf = false);
    }
  }

  Future<void> _exportarPdf() async {
    final dados = _resultado;
    if (dados == null) return;
    setState(() => _exportandoPdf = true);
    try {
      await RelatorioAlunosTurmaPdf.exportar(
        dados,
        tipoRelatorio: _tipoRelatorio,
        geradoPor: _geradoPor,
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _exportandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PermissaoGate(
      programaCodigo: Programas.relatorioAlunosTurma,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Relatório de Alunos da Turma',
          actions: [
            PdfExportMenuButton(
              enabled: _resultado != null && !_gerando,
              loading: _exportandoPdf,
              onVisualizar: _visualizarPdf,
              onExportar: _exportarPdf,
            ),
          ],
        ),
        body:
            _loadingCursos
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
          padding: AppLayout.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Parâmetros do relatório',
                      style: textTheme.titleMedium?.copyWith(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey('curso-${_cursos.length}'),
                      focusNode: _cursoFocusNode,
                      value: _cursoCodigo,
                      decoration: const InputDecoration(
                        labelText: 'Curso',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: _todosCursos,
                          child: Text('Todos os cursos'),
                        ),
                        ..._cursos.map(
                          (c) => DropdownMenuItem(
                            value: c.codigo,
                            child: Text('${c.codigo} — ${c.descricao}'),
                          ),
                        ),
                      ],
                      onChanged: _onCursoChanged,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      key: ValueKey('turma-${_turmas.length}-$_cursoCodigo'),
                      focusNode: _turmaFocusNode,
                      value: _turmaCodigo,
                      decoration: InputDecoration(
                        labelText: 'Turma',
                        border: const OutlineInputBorder(),
                        helperText:
                            _todosCursosSelecionado
                                ? 'Disponível ao selecionar um curso específico'
                                : _loadingTurmas
                                ? 'Carregando turmas…'
                                : null,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: _todasTurmas,
                          child: Text('Todas as turmas'),
                        ),
                        ..._turmas.map(
                          (t) => DropdownMenuItem(
                            value: t.codigo,
                            child: Text(t.rotuloExibicao),
                          ),
                        ),
                      ],
                      onChanged:
                          _todosCursosSelecionado || _loadingTurmas
                              ? null
                              : _onTurmaChanged,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _situacao,
                      decoration: const InputDecoration(
                        labelText: 'Situação',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          SituacaoRelatorioAlunos.opcoes.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                      onChanged: _onSituacaoChanged,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _tipoRelatorio,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de relatório',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          TipoRelatorioAlunosTurma.opcoes.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                      onChanged: _onTipoRelatorioChanged,
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: _gerando ? 'Gerando…' : 'Gerar relatório',
                      icon: Icons.analytics_outlined,
                      onPressed: _gerando ? null : _gerarRelatorio,
                      loading: _gerando,
                    ),
                  ],
                ),
              ),
              if (_resultado != null) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prévia',
                        style: textTheme.titleMedium?.copyWith(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_resultado!.secoes.length} turma(s) no relatório. '
                        'Use o ícone PDF no topo para visualizar ou exportar.',
                        style: textTheme.bodyMedium?.copyWith(
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      if (_resultado!.resumoGeral.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._resultado!.resumoGeral.map((r) {
                          final partes = <String>[
                            '${r.cursoDescricao} — ${r.turmaNome}:',
                            '${r.matriculados} matriculado(s)',
                            '${r.matriculasCanceladas} cancelada(s)',
                          ];
                          if (r.situacaoTurma == 'ABERTA') {
                            partes.add('${r.aMatricular ?? 0} a matricular');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              partes.join(' · '),
                              style: textTheme.bodySmall?.copyWith(
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
