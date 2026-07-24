import 'package:flutter/material.dart';
import 'package:pulguinha/config/auth_config.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

/// Tela aberta pelo link de recuperação (evento `PASSWORD_RECOVERY`).
///
/// A sessão de recuperação já está aberta quando [linkValido] é `true`; basta
/// gravar a nova senha via [onSalvar].
class DefinirNovaSenhaScreen extends StatefulWidget {
  const DefinirNovaSenhaScreen({
    super.key,
    required this.onSalvar,
    required this.onConcluir,
    this.linkValido = true,
  });

  /// Retorna `null` em caso de sucesso ou a mensagem de erro.
  final Future<String?> Function(String novaSenha) onSalvar;

  /// Fecha o fluxo e leva o usuário de volta ao login.
  final Future<void> Function() onConcluir;

  final bool linkValido;

  @override
  State<DefinirNovaSenhaScreen> createState() => _DefinirNovaSenhaScreenState();
}

class _DefinirNovaSenhaScreenState extends State<DefinirNovaSenhaScreen> {
  final _novaCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _mostrarSenha = false;
  bool _salvando = false;
  bool _sucesso = false;
  String _erro = '';

  @override
  void dispose() {
    _novaCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nova = _novaCtrl.text;
    if (nova.length < AuthConfig.senhaMinima) {
      setState(() => _erro = 'A senha precisa ter ao menos ${AuthConfig.senhaMinima} caracteres.');
      return;
    }
    if (nova != _confCtrl.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = '';
    });

    final erro = await widget.onSalvar(nova);
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _erro = erro ?? '';
      _sucesso = erro == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const PulguinhaLogo(size: 96, borderRadius: 22),
                  const SizedBox(height: 20),
                  const Text(
                    'Criar nova senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white),
                  ),
                  const SizedBox(height: 24),
                  if (!widget.linkValido)
                    _aviso(
                      'Este link de redefinição é inválido ou expirou. Volte ao login e '
                      'peça um novo e-mail em "Esqueci a senha".',
                      AppColors.yellow,
                    )
                  else if (_sucesso)
                    _aviso('Senha alterada com sucesso! Entre novamente com a nova senha.', AppColors.neon)
                  else
                    ..._campos(),
                  if (_erro.isNotEmpty && !_sucesso) ...[
                    const SizedBox(height: 12),
                    _aviso(_erro, AppColors.red),
                  ],
                  const SizedBox(height: 20),
                  if (widget.linkValido && !_sucesso)
                    NeonButton(
                      label: _salvando ? 'Salvando...' : 'Salvar nova senha',
                      fullWidth: true,
                      enabled: !_salvando,
                      onPressed: _salvando ? null : _salvar,
                    ),
                  if (widget.linkValido && !_sucesso) const SizedBox(height: 12),
                  GhostButton(
                    label: _sucesso || !widget.linkValido ? 'Ir para o login' : 'Cancelar',
                    fullWidth: true,
                    onPressed: _salvando ? null : () => widget.onConcluir(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _campos() => [
        Text(
          'Escolha uma senha com pelo menos ${AuthConfig.senhaMinima} caracteres.',
          style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4),
        ),
        const SizedBox(height: 14),
        FieldLabel(
          label: 'Nova senha',
          child: TextField(
            controller: _novaCtrl,
            obscureText: !_mostrarSenha,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                icon: Text(_mostrarSenha ? '🙈' : '👁️', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
        FieldLabel(
          label: 'Confirmar nova senha',
          child: TextField(
            controller: _confCtrl,
            obscureText: !_mostrarSenha,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _salvando ? null : _salvar(),
            decoration: const InputDecoration(hintText: '••••••••'),
          ),
        ),
      ];

  Widget _aviso(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(texto, style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w700, height: 1.4)),
    );
  }
}
