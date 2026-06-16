import 'package:flutter/material.dart';
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
          if (novaCtrl.text.length < 4) {
            setLocal(() => erro = 'Nova senha: mínimo 4 caracteres.');
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
      title: Text('Resetar senha — $nomeAluno', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A nova senha será exibida uma vez. O aluno deve alterá-la no perfil.',
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

String _gerarSenhaTemp() => 'pul${DateTime.now().millisecondsSinceEpoch % 10000}';

Future<void> showForgotPasswordDialog(
  BuildContext context, {
  required Future<String?> Function(String email) buscarDica,
}) {
  final emailCtrl = TextEditingController();
  var resultado = '';
  var buscando = false;

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        Future<void> buscar() async {
          if (emailCtrl.text.trim().isEmpty) {
            setLocal(() => resultado = 'Informe seu e-mail de cadastro.');
            return;
          }
          setLocal(() {
            buscando = true;
            resultado = '';
          });
          final dica = await buscarDica(emailCtrl.text.trim());
          if (!ctx.mounted) return;
          setLocal(() {
            buscando = false;
            resultado = dica ?? 'E-mail não encontrado. Verifique ou cadastre-se.';
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
                'Por segurança, a recuperação é feita pela recepção. Informe seu e-mail para confirmar o cadastro.',
                style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4),
              ),
              const SizedBox(height: 12),
              FieldLabel(label: 'E-mail', child: TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress)),
              if (resultado.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  resultado,
                  style: TextStyle(
                    fontSize: 12,
                    color: resultado.startsWith('Cadastro encontrado') ? AppColors.neon : AppColors.yellow,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
            NeonButton(label: buscando ? 'Buscando...' : 'Verificar', enabled: !buscando, onPressed: buscando ? null : buscar),
          ],
        );
      },
    ),
  );
}
