import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/widgets/change_password_dialog.dart';

void main() {
  /// Abre o diálogo registrando os e-mails passados para o envio do link.
  Future<void> abrirDialogo(WidgetTester tester, List<String> enviados) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showForgotPasswordDialog(
                context,
                onEnviarLink: (email) async {
                  enviados.add(email);
                  return AppState.mensagemResetSenhaEnviado;
                },
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('responde com mensagem genérica para e-mail desconhecido', (tester) async {
    final enviados = <String>[];
    await abrirDialogo(tester, enviados);

    await tester.enterText(find.byType(TextField), 'ninguem@exemplo.com');
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    expect(enviados, ['ninguem@exemplo.com']);
    expect(find.textContaining('Se o e-mail estiver cadastrado'), findsOneWidget);
  });

  testWidgets('não revela existência da conta, nome nem telefone', (tester) async {
    final enviados = <String>[];
    await abrirDialogo(tester, enviados);

    await tester.enterText(find.byType(TextField), 'aluno@pulguinha.com');
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cadastro encontrado'), findsNothing);
    expect(find.textContaining('não encontrado'), findsNothing);
    expect(find.textContaining('recepção'), findsNothing);
    expect(find.textContaining('tel.'), findsNothing);
  });

  testWidgets('valida o e-mail antes de disparar o envio', (tester) async {
    final enviados = <String>[];
    await abrirDialogo(tester, enviados);

    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    expect(enviados, isEmpty);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
  });
}
