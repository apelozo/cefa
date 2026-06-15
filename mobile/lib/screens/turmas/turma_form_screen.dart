import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../constants/periodo_inscricao.dart';
import '../../constants/situacao_turma.dart';
import '../../models/turma.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/auditoria_section.dart';
import '../../widgets/app_screen_chrome.dart';
import '../cursos/cursos_search_screen.dart';

class TurmaFormScreen extends ConsumerStatefulWidget {
  const TurmaFormScreen({super.key, this.turma});

  final Turma? turma;

  bool get isEditing => turma != null;

  @override
  ConsumerState<TurmaFormScreen> createState() => _TurmaFormScreenState();
}

class _TurmaFormScreenState extends ConsumerState<TurmaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final FormEnterFocus _enterFocus;

  int? _cursoCodigo;
  String? _cursoLabel;
  String? _periodo;
  String _situacao = SituacaoTurma.aberta;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    final t = widget.turma;
    _nomeController = TextEditingController(text: t?.nome ?? '');
    _cursoCodigo = t?.cursoCodigo;
    _cursoLabel = t != null ? '${t.cursoCodigo} — ${t.cursoDescricao}' : null;
    _periodo = t?.periodo;
    _situacao = t?.situacao ?? SituacaoTurma.aberta;
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _pesquisarCurso() async {
    final curso = await CursosSearchScreen.select(
      context,
      title: 'Pesquisar curso',
      subtitle: widget.isEditing
          ? 'Turma ${widget.turma!.codigo}'
          : 'Nova turma',
    );
    if (!mounted || curso == null) return;
    setState(() {
      _cursoCodigo = curso.codigo;
      _cursoLabel = '${curso.codigo} — ${curso.descricao}';
    });
  }

  Future<void> _save() async {
    if (_cursoCodigo == null) {
      showErrorSnackBar(context, 'Selecione o curso');
      return;
    }
    if (_periodo == null) {
      showErrorSnackBar(context, 'Selecione o período');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing && widget.turma!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final api = ref.read(apiClientProvider);
      final payload = Turma(
        id: widget.turma?.id ?? '',
        codigo: widget.turma?.codigo ?? 0,
        nome: _nomeController.text.trim(),
        cursoCodigo: _cursoCodigo!,
        cursoDescricao: _cursoLabel ?? '',
        periodo: _periodo!,
        situacao: _situacao,
        ativo: widget.turma?.ativo ?? true,
        usuarioInclusaoId: widget.turma?.usuarioInclusaoId,
        dataHoraInclusao: widget.turma?.dataHoraInclusao,
        usuarioAlteracaoId: widget.turma?.usuarioAlteracaoId,
        dataHoraAlteracao: widget.turma?.dataHoraAlteracao,
      );

      if (widget.isEditing) {
        await api.updateTurma(payload);
        if (mounted) {
          showSuccessSnackBar(context, 'Turma atualizada');
          Navigator.pop(context, true);
        }
      } else {
        final created = await api.createTurma(payload);
        if (mounted) {
          showSuccessSnackBar(context, 'Turma criada');
          Navigator.pop(context, created);
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSelecaoCurso() {
    final textTheme = Theme.of(context).textTheme;
    final temValor = _cursoLabel != null && _cursoLabel!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Curso'),
          child: Text(
            temValor ? _cursoLabel! : 'Nenhum curso selecionado',
            style: temValor
                ? textTheme.bodyLarge
                : textTheme.bodyLarge?.copyWith(
                    color: AppColors.neutralGray,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Pesquisar curso',
          type: AppButtonType.secondary,
          icon: Icons.search,
          onPressed: _pesquisarCurso,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.turma;
    final podeSalvar = widget.isEditing
        ? ref.watch(authProvider).podeAlterar(Programas.turmas)
        : ref.watch(authProvider).podeIncluir(Programas.turmas);

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Turma ${t!.codigo}' : 'Nova turma',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            if (widget.isEditing && t != null) ...[
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Código'),
                child: Text(
                  t.codigo.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    focusNode: _enterFocus.fields[0],
                    decoration: const InputDecoration(labelText: 'Nome da turma'),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: _enterFocus.inputAction(0),
                    onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                    onEditingComplete: _enterFocus.editingComplete(0),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildSelecaoCurso(),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _periodo,
                    decoration: const InputDecoration(labelText: 'Período'),
                    hint: const Text('Selecione'),
                    items: PeriodoInscricao.opcoes.entries
                        .map(
                          (e) => DropdownMenuItem<String?>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _periodo = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _situacao,
                    decoration: const InputDecoration(labelText: 'Situação'),
                    items: SituacaoTurma.opcoes.entries
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _situacao = v);
                    },
                  ),
                ],
              ),
            ),
            if (widget.isEditing && t != null) ...[
              const SizedBox(height: 16),
              AuditoriaSection(auditoria: t.auditoria),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: widget.isEditing ? 'Salvar' : 'Criar turma',
              loading: _saving,
              onPressed: podeSalvar && !_saving ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
