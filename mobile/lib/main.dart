import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CefaApp()));
}

class CefaApp extends ConsumerWidget {
  const CefaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'Cefa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: AppTheme.fontFamily),
            primaryTextTheme:
                theme.primaryTextTheme.apply(fontFamily: AppTheme.fontFamily),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: auth.loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : auth.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
    );
  }
}
