import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// URL da API. Defina com `--dart-define=API_BASE_URL=http://SEU_IP:3000`
  /// se usar celular físico na mesma rede Wi‑Fi.
  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    // 127.0.0.1 evita falhas de conexão com localhost no Chrome (Windows).
    if (kIsWeb) return 'http://127.0.0.1:3000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:3000';
      default:
        return 'http://127.0.0.1:3000';
    }
  }
}
