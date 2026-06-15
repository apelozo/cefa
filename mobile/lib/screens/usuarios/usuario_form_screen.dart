import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tipo_usuario.dart';
import '../../models/usuario.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';

class UsuarioFormScreen extends ConsumerStatefulWidget {
  const UsuarioFormScreen({super.key, this.usuario});

  final Usuario? usuario;

  bool get isEditing => usuario != null;

  @override
  ConsumerState<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends ConsumerState<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeUsuarioController;
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _senhaController;
  late final FormEnterFocus _enterFocus;
  List<TipoUsuario> _tipos = [];
  String? _tipoUsuarioId;
  late bool _ativo;
  bool _loadingTipos = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(4);
    _nomeUsuarioController =
        TextEditingController(text: widget.usuario?.nomeUsuario ?? '');
    _nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _senhaController = TextEditingController();
    _tipoUsuarioId = widget.usuario?.tipoUsuarioId;
    _ativo = widget.usuario?.ativo ?? true;
    _loadTipos();
  }

  Future<void> _loadTipos() async {
    try {
      final tipos = await ref.read(apiClientProvider).listTiposUsuario(ativo: true);
      if (mounted) {
        setState(() {
          _tipos = tipos;
          _loadingTipos = false;
          _tipoUsuarioId ??= tipos.isNotEmpty ? tipos.first.id : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTipos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeUsuarioController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoUsuarioId == null) {
      showErrorSnackBar(context, 'Selecione o tipo de usuário');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final usuario = Usuario(
        id: widget.usuario?.id ?? '',
        nomeUsuario: _nomeUsuarioController.text.trim(),
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        tipoUsuarioId: _tipoUsuarioId!,
        tipoUsuario: widget.usuario?.tipoUsuario ??
            TipoUsuarioResumo(
              id: _tipoUsuarioId!,
              descricao: '',
              perfil: PerfilTipoUsuario.comum,
              ativo: true,
            ),
        ativo: _ativo,
        createdAt: widget.usuario?.createdAt ?? DateTime.now(),
      );

      if (widget.isEditing) {
        await api.updateUsuario(
          usuario,
          senha: _senhaController.text.isEmpty ? null : _senhaController.text,
        );
      } else {
        if (_senhaController.text.length < 6) {
          showErrorSnackBar(context, 'Senha deve ter no mínimo 6 caracteres');
          return;
        }
        await api.createUsuario(usuario, senha: _senhaController.text);
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
        title: widget.isEditing ? 'Alterar usuário' : 'Novo usuário',
      ),
      body: SafeArea(
        child: _loadingTipos
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: AppLayout.screenPadding,
                  children: [
                    TextFormField(
                      controller: _nomeUsuarioController,
                      focusNode: _enterFocus.fields[0],
                      textInputAction: _enterFocus.inputAction(0),
                      onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
                      decoration: const InputDecoration(
                        labelText: 'Nome de usuário',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomeController,
                      focusNode: _enterFocus.fields[1],
                      textInputAction: _enterFocus.inputAction(1),
                      onFieldSubmitted: (_) => _enterFocus.onSubmitted(1),
                  onEditingComplete: _enterFocus.editingComplete(1),
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _enterFocus.fields[2],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: _enterFocus.inputAction(2),
                      onFieldSubmitted: (_) => _enterFocus.onSubmitted(2),
                  onEditingComplete: _enterFocus.editingComplete(2),
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obrigatório';
                        if (!v.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipoUsuarioId,
                      decoration: const InputDecoration(labelText: 'Tipo de usuário'),
                      items: _tipos
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.descricao),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _tipoUsuarioId = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaController,
                      focusNode: _enterFocus.fields[3],
                      obscureText: true,
                      textInputAction: _enterFocus.inputAction(3),
                      onFieldSubmitted: (_) => _enterFocus.onSubmitted(3),
                  onEditingComplete: _enterFocus.editingComplete(3),
                      decoration: InputDecoration(
                        labelText: widget.isEditing
                            ? 'Nova senha (opcional)'
                            : 'Senha',
                      ),
                      validator: (v) {
                        if (!widget.isEditing &&
                            (v == null || v.length < 6)) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Ativo'),
                      value: _ativo,
                      onChanged: (v) => setState(() => _ativo = v),
                    ),
                    if (widget.isEditing && widget.usuario != null)
                      AuditoriaSection(
                        auditoria: widget.usuario!.auditoria,
                        mostrarExclusao: !widget.usuario!.ativo,
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
