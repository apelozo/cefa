import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/curso.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/auditoria_section.dart';
import '../../widgets/app_screen_chrome.dart';

class CursoFormScreen extends ConsumerStatefulWidget {
  const CursoFormScreen({super.key, this.curso});

  final Curso? curso;

  bool get isEditing => curso != null;

  @override
  ConsumerState<CursoFormScreen> createState() => _CursoFormScreenState();
}

class _CursoFormScreenState extends ConsumerState<CursoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final FormEnterFocus _enterFocus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    _descricaoController =
        TextEditingController(text: widget.curso?.descricao ?? '');
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing && widget.curso!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final api = ref.read(apiClientProvider);

      if (widget.isEditing) {
        final curso = Curso(
          id: widget.curso!.id,
          codigo: widget.curso!.codigo,
          descricao: _descricaoController.text.trim(),
          ativo: widget.curso!.ativo,
          usuarioInclusaoId: widget.curso?.usuarioInclusaoId,
          dataHoraInclusao: widget.curso?.dataHoraInclusao,
          usuarioAlteracaoId: widget.curso?.usuarioAlteracaoId,
          dataHoraAlteracao: widget.curso?.dataHoraAlteracao,
          createdAt: widget.curso?.createdAt,
        );
        await api.updateCurso(curso);
      } else {
        final created = await api.createCurso(
          Curso(
            id: '',
            codigo: 0,
            descricao: _descricaoController.text.trim(),
            ativo: true,
          ),
        );
        if (mounted) {
          showSuccessSnackBar(context, 'Curso criado');
          Navigator.pop(context, created);
        }
        return;
      }

      if (mounted) {
        showSuccessSnackBar(context, 'Curso atualizado');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.curso;

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar curso' : 'Novo curso',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            if (widget.isEditing && c != null) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Código',
                ),
                child: Text(
                  c.codigo.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'O código será gerado automaticamente ao salvar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _descricaoController,
              focusNode: _enterFocus.fields[0],
              textInputAction: _enterFocus.inputAction(0),
              onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
              onEditingComplete: _enterFocus.editingComplete(0),
              decoration: const InputDecoration(
                labelText: 'Descrição',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe a descrição';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (widget.isEditing && c != null)
              AuditoriaSection(auditoria: c.auditoria),
            AppButton(
              focusNode: _enterFocus.submitFocusNode,
              label: widget.isEditing ? 'Salvar' : 'Criar',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
