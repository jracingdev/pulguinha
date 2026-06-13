import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App inicia na tela pública', (WidgetTester tester) async {
    await tester.pumpWidget(const PulguinhaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('PULGUINHA'), findsOneWidget);
    expect(find.text('Treino funcional de verdade'), findsOneWidget);
  });
}
