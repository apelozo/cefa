import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_layout.dart';
import 'app_screen_chrome.dart';

/// Bloqueia a tela se o usuário não tiver nenhuma permissão no programa.
class PermissaoGate extends ConsumerWidget {
  const PermissaoGate({
    super.key,
    required this.programaCodigo,
    required this.child,
  });

  final String programaCodigo;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.podeAcessar(programaCodigo)) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Acesso negado')),
        body: Center(
          child: Padding(
            padding: AppLayout.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Você não tem permissão para acessar esta tela.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}
