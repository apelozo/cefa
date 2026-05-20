import 'package:cefa_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home exibe atalhos principais', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CefaApp()),
    );

    expect(find.text('Cefa'), findsOneWidget);
    expect(find.text('Tipos de formulário'), findsOneWidget);
    expect(find.text('Cadastrar perguntas'), findsOneWidget);
    expect(find.text('Responder formulário'), findsOneWidget);
  });
}
