import 'package:flutter/material.dart';
import 'package:pulguinha/config/auth_config.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

Future<bool?> showChangePasswordDialog(
  BuildContext context, {
  required String titulo,
  required bool exigeSenhaAtual,
  required Future<String?> Function(String senhaAtual, String novaSenha) onConfirm,
}) {
  final atualCtrl = TextEditingController();
  final novaCtrl = TextEditingController();
  final confCtrl = TextEditingController();
  var erro = '';
  var salvando = false;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        Future<void> salvar() async {
          if (exigeSenhaAtual && atualCtrl.text.isEmpty) {
            setLocal(() => erro = 'Informe a senha atual.');
            return;
          }
          if (novaCtrl.text.length < AuthConfig.senhaMinima) {
            setLocal(() => erro = 'Nova senha: mínimo ${AuthConfig.senhaMinima} caracteres.');
            return;
          }
          if (novaCtrl.text != confCtrl.text) {
            setLocal(() => erro = 'As senhas não coincidem.');
            return;
          }
          setLocal(() {
            salvando = true;
            erro = '';
          });
          final msg = await onConfirm(atualCtrl.text, novaCtrl.text);
          if (!ctx.mounted) return;
          if (msg != null) {
            setLocal(() {
              salvando = false;
              erro = msg;
            });
            return;
          }
          Navigator.of(ctx).pop(true);
        }

        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(titulo, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (exigeSenhaAtual) ...[
                  FieldLabel(
                    label: 'Senha atual',
                    child: TextField(controller: atualCtrl, obscureText: true, autofocus: true),
                  ),
                  const SizedBox(height: 10),
                ],
                FieldLabel(label: 'Nova senha', child: TextField(controller: novaCtrl, obscureText: true)),
                const SizedBox(height: 10),
                FieldLabel(label: 'Confirmar nova senha', child: TextField(controller: confCtrl, obscureText: true)),
                if (erro.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(erro, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: salvando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
            NeonButton(label: salvando ? 'Salvando...' : 'Salvar', enabled: !salvando, onPressed: salvando ? null : salvar),
          ],
        );
      },
    ),
  );
}

Future<String?> showResetPasswordDialog(BuildContext context, {required String nomeAluno}) {
  final novaCtrl = TextEditingController(text: _gerarSenhaTemp());
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('Senha temporária — $nomeAluno', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Use apenas se o aluno não tiver acesso ao e-mail. A senha será exibida uma vez '
            'e não se aplica a contas já migradas para o login por e-mail.',
            style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4),
          ),
          const SizedBox(height: 12),
          FieldLabel(label: 'Nova senha temporária', child: TextField(controller: novaCtrl, obscureText: true)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        NeonButton(label: 'Confirmar reset', onPressed: () => Navigator.pop(ctx, novaCtrl.text)),
      ],
    ),
  );
}

String _gerarSenhaTemp() => 'pulg${DateTime.now().millisecondsSinceEpoch % 100000}';

/// Solicita o e-mail oficial de redefinição de senha (Supabase Auth).
///
/// [onEnviarLink] deve retornar sempre a mesma mensagem, com ou sem cadastro,
/// para não revelar a existência da conta.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  required Future<String> Function(String email) onEnviarLink,
}) {
  final emailCtrl = TextEditingController();
  var resultado = '';
  var enviando = false;

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        Future<void> enviar() async {
          final email = emailCtrl.text.trim();
          if (email.isEmpty || !email.contains('@')) {
            setLocal(() => resultado = 'Informe um e-mail válido.');
            return;
          }
          setLocal(() {
            enviando = true;
            resultado = '';
          });
          final msg = await onEnviarLink(email);
          if (!ctx.mounted) return;
          setLocal(() {
            enviando = false;
            resultado = msg;
          });
        }

        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Esqueci a senha', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe o e-mail da sua conta. Enviaremos um link para você criar uma nova senha.',
                style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4),
              ),
              const SizedBox(height: 12),
              FieldLabel(
                label: 'E-mail',
                child: TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => enviando ? null : enviar(),
                ),
              ),
              if (resultado.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(resultado, style: const TextStyle(fontSize: 12, color: AppColors.neon, height: 1.4)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: enviando ? null : () => Navigator.pop(ctx), child: const Text('Fechar')),
            NeonButton(
              label: enviando ? 'Enviando...' : 'Enviar link',
              enabled: !enviando,
              onPressed: enviando ? null : enviar,
            ),
          ],
        );
      },
    ),
  );
}
