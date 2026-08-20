// Teste básico: a splash art aparece e depois abre a tela de login.

import 'package:flutter_test/flutter_test.dart';

import 'package:bookface/main.dart';

void main() {
  testWidgets('Splash mostra o wordmark e navega para o login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BookfaceApp());

    // Durante a splash, o wordmark "bookface" está visível.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('bookface'), findsWidgets);

    // Avança em passos para encadear as animações sequenciais (await)
    // e disparar o Future.delayed que faz a navegação.
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Chegou a tela de login.
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar nova conta'), findsOneWidget);
  });
}
