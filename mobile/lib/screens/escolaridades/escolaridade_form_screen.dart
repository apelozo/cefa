import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/escolaridade.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/datetime_display.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';

class EscolaridadeFormScreen extends ConsumerStatefulWidget {
  const EscolaridadeFormScreen({super.key, this.escolaridade});

  final Escolaridade? escolaridade;

  bool get isEditing => escolaridade != null;

  @override
  ConsumerState<EscolaridadeFormScreen> createState() =>
      _EscolaridadeFormScreenState();
}

class _EscolaridadeFormScreenState extends ConsumerState<EscolaridadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final FormEnterFocus _enterFocus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    _descricaoController =
        TextEditingController(text: widget.escolaridade?.descricao ?? '');
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
      if (widget.isEditing && widget.escolaridade!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final api = ref.read(apiClientProvider);

      if (widget.isEditing) {
        final escolaridade = Escolaridade(
          id: widget.escolaridade!.id,
          codigo: widget.escolaridade!.codigo,
          descricao: _descricaoController.text.trim(),
          ativo: widget.escolaridade!.ativo,
          usuarioInclusaoId: widget.escolaridade?.usuarioInclusaoId,
          dataHoraInclusao: widget.escolaridade?.dataHoraInclusao,
          usuarioAlteracaoId: widget.escolaridade?.usuarioAlteracaoId,
          dataHoraAlteracao: widget.escolaridade?.dataHoraAlteracao,
          usuarioExclusaoId: widget.escolaridade?.usuarioExclusaoId,
          dataHoraExclusao: widget.escolaridade?.dataHoraExclusao,
          createdAt: widget.escolaridade?.createdAt,
        );
        await api.updateEscolaridade(escolaridade);
      } else {
        final created = await api.createEscolaridade(
          Escolaridade(
            id: '',
            codigo: 0,
            descricao: _descricaoController.text.trim(),
            ativo: true,
          ),
        );
        if (mounted) {
          showSuccessSnackBar(context, 'Escolaridade criada');
          Navigator.pop(context, created);
        }
        return;
      }

      if (mounted) {
        showSuccessSnackBar(context, 'Escolaridade atualizada');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _auditLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.escolaridade;

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar escolaridade' : 'Nova escolaridade',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            if (widget.isEditing && e != null) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Código',
                ),
                child: Text(
                  e.codigo.toString(),
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
            if (widget.isEditing && e != null) ...[
              Text(
                'Auditoria',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _auditLine(
                'Inclusão',
                '${formatDateTimeBr(e.dataHoraInclusao)}'
                '${e.usuarioInclusaoId != null ? ' · usuário ${e.usuarioInclusaoId}' : ''}',
              ),
              _auditLine(
                'Última alteração',
                '${formatDateTimeBr(e.dataHoraAlteracao)}'
                '${e.usuarioAlteracaoId != null ? ' · usuário ${e.usuarioAlteracaoId}' : ''}',
              ),
              if (!e.ativo) ...[
                _auditLine(
                  'Desativação (soft delete)',
                  '${formatDateTimeBr(e.dataHoraExclusao)}'
                  '${e.usuarioExclusaoId != null ? ' · usuário ${e.usuarioExclusaoId}' : ''}',
                ),
              ],
              const SizedBox(height: 16),
            ],
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
