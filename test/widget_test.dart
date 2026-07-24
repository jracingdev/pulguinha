import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/app.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseConfig.desabilitarParaTestes();
  });

  testWidgets('App inicia na tela pública', (WidgetTester tester) async {
    await tester.pumpWidget(const PulguinhaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('PULGUINHA'), findsOneWidget);
    expect(find.text('Treino funcional de verdade'), findsOneWidget);

    // Drena os banners in-app disparados pela carga inicial dos dados.
    await tester.pump(const Duration(seconds: 5));
  });
}
