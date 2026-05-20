import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  late final FormEnterFocus _enterFocus;
  bool _loading = false;
  bool _obscureSenha = true;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(2);
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(
            _usuarioController.text.trim(),
            _senhaController.text,
          );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppScreenChrome.appBar(context, title: 'Cefa', centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppLayout.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Entrar',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use o usuário administrador inicial (admin) após o primeiro deploy.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usuarioController,
                      focusNode: _enterFocus.fields[0],
                      textInputAction: _enterFocus.inputAction(0),
                      onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
                      decoration: const InputDecoration(
                        labelText: 'Nome de usuário',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaController,
                      focusNode: _enterFocus.fields[1],
                      obscureText: _obscureSenha,
                      textInputAction: _enterFocus.inputAction(1),
                      onFieldSubmitted: (_) => _enterFocus.onSubmitted(1),
                  onEditingComplete: _enterFocus.editingComplete(1),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSenha
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureSenha = !_obscureSenha),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: _loading ? 'Entrando...' : 'Entrar',
                      focusNode: _enterFocus.submitFocusNode,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
