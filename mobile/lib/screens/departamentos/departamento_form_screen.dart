import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/departamento.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/auditoria_section.dart';
import '../../widgets/app_screen_chrome.dart';

class DepartamentoFormScreen extends ConsumerStatefulWidget {
  const DepartamentoFormScreen({super.key, this.departamento});

  final Departamento? departamento;

  bool get isEditing => departamento != null;

  @override
  ConsumerState<DepartamentoFormScreen> createState() =>
      _DepartamentoFormScreenState();
}

class _DepartamentoFormScreenState extends ConsumerState<DepartamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final FormEnterFocus _enterFocus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    _descricaoController =
        TextEditingController(text: widget.departamento?.descricao ?? '');
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
      if (widget.isEditing && widget.departamento!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final api = ref.read(apiClientProvider);

      if (widget.isEditing) {
        final departamento = Departamento(
          id: widget.departamento!.id,
          codigo: widget.departamento!.codigo,
          descricao: _descricaoController.text.trim(),
          ativo: widget.departamento!.ativo,
          usuarioInclusaoId: widget.departamento?.usuarioInclusaoId,
          dataHoraInclusao: widget.departamento?.dataHoraInclusao,
          usuarioAlteracaoId: widget.departamento?.usuarioAlteracaoId,
          dataHoraAlteracao: widget.departamento?.dataHoraAlteracao,
          createdAt: widget.departamento?.createdAt,
        );
        await api.updateDepartamento(departamento);
      } else {
        final created = await api.createDepartamento(
          Departamento(
            id: '',
            codigo: 0,
            descricao: _descricaoController.text.trim(),
            ativo: true,
          ),
        );
        if (mounted) {
          showSuccessSnackBar(context, 'Departamento criado');
          Navigator.pop(context, created);
        }
        return;
      }

      if (mounted) {
        showSuccessSnackBar(context, 'Departamento atualizado');
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
    final d = widget.departamento;

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar departamento' : 'Novo departamento',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            if (widget.isEditing && d != null) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Código',
                ),
                child: Text(
                  d.codigo.toString(),
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
            if (widget.isEditing && d != null)
              AuditoriaSection(auditoria: d.auditoria),
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
