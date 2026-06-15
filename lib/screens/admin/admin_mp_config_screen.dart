import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/services/mp_config_storage.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMpConfigScreen extends StatefulWidget {
  const AdminMpConfigScreen({super.key});

  @override
  State<AdminMpConfigScreen> createState() => _AdminMpConfigScreenState();
}

class _AdminMpConfigScreenState extends State<AdminMpConfigScreen> {
  final _senhaCtrl = TextEditingController();
  final _publicKeyCtrl = TextEditingController();
  final _accessTokenCtrl = TextEditingController();
  final _linkMensalCtrl = TextEditingController();
  final _linkTrimestralCtrl = TextEditingController();
  final _linkSemestralCtrl = TextEditingController();
  final _linkAnualCtrl = TextEditingController();

  bool _unlocked = false;
  bool _loading = true;
  bool _saving = false;
  bool _obscureToken = true;
  String? _erroSenha;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _publicKeyCtrl.dispose();
    _accessTokenCtrl.dispose();
    _linkMensalCtrl.dispose();
    _linkTrimestralCtrl.dispose();
    _linkSemestralCtrl.dispose();
    _linkAnualCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _loading = true);
    await MercadoPagoConfig.reload();
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

    final stored = await MpConfigStorage.instance.load();
    _publicKeyCtrl.text = stored.publicKey;
    _accessTokenCtrl.text = stored.accessToken;
    _linkMensalCtrl.text = stored.linkPlanoMensal;
    _linkTrimestralCtrl.text = stored.linkPlanoTrimestral;
    _linkSemestralCtrl.text = stored.linkPlanoSemestral;
    _linkAnualCtrl.text = stored.linkPlanoAnual;

    setState(() {
      _unlocked = true;
      _erroSenha = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await MpConfigStorage.instance.save(
      MpStoredConfig(
        publicKey: _publicKeyCtrl.text,
        accessToken: _accessTokenCtrl.text,
        linkPlanoMensal: _linkMensalCtrl.text,
        linkPlanoTrimestral: _linkTrimestralCtrl.text,
        linkPlanoSemestral: _linkSemestralCtrl.text,
        linkPlanoAnual: _linkAnualCtrl.text,
      ),
    );
    await MercadoPagoConfig.reload();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciais Mercado Pago salvas neste dispositivo')),
    );
  }

  Future<void> _openMpDevelopers() async {
    final uri = Uri.parse('https://www.mercadopago.com.br/developers/panel/app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grayDim, fontSize: 13),
        filled: true,
        fillColor: AppColors.card2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.mercadoPago)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mercado Pago'),
        actions: [
          if (_unlocked)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mercadoPago)),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.mercadoPago))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!_unlocked) ...[
                    _lockCard(),
                  ] else ...[
                    _credentialsCard(),
                    const SizedBox(height: 16),
                    _linksCard(),
                  ],
                  const SizedBox(height: 20),
                  _statusCard(),
                ],
              ),
      ),
    );
  }

  Widget _lockCard() {
    return PulguinhaCard(
      borderColor: AppColors.mercadoPago.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🔐', title: 'Proteção admin'),
          const Text(
            'As credenciais do Mercado Pago ficam salvas neste app (ideal para personalizar por academia). '
            'Confirme sua senha de administrador para visualizar e editar.',
            style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.45, decoration: TextDecoration.none),
          ),
          const SizedBox(height: 14),
          FieldLabel(
            label: 'Senha do admin',
            child: TextField(
              controller: _senhaCtrl,
              obscureText: true,
              decoration: _fieldDecoration('Digite sua senha de admin'),
              onSubmitted: (_) => _unlock(),
            ),
          ),
          if (_erroSenha != null) ...[
            const SizedBox(height: 8),
            Text(_erroSenha!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          NeonButton(label: 'Desbloquear configurações', fullWidth: true, backgroundColor: AppColors.mercadoPago, textColor: Colors.white, onPressed: _unlock),
        ],
      ),
    );
  }

  Widget _credentialsCard() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '💳', title: 'Credenciais da academia'),
          FieldLabel(
            label: 'Chave pública (Public Key)',
            child: TextField(controller: _publicKeyCtrl, decoration: _fieldDecoration('APP_USR-... ou TEST-...'), autocorrect: false),
          ),
          FieldLabel(
            label: 'Access Token (produção ou teste)',
            child: TextField(
              controller: _accessTokenCtrl,
              obscureText: _obscureToken,
              decoration: _fieldDecoration('APP_USR-...').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility, color: AppColors.gray, size: 20),
                  onPressed: () => setState(() => _obscureToken = !_obscureToken),
                ),
              ),
              autocorrect: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.yellow.withValues(alpha: 0.25)),
            ),
            child: const Text(
              'O token fica armazenado neste dispositivo. Cada academia configura o seu. '
              'Em APK/Android funciona direto; na web pode exigir proxy se o navegador bloquear a API.',
              style: TextStyle(fontSize: 11, color: AppColors.white, height: 1.4, decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linksCard() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🔗', title: 'Links de pagamento (opcional)'),
          const Text('Se preenchido, o checkout usa o link direto do plano.', style: TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none)),
          const SizedBox(height: 10),
          FieldLabel(label: 'Plano Mensal', child: TextField(controller: _linkMensalCtrl, decoration: _fieldDecoration('https://mpago.la/...'))),
          FieldLabel(label: 'Plano Trimestral', child: TextField(controller: _linkTrimestralCtrl, decoration: _fieldDecoration('https://mpago.la/...'))),
          FieldLabel(label: 'Plano Semestral', child: TextField(controller: _linkSemestralCtrl, decoration: _fieldDecoration('https://mpago.la/...'))),
          FieldLabel(label: 'Plano Anual', child: TextField(controller: _linkAnualCtrl, decoration: _fieldDecoration('https://mpago.la/...'))),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '📊', title: 'Status atual'),
          _statusRow('Modo de checkout', MercadoPagoConfig.checkoutModeLabel()),
          _statusRow('Chave pública', MercadoPagoConfig.hasPublicKey ? 'Configurada' : 'Não configurada'),
          _statusRow('Access Token', MercadoPagoConfig.hasAccessToken ? 'Configurado no app' : 'Não configurado'),
          _statusRow('Links de planos', MercadoPagoConfig.hasStaticPaymentLinks ? 'Ativos' : 'Nenhum'),
          const SizedBox(height: 12),
          GhostButton(
            label: '🌐 Abrir painel Mercado Pago Developers',
            onPressed: _openMpDevelopers,
            fullWidth: true,
            borderColor: AppColors.mercadoPago.withValues(alpha: 0.3),
            textColor: AppColors.mercadoPago,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white, decoration: TextDecoration.none))),
        ],
      ),
    );
  }
}
