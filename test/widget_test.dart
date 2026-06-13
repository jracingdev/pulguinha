import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/app.dart';

void main() {
  testWidgets('App inicia na tela pública', (WidgetTester tester) async {
    await tester.pumpWidget(const PulguinhaApp());
    await tester.pumpAndSettle();

    expect(find.text('PULGUINHA'), findsOneWidget);
    expect(find.text('Treino funcional de verdade'), findsOneWidget);
  });
}
