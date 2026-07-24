import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/screens/auth/definir_nova_senha_screen.dart';

void main() {
  Future<void> abrirTela(
    WidgetTester tester, {
    required Future<String?> Function(String) onSalvar,
    bool linkValido = true,
    VoidCallback? onConcluir,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefinirNovaSenhaScreen(
          linkValido: linkValido,
          onSalvar: onSalvar,
          onConcluir: () async => onConcluir?.call(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('salva a nova senha e confirma o sucesso', (tester) async {
    final salvas = <String>[];
    await abrirTela(tester, onSalvar: (senha) async {
      salvas.add(senha);
      return null;
    });

    await tester.enterText(find.byType(TextField).at(0), 'senhanova1');
    await tester.enterText(find.byType(TextField).at(1), 'senhanova1');
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();

    expect(salvas, ['senhanova1']);
    expect(find.textContaining('Senha alterada com sucesso'), findsOneWidget);
    expect(find.text('Ir para o login'), findsOneWidget);
  });

  testWidgets('recusa senha menor que o mínimo do Supabase', (tester) async {
    final salvas = <String>[];
    await abrirTela(tester, onSalvar: (senha) async {
      salvas.add(senha);
      return null;
    });

    await tester.enterText(find.byType(TextField).at(0), '123');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();

    expect(salvas, isEmpty);
    expect(find.textContaining('ao menos 6 caracteres'), findsOneWidget);
  });

  testWidgets('exige confirmação igual', (tester) async {
    final salvas = <String>[];
    await abrirTela(tester, onSalvar: (senha) async {
      salvas.add(senha);
      return null;
    });

    await tester.enterText(find.byType(TextField).at(0), 'senhanova1');
    await tester.enterText(find.byType(TextField).at(1), 'senhanova2');
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();

    expect(salvas, isEmpty);
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
  });

  testWidgets('mostra erro retornado pelo Supabase', (tester) async {
    await abrirTela(
      tester,
      onSalvar: (_) async => 'Link expirado ou inválido. Solicite um novo e-mail de redefinição.',
    );

    await tester.enterText(find.byType(TextField).at(0), 'senhanova1');
    await tester.enterText(find.byType(TextField).at(1), 'senhanova1');
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Link expirado'), findsOneWidget);
    expect(find.textContaining('Senha alterada com sucesso'), findsNothing);
  });

  testWidgets('link inválido não oferece formulário', (tester) async {
    var concluiu = false;
    await abrirTela(
      tester,
      linkValido: false,
      onSalvar: (_) async => null,
      onConcluir: () => concluiu = true,
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Salvar nova senha'), findsNothing);
    expect(find.textContaining('inválido ou expirou'), findsOneWidget);

    await tester.tap(find.text('Ir para o login'));
    await tester.pumpAndSettle();
    expect(concluiu, isTrue);
  });
}
