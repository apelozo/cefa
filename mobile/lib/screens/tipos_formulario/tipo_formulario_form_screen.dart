import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tipo_formulario.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';

class TipoFormularioFormScreen extends ConsumerStatefulWidget {
  const TipoFormularioFormScreen({super.key, this.tipo});

  final TipoFormulario? tipo;

  bool get isEditing => tipo != null;

  @override
  ConsumerState<TipoFormularioFormScreen> createState() =>
      _TipoFormularioFormScreenState();
}

class _TipoFormularioFormScreenState
    extends ConsumerState<TipoFormularioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final FormEnterFocus _enterFocus;
  late bool _ativo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(2);
    _nomeController = TextEditingController(text: widget.tipo?.nome ?? '');
    _descricaoController =
        TextEditingController(text: widget.tipo?.descricao ?? '');
    _ativo = widget.tipo?.ativo ?? true;
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing && widget.tipo!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }
      final api = ref.read(apiClientProvider);
      final nome = _nomeController.text.trim();
      final descricao = _descricaoController.text.trim();

      if (widget.isEditing) {
        await api.updateTipoFormulario(
          TipoFormulario(
            id: widget.tipo!.id,
            nome: nome,
            descricao: descricao.isEmpty ? null : descricao,
            ativo: _ativo,
            createdAt: widget.tipo!.createdAt,
          ),
        );
      } else {
        await api.createTipoFormulario(
          TipoFormulario(
            id: '',
            nome: nome,
            descricao: descricao.isEmpty ? null : descricao,
            ativo: _ativo,
            createdAt: DateTime.now(),
          ),
        );
      }

      if (mounted) {
        showSuccessSnackBar(
          context,
          widget.isEditing ? 'Tipo atualizado' : 'Tipo criado',
        );
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
    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing
            ? 'Editar tipo de formulário'
            : 'Novo tipo de formulário',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            TextFormField(
              controller: _nomeController,
              focusNode: _enterFocus.fields[0],
              textInputAction: _enterFocus.inputAction(0),
              onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o nome';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              focusNode: _enterFocus.fields[1],
              textInputAction: _enterFocus.inputAction(1),
              onFieldSubmitted: (_) => _enterFocus.onSubmitted(1),
                  onEditingComplete: _enterFocus.editingComplete(1),
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativo'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: widget.isEditing ? 'Salvar' : 'Criar',
              focusNode: _enterFocus.submitFocusNode,
              onPressed: _saving ? null : _save,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
