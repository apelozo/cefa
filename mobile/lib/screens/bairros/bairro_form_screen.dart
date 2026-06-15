import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bairro.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';

class BairroFormScreen extends ConsumerStatefulWidget {
  const BairroFormScreen({super.key, this.bairro});

  final Bairro? bairro;

  bool get isEditing => bairro != null;

  @override
  ConsumerState<BairroFormScreen> createState() => _BairroFormScreenState();
}

class _BairroFormScreenState extends ConsumerState<BairroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final FormEnterFocus _enterFocus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    _nomeController = TextEditingController(text: widget.bairro?.nome ?? '');
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing && widget.bairro!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final api = ref.read(apiClientProvider);

      if (widget.isEditing) {
        final bairro = Bairro(
          id: widget.bairro!.id,
          codigo: widget.bairro!.codigo,
          nome: _nomeController.text.trim(),
          ativo: widget.bairro!.ativo,
          usuarioInclusaoId: widget.bairro?.usuarioInclusaoId,
          dataHoraInclusao: widget.bairro?.dataHoraInclusao,
          usuarioAlteracaoId: widget.bairro?.usuarioAlteracaoId,
          dataHoraAlteracao: widget.bairro?.dataHoraAlteracao,
          usuarioExclusaoId: widget.bairro?.usuarioExclusaoId,
          dataHoraExclusao: widget.bairro?.dataHoraExclusao,
          createdAt: widget.bairro?.createdAt,
        );
        await api.updateBairro(bairro);
      } else {
        final created = await api.createBairro(
          Bairro(
            id: '',
            codigo: 0,
            nome: _nomeController.text.trim(),
            ativo: true,
          ),
        );
        if (mounted) {
          showSuccessSnackBar(context, 'Bairro criado');
          Navigator.pop(context, created);
        }
        return;
      }

      if (mounted) {
        showSuccessSnackBar(context, 'Bairro atualizado');
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
    final b = widget.bairro;

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar bairro' : 'Novo bairro',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            if (widget.isEditing && b != null) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Código',
                ),
                child: Text(
                  b.codigo.toString(),
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
              controller: _nomeController,
              focusNode: _enterFocus.fields[0],
              textInputAction: _enterFocus.inputAction(0),
              onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
              decoration: const InputDecoration(
                labelText: 'Nome do bairro',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o nome do bairro';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (widget.isEditing && b != null)
              AuditoriaSection(
                auditoria: b.auditoria,
                mostrarExclusao: !b.ativo,
              ),
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
