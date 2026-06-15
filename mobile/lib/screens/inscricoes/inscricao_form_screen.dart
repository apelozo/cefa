import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/aluno.dart';
import '../../models/inscricao.dart';
import '../../models/turma.dart';
import '../../models/inscricao_renda_familiar.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/data_br_hoje.dart';
import '../../utils/moeda_br.dart';
import '../../utils/snackbar.dart';
import '../../utils/telefone_formatter.dart';
import '../alunos/alunos_search_screen.dart';
import '../turmas/turmas_search_screen.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';
import 'inscricao_informacoes_gerais_tab.dart';
import 'inscricao_renda_familiar_tab.dart';
import 'inscricao_renda_linha.dart';

class InscricaoFormScreen extends ConsumerStatefulWidget {
  const InscricaoFormScreen({super.key, this.inscricao});

  final Inscricao? inscricao;

  bool get isEditing => inscricao != null;

  @override
  ConsumerState<InscricaoFormScreen> createState() =>
      _InscricaoFormScreenState();
}

class _InscricaoFormScreenState extends ConsumerState<InscricaoFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  late final TextEditingController _dtCursoController;
  late final TextEditingController _cursoSenacSenaiController;
  late final TextEditingController _orgaoEncaminhamentoController;
  late final TextEditingController _telefoneEncaminhamentoController;
  late final TextEditingController _qualNecessidadeController;
  late final TextEditingController _quaisMedicacoesController;
  late final TextEditingController _vacinacaoController;
  late final TextEditingController _alergiasController;

  String? _alunoId;
  String? _alunoLabel;
  Turma? _turmaSelecionada;
  String? _turmaLabel;
  bool _jaFezCursoSenacSenai = false;
  bool _possuiEncaminhamento = false;
  bool _possuiNecessidadeEspecial = false;
  bool _fazAcompanhamentoMedico = false;
  bool _tomaMedicacao = false;

  final List<InscricaoRendaLinha> _rendaLinhas = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final i = widget.inscricao;

    _dtCursoController = TextEditingController(
      text: i?.dtCurso ?? dataBrHojeCurta(),
    );
    _cursoSenacSenaiController =
        TextEditingController(text: i?.cursoSenacSenaiDescricao ?? '');
    _orgaoEncaminhamentoController =
        TextEditingController(text: i?.orgaoEncaminhamento ?? '');
    _telefoneEncaminhamentoController = TextEditingController(
      text: i?.telefoneEncaminhamentoFormatado ??
          i?.telefoneEncaminhamento ??
          '',
    );
    _qualNecessidadeController =
        TextEditingController(text: i?.qualNecessidade ?? '');
    _quaisMedicacoesController =
        TextEditingController(text: i?.quaisMedicacoes ?? '');
    _vacinacaoController = TextEditingController(text: i?.vacinacao ?? '');
    _alergiasController = TextEditingController(text: i?.alergias ?? '');

    _alunoId = i?.alunoId;
    _alunoLabel = i != null
        ? '${i.alunoNome}${i.alunoCpfFormatado != null ? ' — ${i.alunoCpfFormatado}' : ''}'
        : null;
    if (i != null) {
      _turmaSelecionada = Turma(
        id: '',
        codigo: i.turmaCodigo,
        nome: i.turmaNome,
        cursoCodigo: i.cursoCodigo,
        cursoDescricao: i.cursoDescricao,
        periodo: i.periodo,
        periodoRotulo: i.periodoRotulo,
        situacao: '',
        ativo: true,
      );
      _turmaLabel = _labelTurma(_turmaSelecionada!);
    }
    _jaFezCursoSenacSenai = i?.jaFezCursoSenacSenai ?? false;
    _possuiEncaminhamento = i?.possuiEncaminhamento ?? false;
    _possuiNecessidadeEspecial = i?.possuiNecessidadeEspecial ?? false;
    _fazAcompanhamentoMedico = i?.fazAcompanhamentoMedico ?? false;
    _tomaMedicacao = i?.tomaMedicacao ?? false;

    if (i != null && i.rendaFamiliar.isNotEmpty) {
      for (final r in i.rendaFamiliar) {
        _rendaLinhas.add(
          InscricaoRendaLinha(
            nome: r.nome,
            idade: r.idade?.toString() ?? '',
            renda: r.rendaFormatada ?? formatMoedaBr(r.renda),
            parentesco: r.parentesco ?? '',
            profissao: r.profissao ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dtCursoController.dispose();
    _cursoSenacSenaiController.dispose();
    _orgaoEncaminhamentoController.dispose();
    _telefoneEncaminhamentoController.dispose();
    _qualNecessidadeController.dispose();
    _quaisMedicacoesController.dispose();
    _vacinacaoController.dispose();
    _alergiasController.dispose();
    for (final linha in _rendaLinhas) {
      linha.dispose();
    }
    super.dispose();
  }

  String _labelAluno(Aluno aluno) {
    if (aluno.cpfFormatado != null && aluno.cpfFormatado!.isNotEmpty) {
      return '${aluno.nome} — ${aluno.cpfFormatado}';
    }
    return aluno.nome;
  }

  String _labelTurma(Turma turma) =>
      '${turma.codigo} — ${turma.nome} (${turma.cursoDescricao})';

  Future<void> _pesquisarAluno() async {
    final aluno = await AlunosSearchScreen.select(
      context,
      title: 'Pesquisar aluno',
      subtitle: widget.isEditing
          ? 'Inscrição ${widget.inscricao!.codigo}'
          : 'Nova inscrição',
    );
    if (!mounted || aluno == null) return;
    setState(() {
      _alunoId = aluno.id;
      _alunoLabel = _labelAluno(aluno);
    });
  }

  Future<void> _pesquisarTurma() async {
    final turma = await TurmasSearchScreen.select(
      context,
      title: 'Pesquisar turma',
      subtitle: widget.isEditing
          ? 'Inscrição ${widget.inscricao!.codigo}'
          : 'Nova inscrição',
      somenteAbertas: !widget.isEditing,
    );
    if (!mounted || turma == null) return;
    setState(() {
      _turmaSelecionada = turma;
      _turmaLabel = _labelTurma(turma);
    });
  }

  void _adicionarRendaLinha() {
    setState(() => _rendaLinhas.add(InscricaoRendaLinha()));
  }

  void _removerRendaLinha(int index) {
    setState(() {
      _rendaLinhas[index].dispose();
      _rendaLinhas.removeAt(index);
    });
  }

  bool _linhaRendaTemConteudo(InscricaoRendaLinha linha) {
    return linha.idade.text.trim().isNotEmpty ||
        linha.renda.text.trim().isNotEmpty ||
        linha.parentesco.text.trim().isNotEmpty ||
        linha.profissao.text.trim().isNotEmpty;
  }

  String? _validarAntesDeSalvar() {
    final dtErro = validateDataBr(_dtCursoController.text.trim());
    if (dtErro != null) {
      _tabController.animateTo(0);
      return dtErro;
    }
    if (_possuiEncaminhamento) {
      final telErro =
          validateTelefoneOpcional(_telefoneEncaminhamentoController.text);
      if (telErro != null) {
        _tabController.animateTo(0);
        return telErro;
      }
    }
    for (final linha in _rendaLinhas) {
      formatarMoedaBrNoController(linha.renda);
      if (_linhaRendaTemConteudo(linha) && linha.nome.text.trim().isEmpty) {
        _tabController.animateTo(1);
        return 'Informe o nome em todas as linhas de renda familiar preenchidas';
      }
    }
    return null;
  }

  List<InscricaoRendaFamiliar> _buildRendaPayload() {
    return _rendaLinhas
        .where((l) => l.nome.text.trim().isNotEmpty)
        .map((l) {
          formatarMoedaBrNoController(l.renda);
          final idadeText = l.idade.text.trim();
          return InscricaoRendaFamiliar(
            nome: l.nome.text.trim(),
            idade: idadeText.isEmpty ? null : int.tryParse(idadeText),
            renda: parseMoedaBr(l.renda.text),
            parentesco: l.parentesco.text.trim().isEmpty
                ? null
                : l.parentesco.text.trim(),
            profissao: l.profissao.text.trim().isEmpty
                ? null
                : l.profissao.text.trim(),
          );
        })
        .toList();
  }
  Future<void> _save() async {
    if (_alunoId == null) {
      showErrorSnackBar(context, 'Selecione o aluno');
      return;
    }
    if (_turmaSelecionada == null) {
      showErrorSnackBar(context, 'Selecione a turma');
      return;
    }
    final erroValidacao = _validarAntesDeSalvar();
    if (erroValidacao != null) {
      showErrorSnackBar(context, erroValidacao);
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = Inscricao(
        id: widget.inscricao?.id ?? '',
        codigo: widget.inscricao?.codigo ?? 0,
        alunoId: _alunoId!,
        alunoNome: _alunoLabel ?? '',
        turmaCodigo: _turmaSelecionada!.codigo,
        turmaNome: _turmaSelecionada!.nome,
        cursoCodigo: _turmaSelecionada!.cursoCodigo,
        cursoDescricao: _turmaSelecionada!.cursoDescricao,
        dtCurso: _dtCursoController.text.trim(),
        periodo: _turmaSelecionada!.periodo,
        periodoRotulo: _turmaSelecionada!.periodoRotulo,
        jaFezCursoSenacSenai: _jaFezCursoSenacSenai,
        cursoSenacSenaiDescricao: _jaFezCursoSenacSenai
            ? _cursoSenacSenaiController.text.trim()
            : null,
        possuiEncaminhamento: _possuiEncaminhamento,
        orgaoEncaminhamento: _possuiEncaminhamento
            ? _orgaoEncaminhamentoController.text.trim()
            : null,
        telefoneEncaminhamento: _possuiEncaminhamento
            ? normalizeTelefone(_telefoneEncaminhamentoController.text)
            : null,
        possuiNecessidadeEspecial: _possuiNecessidadeEspecial,
        qualNecessidade: _possuiNecessidadeEspecial
            ? _qualNecessidadeController.text.trim()
            : null,
        fazAcompanhamentoMedico: _fazAcompanhamentoMedico,
        tomaMedicacao: _tomaMedicacao,
        quaisMedicacoes: _tomaMedicacao
            ? _quaisMedicacoesController.text.trim()
            : null,
        vacinacao: _vacinacaoController.text.trim(),
        alergias: _alergiasController.text.trim(),
        rendaFamiliar: _buildRendaPayload(),
        ativo: widget.inscricao?.ativo ?? true,
      );

      final api = ref.read(apiClientProvider);
      final saved = widget.isEditing
          ? await api.updateInscricao(payload)
          : await api.createInscricao(payload);

      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSelecaoCampo({
    required String label,
    required String? valor,
    required String hint,
    required VoidCallback onPesquisar,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final temValor = valor != null && valor.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(
            temValor ? valor : hint,
            style: temValor
                ? textTheme.bodyLarge
                : textTheme.bodyLarge?.copyWith(
                    color: AppColors.neutralGray,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Pesquisar',
          type: AppButtonType.secondary,
          icon: Icons.search,
          onPressed: onPesquisar,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final podeSalvar = widget.isEditing
        ? ref.watch(authProvider).podeAlterar(Programas.inscricoes)
        : ref.watch(authProvider).podeIncluir(Programas.inscricoes);

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing
            ? 'Inscrição ${widget.inscricao!.codigo}'
            : 'Nova inscrição',
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        AppLayout.screenPaddingTop,
                        AppLayout.screenPaddingH,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.isEditing)
                            AppCard(
                              child: Text(
                                'Código da inscrição: ${widget.inscricao!.codigo}',
                                style: textTheme.titleSmall?.copyWith(
                                  fontFamily: AppTheme.fontFamily,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          if (widget.isEditing) const SizedBox(height: 12),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSelecaoCampo(
                                  label: 'Aluno',
                                  valor: _alunoLabel,
                                  hint: 'Nenhum aluno selecionado',
                                  onPesquisar: _pesquisarAluno,
                                ),
                                const SizedBox(height: 20),
                                _buildSelecaoCampo(
                                  label: 'Turma',
                                  valor: _turmaLabel,
                                  hint: 'Nenhuma turma selecionada',
                                  onPesquisar: _pesquisarTurma,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _InscricaoTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.primaryBlue,
                        unselectedLabelColor: AppColors.neutralGray,
                        indicatorColor: AppColors.primaryBlue,
                        labelStyle: textTheme.labelLarge?.copyWith(
                          fontFamily: AppTheme.fontFamily,
                        ),
                        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
                          fontFamily: AppTheme.fontFamily,
                        ),
                        tabs: const [
                          Tab(text: 'Informações Gerais'),
                          Tab(text: 'Renda Familiar'),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    InscricaoInformacoesGeraisTab(
                      dtCursoController: _dtCursoController,
                      jaFezCursoSenacSenai: _jaFezCursoSenacSenai,
                      onJaFezCursoSenacSenaiChanged: (v) =>
                          setState(() => _jaFezCursoSenacSenai = v),
                      cursoSenacSenaiController: _cursoSenacSenaiController,
                      possuiEncaminhamento: _possuiEncaminhamento,
                      onPossuiEncaminhamentoChanged: (v) =>
                          setState(() => _possuiEncaminhamento = v),
                      orgaoEncaminhamentoController:
                          _orgaoEncaminhamentoController,
                      telefoneEncaminhamentoController:
                          _telefoneEncaminhamentoController,
                      possuiNecessidadeEspecial: _possuiNecessidadeEspecial,
                      onPossuiNecessidadeEspecialChanged: (v) =>
                          setState(() => _possuiNecessidadeEspecial = v),
                      qualNecessidadeController: _qualNecessidadeController,
                      fazAcompanhamentoMedico: _fazAcompanhamentoMedico,
                      onFazAcompanhamentoMedicoChanged: (v) =>
                          setState(() => _fazAcompanhamentoMedico = v),
                      tomaMedicacao: _tomaMedicacao,
                      onTomaMedicacaoChanged: (v) => setState(() {
                        _tomaMedicacao = v;
                        if (!v) _quaisMedicacoesController.clear();
                      }),
                      quaisMedicacoesController: _quaisMedicacoesController,
                      vacinacaoController: _vacinacaoController,
                      alergiasController: _alergiasController,
                    ),
                    InscricaoRendaFamiliarTab(
                      linhas: _rendaLinhas,
                      onAdicionar: _adicionarRendaLinha,
                      onRemover: _removerRendaLinha,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppLayout.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isEditing)
                    AuditoriaSection(
                      auditoria: widget.inscricao!.auditoria,
                      mostrarExclusao: !widget.inscricao!.ativo,
                    ),
                  AppButton(
                    label: widget.isEditing ? 'Salvar' : 'Criar inscrição',
                    loading: _saving,
                    onPressed: podeSalvar && !_saving ? _save : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InscricaoTabBarDelegate extends SliverPersistentHeaderDelegate {
  _InscricaoTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _InscricaoTabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}
