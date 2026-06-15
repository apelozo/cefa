import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../constants/periodo_inscricao.dart';
import '../../models/aluno.dart';
import '../../models/curso.dart';
import '../../models/inscricao.dart';
import '../../models/turma.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import '../alunos/alunos_search_screen.dart';
import '../cursos/cursos_search_screen.dart';
import '../turmas/turmas_search_screen.dart';
import 'inscricao_form_screen.dart';

class InscricoesListScreen extends ConsumerStatefulWidget {
  const InscricoesListScreen({super.key});

  @override
  ConsumerState<InscricoesListScreen> createState() =>
      _InscricoesListScreenState();
}

class _InscricoesListScreenState extends ConsumerState<InscricoesListScreen> {
  List<Inscricao>? _inscricoes;
  bool _loading = false;
  bool _mostrarInativos = false;

  String? _alunoId;
  String? _alunoLabel;
  int? _cursoCodigo;
  String? _cursoLabel;
  int? _turmaCodigo;
  String? _turmaLabel;

  bool get _temFiltroBusca =>
      _alunoId != null || _cursoCodigo != null || _turmaCodigo != null;

  Future<void> _load() async {
    if (!_temFiltroBusca) {
      showErrorSnackBar(
        context,
        'Selecione ao menos um filtro (Aluno, Curso ou Turma) antes de buscar',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listInscricoes(
            ativo: _mostrarInativos ? null : true,
            alunoId: _alunoId,
            cursoCodigo: _cursoCodigo,
            turmaCodigo: _turmaCodigo,
          );
      if (mounted) setState(() => _inscricoes = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _limparFiltros() {
    setState(() {
      _alunoId = null;
      _alunoLabel = null;
      _cursoCodigo = null;
      _cursoLabel = null;
      _turmaCodigo = null;
      _turmaLabel = null;
      _inscricoes = null;
    });
  }

  String _labelAluno(Aluno aluno) {
    if (aluno.cpfFormatado != null && aluno.cpfFormatado!.isNotEmpty) {
      return '${aluno.nome} — ${aluno.cpfFormatado}';
    }
    return aluno.nome;
  }

  String _labelCurso(Curso curso) => '${curso.codigo} — ${curso.descricao}';

  String _labelTurma(Turma turma) =>
      '${turma.codigo} — ${turma.nome} (${turma.cursoDescricao})';

  Future<void> _pesquisarAluno() async {
    final aluno = await AlunosSearchScreen.select(
      context,
      title: 'Filtrar por aluno',
      subtitle: 'Inscrição em curso',
    );
    if (!mounted || aluno == null) return;
    setState(() {
      _alunoId = aluno.id;
      _alunoLabel = _labelAluno(aluno);
    });
  }

  Future<void> _pesquisarCurso() async {
    final curso = await CursosSearchScreen.select(
      context,
      title: 'Filtrar por curso',
      subtitle: 'Inscrição em curso',
    );
    if (!mounted || curso == null) return;
    setState(() {
      _cursoCodigo = curso.codigo;
      _cursoLabel = _labelCurso(curso);
    });
  }

  Future<void> _pesquisarTurma() async {
    final turma = await TurmasSearchScreen.select(
      context,
      title: 'Filtrar por turma',
      subtitle: 'Inscrição em curso',
    );
    if (!mounted || turma == null) return;
    setState(() {
      _turmaCodigo = turma.codigo;
      _turmaLabel = _labelTurma(turma);
    });
  }

  Future<void> _openForm([Inscricao? inscricao]) async {
    final auth = ref.read(authProvider);
    if (inscricao == null && !auth.podeIncluir(Programas.inscricoes)) {
      return;
    }
    if (inscricao != null && !auth.podeAlterar(Programas.inscricoes)) {
      return;
    }
    if (inscricao != null && !inscricao.ativo) {
      showErrorSnackBar(
        context,
        'Inscrição desativada não pode ser editada.',
      );
      return;
    }

    Inscricao? completa = inscricao;
    if (inscricao != null) {
      try {
        completa =
            await ref.read(apiClientProvider).getInscricao(inscricao.id);
      } catch (e) {
        if (mounted) showErrorSnackBar(context, e.toString());
        return;
      }
    }

    if (!mounted) return;
    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => InscricaoFormScreen(inscricao: completa),
      ),
    );
    if ((saved == true || saved is Inscricao) && _temFiltroBusca) _load();
  }

  Future<void> _desativar(Inscricao inscricao) async {
    if (!ref.read(authProvider).podeExcluir(Programas.inscricoes)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar inscrição?'),
        content: Text(
          'Inscrição ${inscricao.codigo} — ${inscricao.alunoNome} / '
          '${inscricao.cursoDescricao} será desativada.\n\n'
          'O registro permanece no banco.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(apiClientProvider).desativarInscricao(inscricao.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Inscrição desativada');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  String _mensagemListaVazia() {
    if (!_temFiltroBusca || _inscricoes == null) {
      return 'Selecione ao menos um filtro (Aluno, Curso ou Turma) '
          'e toque em Buscar para listar as inscrições.';
    }
    if (_mostrarInativos) {
      return 'Nenhuma inscrição encontrada para os filtros informados.';
    }
    return 'Nenhuma inscrição ativa para os filtros informados.\n'
        'Ative "Inativos" para incluir desativadas.';
  }

  Widget _buildFiltroCampo({
    required String label,
    required String? valor,
    required VoidCallback onPesquisar,
    required VoidCallback? onLimpar,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final temValor = valor != null && valor.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(labelText: label, isDense: true),
            child: Text(
              temValor ? valor : 'Não selecionado',
              style: temValor
                  ? textTheme.bodyMedium
                  : textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutralGray,
                    ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Pesquisar $label',
          onPressed: onPesquisar,
          icon: const Icon(Icons.search),
        ),
        if (onLimpar != null)
          IconButton(
            tooltip: 'Limpar $label',
            onPressed: onLimpar,
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }

  TextStyle _estiloValorCard({double? fontSize, FontWeight? fontWeight}) {
    final base = Theme.of(context).textTheme.bodySmall;
    return TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: fontSize ?? base?.fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: base?.color,
    );
  }

  TextStyle get _estiloLabelCard => _estiloValorCard(fontWeight: FontWeight.bold);

  TextSpan _campoLinha(String label, String valor, {TextStyle? valorStyle}) {
    return TextSpan(
      children: [
        TextSpan(text: '$label: ', style: _estiloLabelCard),
        TextSpan(
          text: valor,
          style: valorStyle ?? _estiloValorCard(),
        ),
      ],
    );
  }

  TextSpan _campoPeriodoComStatus(Inscricao item, String periodo) {
    final estiloStatus = _estiloValorCard(fontWeight: FontWeight.bold);
    return TextSpan(
      children: [
        TextSpan(text: 'Período: ', style: _estiloLabelCard),
        TextSpan(text: periodo, style: _estiloValorCard()),
        if (item.matriculaCancelada)
          TextSpan(text: ' - Matricula Cancelada', style: estiloStatus)
        else if (item.matriculado)
          TextSpan(text: ' - MATRICULADO', style: estiloStatus),
      ],
    );
  }

  Widget _linhaResumoCard(Inscricao item, String periodo) {
    const separador = TextSpan(text: ' · ');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text.rich(
        TextSpan(
          children: [
            _campoLinha(
              'Nome',
              item.alunoNome,
              valorStyle: _estiloValorCard(
                fontSize:
                    (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) + 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            separador,
            _campoLinha('CPF', item.alunoCpfFormatado ?? '—'),
            separador,
            _campoLinha('Curso', item.cursoDescricao),
            separador,
            _campoLinha('Turma', item.turmaNome),
            separador,
            _campoLinha('Data de inscrição', item.dtCurso),
            separador,
            _campoPeriodoComStatus(item, periodo),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.inscricoes);
    final podeAlterar = auth.podeAlterar(Programas.inscricoes);
    final podeExcluir = auth.podeExcluir(Programas.inscricoes);

    return PermissaoGate(
      programaCodigo: Programas.inscricoes,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Inscrição em curso',
          actions: [
            FilterChip(
              label: const Text('Inativos'),
              selected: _mostrarInativos,
              onSelected: _loading
                  ? null
                  : (v) {
                      setState(() => _mostrarInativos = v);
                      if (_temFiltroBusca && _inscricoes != null) {
                        _load();
                      }
                    },
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: podeIncluir
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                AppLayout.screenPaddingTop,
                AppLayout.screenPaddingH,
                0,
              ),
              child: Column(
                children: [
                  _buildFiltroCampo(
                    label: 'Aluno',
                    valor: _alunoLabel,
                    onPesquisar: _pesquisarAluno,
                    onLimpar: _alunoId != null
                        ? () => setState(() {
                              _alunoId = null;
                              _alunoLabel = null;
                            })
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildFiltroCampo(
                    label: 'Curso',
                    valor: _cursoLabel,
                    onPesquisar: _pesquisarCurso,
                    onLimpar: _cursoCodigo != null
                        ? () => setState(() {
                              _cursoCodigo = null;
                              _cursoLabel = null;
                            })
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildFiltroCampo(
                    label: 'Turma',
                    valor: _turmaLabel,
                    onPesquisar: _pesquisarTurma,
                    onLimpar: _turmaCodigo != null
                        ? () => setState(() {
                              _turmaCodigo = null;
                              _turmaLabel = null;
                            })
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Buscar',
                          onPressed: (_loading || !_temFiltroBusca) ? null : _load,
                          loading: _loading,
                        ),
                      ),
                      if (_temFiltroBusca) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _loading ? null : _limparFiltros,
                          child: const Text('Limpar filtros'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(child: _buildList(podeAlterar, podeExcluir)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool podeAlterar, bool podeExcluir) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_inscricoes == null || _inscricoes!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            _mensagemListaVazia(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: () async {
        if (_temFiltroBusca) await _load();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.screenPaddingH,
          8,
          AppLayout.screenPaddingH,
          88,
        ),
        itemCount: _inscricoes!.length,
        itemBuilder: (context, index) {
          final item = _inscricoes![index];
          final periodo =
              item.periodoRotulo ?? PeriodoInscricao.rotulo(item.periodo);

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!item.ativo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Inativo',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                    ),
                  ),
                _linhaResumoCard(item, periodo),
                const SizedBox(height: 12),
                RecordActionButtons(
                  onEdit: podeAlterar && item.ativo
                      ? () => _openForm(item)
                      : null,
                  onDelete: podeExcluir && item.ativo
                      ? () => _desativar(item)
                      : null,
                  deleteTooltip: 'Desativar',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
