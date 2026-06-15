import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/services/pagbank_config_storage.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminPagBankConfigScreen extends StatefulWidget {
  const AdminPagBankConfigScreen({super.key});

  @override
  State<AdminPagBankConfigScreen> createState() => _AdminPagBankConfigScreenState();
}

class _AdminPagBankConfigScreenState extends State<AdminPagBankConfigScreen> {
  final _senhaCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _redirectCtrl = TextEditingController();

  bool _unlocked = false;
  bool _loading = true;
  bool _saving = false;
  bool _obscureToken = true;
  bool _useSandbox = false;
  String? _erroSenha;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _tokenCtrl.dispose();
    _redirectCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _loading = true);
    await PagBankConfig.reload();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _unlock() async {
    final state = context.read<AppState>();
    final admin = state.usuario;
    if (admin == null || !admin.isAdmin) return;

    final ok = await state.autenticar(admin.email, _senhaCtrl.text, UserType.admin);
    if (!mounted) return;

    if (ok == null) {
      setState(() => _erroSenha = 'Senha de admin incorreta');
      return;
    }

    final stored = await PagBankConfigStorage.instance.load();
    _tokenCtrl.text = stored.token;
    _redirectCtrl.text = stored.redirectUrl;
    _useSandbox = stored.useSandbox;

    setState(() {
      _unlocked = true;
      _erroSenha = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await PagBankConfigStorage.instance.save(
      PagBankStoredConfig(
        token: _tokenCtrl.text,
        useSandbox: _useSandbox,
        redirectUrl: _redirectCtrl.text,
      ),
    );
    await PagBankConfig.reload();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciais PagBank salvas neste dispositivo')),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grayDim, fontSize: 12),
        filled: true,
        fillColor: AppColors.card2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('PagBank / PagSeguro', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pagBank))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statusCard(),
                const SizedBox(height: 16),
                if (!_unlocked) _lockCard() else ..._formCards(),
              ],
            ),
    );
  }

  Widget _statusCard() {
    final ativo = PagBankConfig.isRealCheckoutAvailable;
    return PulguinhaCard(
      borderColor: ativo ? AppColors.pagBank.withValues(alpha: 0.35) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏦', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  PagBankConfig.checkoutModeLabel(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white, decoration: TextDecoration.none),
                ),
              ),
              PulguinhaBadge(label: ativo ? 'Ativo' : 'Não configurado', variant: ativo ? BadgeVariant.pagBank : BadgeVariant.yellow),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ativo
                ? 'Checkout via API PagBank (${PagBankConfig.useSandbox ? "sandbox" : "produção"}).'
                : 'Gere o token em PagBank → Venda online → Integrações.',
            style: const TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }

  Widget _lockCard() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🔒', title: 'Desbloquear configuração'),
          const Text('Digite a senha de admin para editar o token PagBank.', style: TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none)),
          const SizedBox(height: 12),
          TextField(
            controller: _senhaCtrl,
            obscureText: true,
            decoration: _fieldDecoration('Senha do admin'),
            style: const TextStyle(color: AppColors.white),
          ),
          if (_erroSenha != null) ...[
            const SizedBox(height: 8),
            Text(_erroSenha!, style: const TextStyle(color: AppColors.red, fontSize: 12, decoration: TextDecoration.none)),
          ],
          const SizedBox(height: 12),
          NeonButton(label: 'Desbloquear', fullWidth: true, backgroundColor: AppColors.pagBank, textColor: Colors.white, onPressed: _unlock),
        ],
      ),
    );
  }

  List<Widget> _formCards() {
    return [
      PulguinhaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(icon: '🔑', title: 'Token de autenticação'),
            TextField(
              controller: _tokenCtrl,
              obscureText: _obscureToken,
              decoration: _fieldDecoration('Bearer token PagBank').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off, color: AppColors.gray),
                  onPressed: () => setState(() => _obscureToken = !_obscureToken),
                ),
              ),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ambiente Sandbox (testes)', style: TextStyle(color: AppColors.white, fontSize: 13, decoration: TextDecoration.none)),
              subtitle: const Text('Desative em produção com token real.', style: TextStyle(color: AppColors.gray, fontSize: 11, decoration: TextDecoration.none)),
              value: _useSandbox,
              activeColor: AppColors.pagBank,
              onChanged: (v) => setState(() => _useSandbox = v),
            ),
            const SizedBox(height: 8),
            FieldLabel(
              label: 'URL de retorno após pagamento',
              child: TextField(
                controller: _redirectCtrl,
                decoration: _fieldDecoration('https://funcionaldopulguinha.com.br/loja'),
                style: const TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      NeonButton(
        label: _saving ? 'Salvando...' : '💾 Salvar credenciais',
        fullWidth: true,
        backgroundColor: AppColors.pagBank,
        textColor: Colors.white,
        onPressed: _saving ? null : _save,
      ),
    ];
  }
}
