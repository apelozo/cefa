import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tipo_usuario.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';

class TipoUsuarioFormScreen extends ConsumerStatefulWidget {
  const TipoUsuarioFormScreen({super.key, this.tipo});

  final TipoUsuario? tipo;

  bool get isEditing => tipo != null;

  @override
  ConsumerState<TipoUsuarioFormScreen> createState() =>
      _TipoUsuarioFormScreenState();
}

class _TipoUsuarioFormScreenState extends ConsumerState<TipoUsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final FormEnterFocus _enterFocus;
  late PerfilTipoUsuario _perfil;
  late bool _ativo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    _descricaoController =
        TextEditingController(text: widget.tipo?.descricao ?? '');
    _perfil = widget.tipo?.perfil ?? PerfilTipoUsuario.comum;
    _ativo = widget.tipo?.ativo ?? true;
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
      final api = ref.read(apiClientProvider);
      final tipo = TipoUsuario(
        id: widget.tipo?.id ?? '',
        descricao: _descricaoController.text.trim(),
        perfil: _perfil,
        ativo: _ativo,
        createdAt: widget.tipo?.createdAt ?? DateTime.now(),
      );
      if (widget.isEditing) {
        await api.updateTipoUsuario(tipo);
      } else {
        await api.createTipoUsuario(tipo);
      }
      if (mounted) {
        showSuccessSnackBar(context, 'Salvo com sucesso');
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
        title: widget.isEditing ? 'Alterar tipo' : 'Novo tipo de usuário',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppLayout.screenPadding,
            children: [
              TextFormField(
                controller: _descricaoController,
                focusNode: _enterFocus.fields[0],
                textInputAction: _enterFocus.inputAction(0),
                onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PerfilTipoUsuario>(
                value: _perfil,
                decoration: const InputDecoration(labelText: 'Perfil'),
                items: PerfilTipoUsuario.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(perfilLabel(p)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _perfil = v);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Ativo'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
              if (widget.tipo != null)
                AuditoriaSection(
                  auditoria: widget.tipo!.auditoria,
                  mostrarExclusao: !widget.tipo!.ativo,
                ),
              const SizedBox(height: 24),
              AppButton(
                label: _saving ? 'Salvando...' : 'Salvar',
                focusNode: _enterFocus.submitFocusNode,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
