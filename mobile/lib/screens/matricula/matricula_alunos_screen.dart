import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/matricula_candidato.dart';
import '../../models/turma.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/data_br_hoje.dart';
import '../../utils/matriculados_pdf.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/pdf_export_menu_button.dart';
import '../../widgets/permissao_gate.dart';
import '../turmas/turmas_search_screen.dart';

class MatriculaAlunosScreen extends ConsumerStatefulWidget {
  const MatriculaAlunosScreen({super.key});

  @override
  ConsumerState<MatriculaAlunosScreen> createState() =>
      _MatriculaAlunosScreenState();
}

class _MatriculaAlunosScreenState extends ConsumerState<MatriculaAlunosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vagasController = TextEditingController();
  final _dtInicioController =
      TextEditingController(text: dataBrHojeCurta());

  Turma? _turma;
  MatriculaCandidatosResult? _resultado;
  final Set<String> _selecionados = {};
  bool _loading = false;
  bool _saving = false;
  bool _bloqueado = false;
  bool _exportandoPdf = false;

  @override
  void initState() {
    super.initState();
    _vagasController.addListener(_onFiltroAlterado);
    _dtInicioController.addListener(_onFiltroAlterado);
  }

  @override
  void dispose() {
    _vagasController.removeListener(_onFiltroAlterado);
    _dtInicioController.removeListener(_onFiltroAlterado);
    _vagasController.dispose();
    _dtInicioController.dispose();
    super.dispose();
  }

  void _onFiltroAlterado() {
    if (_resultado == null) return;
    setState(() {
      _resultado = null;
      _selecionados.clear();
      _bloqueado = false;
    });
  }

  bool get _filtrosPreenchidos {
    if (_vagas == null || _turma == null) return false;
    return validateDataBr(_dtInicioController.text) == null;
  }

  int? get _vagas {
    final v = int.tryParse(_vagasController.text.trim());
    if (v == null || v < 1) return null;
    return v;
  }

  int get _vagasDisponiveis {
    final vagas = _vagas;
    if (vagas == null || _resultado == null) return 0;
    return (vagas - _resultado!.totalMatriculados).clamp(0, vagas);
  }

  int get _totalSelecionados => _selecionados.length;

  void _aplicarSelecaoInicial(MatriculaCandidatosResult resultado, int vagas) {
    _selecionados.clear();
    _bloqueado = resultado.totalMatriculados >= vagas;

    if (!_bloqueado) {
      var restantes = vagas - resultado.totalMatriculados;
      for (final c in resultado.candidatos) {
        if (restantes <= 0) break;
        if (!c.matriculado) {
          _selecionados.add(c.id);
          restantes--;
        }
      }
    }
  }

  Future<void> _pesquisarTurma() async {
    final turma = await TurmasSearchScreen.select(
      context,
      title: 'Selecionar turma',
      subtitle: 'Matricular alunos no curso',
    );
    if (turma == null || !mounted) return;
    setState(() {
      _turma = turma;
      _resultado = null;
      _selecionados.clear();
      _bloqueado = false;
    });
  }

  Future<void> _carregar() async {
    if (!_filtrosPreenchidos) {
      showErrorSnackBar(
        context,
        'Preencha vagas, turma e data da matrícula antes de carregar',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final vagas = _vagas!;

    setState(() => _loading = true);
    try {
      final resultado = await ref
          .read(apiClientProvider)
          .listMatriculaCandidatos(turmaCodigo: _turma!.codigo);
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _aplicarSelecaoInicial(resultado, vagas);
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSelecao(MatriculaCandidato candidato, bool? value) {
    if (candidato.matriculado || _bloqueado) return;

    final limite = _vagasDisponiveis;
    setState(() {
      if (value == true) {
        if (_selecionados.length >= limite) {
          showErrorSnackBar(
            context,
            limite == 0
                ? 'Não há vagas disponíveis para novas matrículas'
                : 'Não é possível selecionar mais de $limite aluno(s)',
          );
          return;
        }
        _selecionados.add(candidato.id);
      } else {
        _selecionados.remove(candidato.id);
      }
    });
  }

  Future<void> _gerarPdf({required bool visualizar}) async {
    if (_turma == null || _exportandoPdf) return;
    if (_resultado == null || _resultado!.totalMatriculados == 0) {
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
      final matriculados = await ref
          .read(apiClientProvider)
          .listCancelamentoMatriculaMatriculados(turmaCodigo: _turma!.codigo);
      if (!mounted) return;
      if (matriculados.totalMatriculados == 0) {
        showErrorSnackBar(
          context,
          'Não há alunos matriculados para gerar o relatório',
        );
        return;
      }
      if (visualizar) {
        await MatriculadosPdf.visualizar(matriculados, geradoPor: geradoPor);
      } else {
        await MatriculadosPdf.exportar(matriculados, geradoPor: geradoPor);
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
    if (!ref.read(authProvider).podeAlterar(Programas.matriculaAlunos)) return;

    if (!_formKey.currentState!.validate()) return;
    final vagas = _vagas;
    if (vagas == null) {
      showErrorSnackBar(context, 'Informe a quantidade de vagas');
      return;
    }
    if (_turma == null || _resultado == null) {
      showErrorSnackBar(context, 'Carregue os candidatos antes de gravar');
      return;
    }
    if (_selecionados.isEmpty) {
      showErrorSnackBar(
        context,
        'Selecione ao menos um aluno para matricular',
      );
      return;
    }
    final limite = _vagasDisponiveis;
    if (_selecionados.length > limite) {
      showErrorSnackBar(
        context,
        limite == 0
            ? 'Não há vagas disponíveis para novas matrículas'
            : 'Selecionados (${_selecionados.length}) excedem as vagas disponíveis ($limite)',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final idsNovos = _resultado!.candidatos
          .where((c) => !c.matriculado && _selecionados.contains(c.id))
          .map((c) => c.id)
          .toList(growable: false);
      final resultado = await ref.read(apiClientProvider).gravarMatricula(
            turmaCodigo: _turma!.codigo,
            dtInicioCurso: _dtInicioController.text.trim(),
            vagas: vagas,
            inscricaoIds: idsNovos,
          );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _aplicarSelecaoInicial(resultado, vagas);
      });
      showSuccessSnackBar(context, 'Matrícula gravada com sucesso');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _labelTurma(Turma turma) =>
      '${turma.codigo} — ${turma.nome} (${turma.cursoDescricao})';

  Widget _buildCandidatoLinha(MatriculaCandidato c) {
    final jaMatriculado = c.matriculado;
    final selecionado = jaMatriculado || _selecionados.contains(c.id);
    final idade = c.alunoIdade != null ? '${c.alunoIdade} anos' : '—';
    final escolaridade = c.escolaridadeDescricao ?? '—';
    final orgao = c.orgaoEncaminhamento ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 130,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  jaMatriculado ? 'Matriculado' : 'Matricular',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: selecionado,
                onChanged: (jaMatriculado || _bloqueado)
                    ? null
                    : (v) => _toggleSelecao(c, v),
              ),
            ),
            _campoLinha('Nome', c.alunoNome, destaque: true),
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
    final podeAlterar =
        ref.watch(authProvider).podeAlterar(Programas.matriculaAlunos);
    final vagas = _vagas;

    return PermissaoGate(
      programaCodigo: Programas.matriculaAlunos,
      child: AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: 'Matricular Alunos no Curso',
        actions: [
          PdfExportMenuButton(
            enabled:
                _resultado != null && _resultado!.totalMatriculados > 0,
            loading: _exportandoPdf,
            onVisualizar: () => _gerarPdf(visualizar: true),
            onExportar: () => _gerarPdf(visualizar: false),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppLayout.screenPadding,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _vagasController,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade de vagas',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n < 1) {
                              return 'Informe ao menos 1 vaga';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                        TextFormField(
                          controller: _dtInicioController,
                          decoration: const InputDecoration(
                            labelText: 'Data da matrícula',
                          ),
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [DataBrFormatter()],
                          validator: validateDataBr,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: _loading ? 'Carregando…' : 'Carregar candidatos',
                          onPressed:
                              (_loading || !_filtrosPreenchidos) ? null : _carregar,
                        ),
                        if (!_filtrosPreenchidos && _resultado == null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Informe a quantidade de vagas, selecione a turma e '
                            'confira a data da matrícula. Os candidatos só serão carregados '
                            'ao tocar em Carregar candidatos.',
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
                            '${vagas != null ? ' · Vagas: $vagas' : ''}'
                            '${vagas != null ? ' · Disponíveis: $_vagasDisponiveis' : ''}'
                            ' · A matricular: $_totalSelecionados',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w600,
                              color: _totalSelecionados > _vagasDisponiveis
                                  ? AppColors.accentOrange
                                  : AppColors.darkGray,
                            ),
                          ),
                          if (_bloqueado) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Todas as vagas estão preenchidas. A seleção não pode ser alterada.',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: AppColors.accentOrange,
                              ),
                            ),
                          ],
                          const Divider(height: 24),
                          if (_resultado!.candidatos.isEmpty)
                            Text(
                              'Nenhuma inscrição ativa para esta turma.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else
                            ..._resultado!.candidatos.map(_buildCandidatoLinha),
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
                  label: _saving ? 'Gravando…' : 'Gravar matrícula',
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
      ),
    );
  }
}
