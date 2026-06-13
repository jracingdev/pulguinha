import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/config/supabase_config.dart';
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
  final _publicKeyCtrl = TextEditingController();
  final _linkMensalCtrl = TextEditingController();
  final _linkTrimestralCtrl = TextEditingController();
  final _linkSemestralCtrl = TextEditingController();
  final _linkAnualCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;
  bool? _testOk;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _publicKeyCtrl.dispose();
    _linkMensalCtrl.dispose();
    _linkTrimestralCtrl.dispose();
    _linkSemestralCtrl.dispose();
    _linkAnualCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    final stored = await MpConfigStorage.instance.load();
    if (!mounted) return;
    _publicKeyCtrl.text = stored.publicKey;
    _linkMensalCtrl.text = stored.linkPlanoMensal;
    _linkTrimestralCtrl.text = stored.linkPlanoTrimestral;
    _linkSemestralCtrl.text = stored.linkPlanoSemestral;
    _linkAnualCtrl.text = stored.linkPlanoAnual;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final config = MpStoredConfig(
      publicKey: _publicKeyCtrl.text,
      linkPlanoMensal: _linkMensalCtrl.text,
      linkPlanoTrimestral: _linkTrimestralCtrl.text,
      linkPlanoSemestral: _linkSemestralCtrl.text,
      linkPlanoAnual: _linkAnualCtrl.text,
    );
    await MpConfigStorage.instance.save(config);
    await MercadoPagoConfig.reload();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _testResult = null;
      _testOk = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações Mercado Pago salvas')),
    );
  }

  Future<void> _testPublicKey() async {
    setState(() {
      _testing = true;
      _testResult = null;
      _testOk = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = _publicKeyCtrl.text.trim();
    final ok = MercadoPagoConfig.isValidPublicKeyFormat(key);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = ok;
      _testResult = key.isEmpty
          ? 'Informe a Chave Pública para testar.'
          : ok
              ? 'Formato válido (${key.startsWith('TEST-') ? 'sandbox' : 'produção'}).'
              : 'Formato inválido. Use TEST-... ou APP_USR-...';
    });
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado')),
    );
  }

  Future<void> _openMpDevelopers() async {
    final uri = Uri.parse('https://www.mercadopago.com.br/developers/panel/app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grayDim, fontSize: 13),
      filled: true,
      fillColor: AppColors.card2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.mercadoPago)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mercado Pago'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mercadoPago)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.mercadoPago))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _statusBanner(),
                const SizedBox(height: 20),
                _sectionPublicKey(),
                const SizedBox(height: 20),
                _sectionPaymentLinks(),
                const SizedBox(height: 20),
                _sectionAccessToken(),
                const SizedBox(height: 20),
                _sectionCurrentStatus(),
                const SizedBox(height: 24),
                NeonButton(
                  label: _saving ? 'Salvando...' : '💾 Salvar configurações',
                  onPressed: _saving ? null : _save,
                  fullWidth: true,
                  backgroundColor: AppColors.mercadoPago,
                  textColor: Colors.white,
                  enabled: !_saving,
                ),
              ],
            ),
    );
  }

  Widget _statusBanner() {
    final active = MercadoPagoConfig.isRealCheckoutAvailable || MercadoPagoConfig.hasPublicKey;
    final color = active ? AppColors.neon : AppColors.yellow;
    final bg = active ? AppColors.neon.withValues(alpha: 0.08) : AppColors.yellow.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(active ? '✅' : '⚠️', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MercadoPagoConfig.statusIndicatorLabel(),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  MercadoPagoConfig.integrationLabel(),
                  style: const TextStyle(fontSize: 11, color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionPublicKey() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🔑', title: 'Chave Pública (Public Key)'),
          const Text(
            'Segura para armazenar no app. Usada pelo cliente para identificar sua conta MP.',
            style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4),
          ),
          const SizedBox(height: 12),
          FieldLabel(
            label: 'MP_PUBLIC_KEY',
            child: TextField(
              controller: _publicKeyCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              decoration: _fieldDecoration('APP_USR-... ou TEST-...'),
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: NeonButton(
                  label: _testing ? 'Testando...' : '🔍 Testar conexão',
                  onPressed: _testing ? null : _testPublicKey,
                  fullWidth: true,
                  backgroundColor: AppColors.card2,
                  textColor: AppColors.mercadoPago,
                  enabled: !_testing,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _copyToClipboard('MP_PUBLIC_KEY', 'Nome da variável'),
                icon: const Icon(Icons.copy, color: AppColors.gray, size: 20),
                tooltip: 'Copiar nome',
              ),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 8),
            Text(
              _testResult!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _testOk == true ? AppColors.neon : AppColors.yellow,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionPaymentLinks() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🔗', title: 'Links de Pagamento'),
          const Text(
            'Opcional — um link por plano criado no painel Mercado Pago. '
            'Se preenchido, o checkout usa o link direto (sem Edge Function).',
            style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4),
          ),
          const SizedBox(height: 12),
          FieldLabel(
            label: 'Plano Mensal',
            child: TextField(
              controller: _linkMensalCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              decoration: _fieldDecoration('https://mpago.la/...'),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ),
          FieldLabel(
            label: 'Plano Trimestral',
            child: TextField(
              controller: _linkTrimestralCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              decoration: _fieldDecoration('https://mpago.la/...'),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ),
          FieldLabel(
            label: 'Plano Semestral',
            child: TextField(
              controller: _linkSemestralCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              decoration: _fieldDecoration('https://mpago.la/...'),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ),
          FieldLabel(
            label: 'Plano Anual',
            child: TextField(
              controller: _linkAnualCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              decoration: _fieldDecoration('https://mpago.la/...'),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionAccessToken() {
    return PulguinhaCard(
      borderColor: AppColors.red.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🔐', title: 'Access Token (SECRETO)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'O Access Token NUNCA deve ficar no app ou no navegador.\n'
              'Configure em um destes locais:',
              style: TextStyle(fontSize: 12, color: AppColors.white, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          _secretStep(
            number: '1',
            title: 'Supabase (recomendado)',
            lines: const [
              'Project Settings → Edge Functions → Secrets',
              'Nome: MP_ACCESS_TOKEN',
              'Deploy: supabase/functions/create-mp-preference',
            ],
            copyText: 'MP_ACCESS_TOKEN',
          ),
          const SizedBox(height: 12),
          _secretStep(
            number: '2',
            title: 'GitHub Actions (deploy web)',
            lines: const [
              'Repository → Settings → Secrets → Actions',
              'MP_ACCESS_TOKEN',
            ],
            copyText: 'MP_ACCESS_TOKEN',
          ),
          const SizedBox(height: 12),
          _secretStep(
            number: '3',
            title: 'Desenvolvimento local',
            lines: const [
              'supabase secrets set MP_ACCESS_TOKEN=APP_USR-...',
            ],
            copyText: 'supabase secrets set MP_ACCESS_TOKEN=APP_USR-...',
          ),
        ],
      ),
    );
  }

  Widget _secretStep({
    required String number,
    required String title,
    required List<String> lines,
    required String copyText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mercadoPago.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.mercadoPago)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.white)),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(copyText, 'Comando/nome'),
                icon: const Icon(Icons.copy, size: 16, color: AppColors.mercadoPago),
                label: const Text('Copiar', style: TextStyle(fontSize: 11, color: AppColors.mercadoPago)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 2),
              child: Text('→ $line', style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCurrentStatus() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '📊', title: 'Status atual'),
          _statusRow('Modo de checkout', MercadoPagoConfig.checkoutModeLabel()),
          _statusRow('Chave pública', MercadoPagoConfig.hasPublicKey ? 'Configurada' : 'Não configurada'),
          _statusRow('Links de planos', MercadoPagoConfig.hasStaticPaymentLinks ? 'Ativos' : 'Nenhum'),
          _statusRow(
            'Edge Function',
            SupabaseConfig.isConfigured ? 'Supabase conectado' : 'Supabase não configurado',
          ),
          _statusRow('Access Token', 'Somente no servidor (secret)'),
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
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
