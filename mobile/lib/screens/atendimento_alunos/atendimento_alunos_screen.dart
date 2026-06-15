import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/inscricao_atendimento.dart';
import '../../models/turma.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/data_br_hoje.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import '../turmas/turmas_search_screen.dart';
import 'alunos_matriculados_search_screen.dart';

class AtendimentoAlunosScreen extends ConsumerStatefulWidget {
  const AtendimentoAlunosScreen({super.key});

  @override
  ConsumerState<AtendimentoAlunosScreen> createState() =>
      _AtendimentoAlunosScreenState();
}

class _AtendimentoAlunosScreenState
    extends ConsumerState<AtendimentoAlunosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataController =
      TextEditingController(text: dataBrHojeCurta());
  final _descricaoController = TextEditingController();

  Turma? _turma;
  AlunoMatriculadoResumo? _aluno;
  InscricaoAtendimentosContexto? _contexto;
  String? _editandoId;
  bool _loading = false;
  bool _saving = false;

  @override
  void dispose() {
    _dataController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _limparFormularioAtendimento({bool manterDataHoje = false}) {
    if (manterDataHoje) {
      _dataController.text = dataBrHojeCurta();
    } else {
      _dataController.clear();
    }
    _descricaoController.clear();
  }

  Future<void> _pesquisarTurma() async {
    final turma = await TurmasSearchScreen.select(
      context,
      title: 'Selecionar turma',
      subtitle: 'Atendimento de alunos',
    );
    if (turma == null || !mounted) return;
    setState(() {
      _turma = turma;
      _aluno = null;
      _contexto = null;
      _editandoId = null;
      _limparFormularioAtendimento(manterDataHoje: true);
    });
  }

  Future<void> _pesquisarAluno() async {
    if (_turma == null) {
      showErrorSnackBar(context, 'Selecione a turma antes de pesquisar o aluno');
      return;
    }
    final aluno = await AlunosMatriculadosSearchScreen.select(
      context,
      turma: _turma!,
      subtitle: 'Atendimento de alunos',
    );
    if (aluno == null || !mounted) return;
    setState(() {
      _aluno = aluno;
      _contexto = null;
      _editandoId = null;
      _limparFormularioAtendimento(manterDataHoje: true);
    });
  }

  Future<void> _carregar() async {
    if (_turma == null || _aluno == null) {
      showErrorSnackBar(
        context,
        'Selecione a turma e o aluno matriculado antes de carregar',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final contexto = await ref.read(apiClientProvider).listInscricaoAtendimentos(
            turmaCodigo: _turma!.codigo,
            alunoId: _aluno!.alunoId,
          );
      if (!mounted) return;
      setState(() {
        _contexto = contexto;
        _editandoId = null;
        _limparFormularioAtendimento(manterDataHoje: true);
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _iniciarEdicao(InscricaoAtendimentoListaItem item) async {
    setState(() => _loading = true);
    try {
      final detalhe = await ref
          .read(apiClientProvider)
          .getInscricaoAtendimento(item.id);
      if (!mounted) return;
      setState(() {
        _editandoId = detalhe.id;
        _dataController.text = detalhe.dataAtendimento;
        _descricaoController.text = detalhe.descricao ?? '';
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cancelarEdicao() {
    setState(() {
      _editandoId = null;
      _limparFormularioAtendimento(manterDataHoje: true);
    });
  }

  Future<void> _confirmarExclusao(InscricaoAtendimentoListaItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir atendimento'),
        content: const Text(
          'Deseja excluir este atendimento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).deleteInscricaoAtendimento(item.id);
      if (!mounted) return;
      if (_editandoId == item.id) {
        _cancelarEdicao();
      }
      await _carregar();
      if (mounted) {
        showSuccessSnackBar(context, 'Atendimento excluído');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    final auth = ref.read(authProvider);
    final editando = _editandoId != null;
    if (editando && !auth.podeAlterar(Programas.atendimentoAlunos)) return;
    if (!editando && !auth.podeIncluir(Programas.atendimentoAlunos)) return;

    if (_contexto == null || _turma == null || _aluno == null) {
      showErrorSnackBar(context, 'Carregue os atendimentos antes de salvar');
      return;
    }
    if (!editando && !_contexto!.podeIncluirAtendimento) {
      showErrorSnackBar(
        context,
        'Não é possível incluir atendimento — matrícula cancelada nesta turma',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (editando) {
        await ref.read(apiClientProvider).updateInscricaoAtendimento(
              id: _editandoId!,
              dataAtendimento: _dataController.text.trim(),
              descricao: _descricaoController.text.trim(),
            );
      } else {
        await ref.read(apiClientProvider).createInscricaoAtendimento(
              turmaCodigo: _turma!.codigo,
              alunoId: _aluno!.alunoId,
              dataAtendimento: _dataController.text.trim(),
              descricao: _descricaoController.text.trim(),
            );
      }
      if (!mounted) return;
      await _carregar();
      if (mounted) {
        showSuccessSnackBar(
          context,
          editando ? 'Atendimento alterado' : 'Atendimento registrado',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _labelTurma(Turma turma) =>
      '${turma.codigo} — ${turma.nome} (${turma.cursoDescricao})';

  Widget _buildAtendimentoLinha(InscricaoAtendimentoListaItem item) {
    final podeAlterar =
        ref.watch(authProvider).podeAlterar(Programas.atendimentoAlunos);
    final podeExcluir =
        ref.watch(authProvider).podeExcluir(Programas.atendimentoAlunos);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkGray,
                        fontFamily: AppTheme.fontFamily,
                      ),
                  children: [
                    TextSpan(
                      text: 'Data: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${item.dataAtendimento} · '),
                    TextSpan(
                      text: 'Atendimento: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: item.descricaoResumo),
                  ],
                ),
              ),
            ),
          ),
          RecordActionButtons(
            onEdit: podeAlterar ? () => _iniciarEdicao(item) : null,
            onDelete: podeExcluir ? () => _confirmarExclusao(item) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final editando = _editandoId != null;
    final podeIncluirNovo =
        _contexto?.podeIncluirAtendimento ?? false;
    final podeSalvar = editando
        ? auth.podeAlterar(Programas.atendimentoAlunos)
        : auth.podeIncluir(Programas.atendimentoAlunos) && podeIncluirNovo;

    return PermissaoGate(
      programaCodigo: Programas.atendimentoAlunos,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Atendimento de Alunos',
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
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Aluno matriculado',
                            ),
                            child: Text(
                              _aluno?.alunoNome ?? 'Nenhum aluno selecionado',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Pesquisar aluno',
                            onPressed: _turma == null ? null : _pesquisarAluno,
                            type: AppButtonType.secondary,
                            icon: Icons.person_search,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: _loading ? 'Carregando…' : 'Carregar atendimentos',
                            onPressed: (_loading || _turma == null || _aluno == null)
                                ? null
                                : _carregar,
                          ),
                        ],
                      ),
                    ),
                    if (_contexto != null) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${_contexto!.cursoDescricao} — ${_contexto!.turmaNome}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Aluno: ${_contexto!.alunoNome}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_contexto!.matriculaCancelada) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Matrícula cancelada nesta turma — consulta e alteração '
                                'de atendimentos existentes; novos atendimentos não '
                                'são permitidos.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.accentOrange,
                                    ),
                              ),
                            ],
                            const Divider(height: 24),
                            if (_contexto!.atendimentos.isEmpty)
                              Text(
                                'Nenhum atendimento registrado para este aluno.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            else
                              ..._contexto!.atendimentos.map(_buildAtendimentoLinha),
                          ],
                        ),
                      ),
                      if (_contexto!.podeIncluirAtendimento || editando) ...[
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              editando
                                  ? 'Alterar atendimento'
                                  : 'Novo atendimento',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dataController,
                              decoration: const InputDecoration(
                                labelText: 'Data do atendimento',
                              ),
                              keyboardType: TextInputType.datetime,
                              inputFormatters: [DataBrFormatter()],
                              validator: validateDataBr,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descricaoController,
                              decoration: const InputDecoration(
                                labelText: 'Descrição do atendimento',
                                alignLabelWithHint: true,
                              ),
                              maxLength: 2000,
                              maxLines: 6,
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) {
                                  return 'Informe a descrição do atendimento';
                                }
                                return null;
                              },
                            ),
                            if (editando) ...[
                              const SizedBox(height: 8),
                              AppButton(
                                label: 'Cancelar alteração',
                                type: AppButtonType.secondary,
                                onPressed: _cancelarEdicao,
                              ),
                            ],
                          ],
                        ),
                      ),
                      ],
                    ],
                  ],
                ),
              ),
              if (podeSalvar && _contexto != null &&
                  (editando || _contexto!.podeIncluirAtendimento))
                Padding(
                  padding: AppLayout.screenPadding,
                  child: AppButton(
                    label: _saving
                        ? 'Salvando…'
                        : (editando ? 'Salvar alteração' : 'Registrar atendimento'),
                    onPressed: _saving ? null : _salvar,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
