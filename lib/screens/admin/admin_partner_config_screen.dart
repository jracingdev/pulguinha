import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/models/partner_access.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/services/partner_access_service.dart';
import 'package:pulguinha/services/partner_config_storage.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminPartnerConfigScreen extends StatefulWidget {
  const AdminPartnerConfigScreen({super.key});

  @override
  State<AdminPartnerConfigScreen> createState() => _AdminPartnerConfigScreenState();
}

class _AdminPartnerConfigScreenState extends State<AdminPartnerConfigScreen> {
  final _senhaCtrl = TextEditingController();
  final _wellhubTokenCtrl = TextEditingController();
  final _wellhubGymIdCtrl = TextEditingController();
  final _totalpassApiKeyCtrl = TextEditingController();
  final _totalpassServiceCodeCtrl = TextEditingController();
  final _totalpassPlanCodeCtrl = TextEditingController();
  final _testWellhubIdCtrl = TextEditingController();
  final _testTotalpassCtrl = TextEditingController();

  bool _unlocked = false;
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _obscureWellhub = true;
  bool _obscureTotalpass = true;
  bool _wellhubSandbox = false;
  bool _totalpassSandbox = false;
  String? _erroSenha;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _wellhubTokenCtrl.dispose();
    _wellhubGymIdCtrl.dispose();
    _totalpassApiKeyCtrl.dispose();
    _totalpassServiceCodeCtrl.dispose();
    _totalpassPlanCodeCtrl.dispose();
    _testWellhubIdCtrl.dispose();
    _testTotalpassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _loading = true);
    await PartnerConfig.reload();
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

    final stored = await PartnerConfigStorage.instance.load();
    _wellhubTokenCtrl.text = stored.wellhubBearerToken;
    _wellhubGymIdCtrl.text = stored.wellhubGymId;
    _wellhubSandbox = stored.wellhubUseSandbox;
    _totalpassApiKeyCtrl.text = stored.totalpassApiKey;
    _totalpassServiceCodeCtrl.text = stored.totalpassServiceProviderCode;
    _totalpassPlanCodeCtrl.text = stored.totalpassPlanCode;
    _totalpassSandbox = stored.totalpassUseSandbox;

    setState(() {
      _unlocked = true;
      _erroSenha = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await PartnerConfigStorage.instance.save(
      PartnerStoredConfig(
        wellhubBearerToken: _wellhubTokenCtrl.text,
        wellhubGymId: _wellhubGymIdCtrl.text,
        wellhubUseSandbox: _wellhubSandbox,
        totalpassApiKey: _totalpassApiKeyCtrl.text,
        totalpassServiceProviderCode: _totalpassServiceCodeCtrl.text,
        totalpassPlanCode: _totalpassPlanCodeCtrl.text,
        totalpassUseSandbox: _totalpassSandbox,
      ),
    );
    await PartnerConfig.reload();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Integração GymPass/TotalPass salva neste dispositivo')),
    );
  }

  Future<void> _testWellhub() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await PartnerAccessService.instance.validate(
      provider: PartnerProvider.wellhub,
      identifier: _testWellhubIdCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result.ok ? 'GymPass: check-in válido ✓' : 'GymPass: ${result.message}';
    });
  }

  Future<void> _testTotalpass() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await PartnerAccessService.instance.validate(
      provider: PartnerProvider.totalpass,
      identifier: _testTotalpassCtrl.text,
      identifierType: TotalpassIdentifierType.token,
      mode: PartnerAccessMode.use,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result.ok ? 'TotalPass: check-in confirmado (token consumido) ✓' : 'TotalPass: ${result.message}';
    });
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
        title: const Text('GymPass & TotalPass', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statusCard(),
                  const SizedBox(height: 16),
                  if (!_unlocked) _lockCard() else ..._formCards(),
                ],
              ),
      ),
    );
  }

  Widget _statusCard() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🎫', title: 'Controle de acesso'),
          Text(
            PartnerConfig.integrationLabel(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white, decoration: TextDecoration.none),
          ),
          const SizedBox(height: 8),
          const Text(
            'Opcional: não altera login por e-mail/senha.\n\n'
            'Fluxo oficial (repasse à academia):\n'
            '• GymPass — aluno faz check-in no app; Pulguinha valida via API /access/v1/validate\n'
            '• TotalPass — aluno faz check-in no app; Pulguinha confirma via track_usages (consome token)\n\n'
            'No PC (PowerShell):\n'
            '1. copy supabase\\secrets.local.env.example supabase\\secrets.local.env\n'
            '2. Preencha os tokens\n'
            '3. .\\scripts\\configurar-secrets-parceiros.ps1\n'
            '4. .\\scripts\\deploy-partner-function.ps1\n\n'
            'No app: salve Gym ID e códigos abaixo (tokens sensíveis podem ficar só no Supabase).',
            style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.45, decoration: TextDecoration.none),
          ),
          if (_unlocked) ...[
            const SizedBox(height: 12),
            _checklistRow('GymPass token local', _wellhubTokenCtrl.text.trim().isNotEmpty),
            _checklistRow('GymPass Gym ID', _wellhubGymIdCtrl.text.trim().isNotEmpty),
            _checklistRow('TotalPass API key local', _totalpassApiKeyCtrl.text.trim().isNotEmpty),
            _checklistRow('TotalPass código academia', _totalpassServiceCodeCtrl.text.trim().isNotEmpty),
          ],
        ],
      ),
    );
  }

  Widget _checklistRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(ok ? '✅' : '⬜', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: ok ? AppColors.neon : AppColors.gray, decoration: TextDecoration.none),
            ),
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
          const Text('Digite a senha de admin para editar as credenciais.', style: TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none)),
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
          NeonButton(label: 'Desbloquear', fullWidth: true, onPressed: _unlock),
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
            const SectionTitle(icon: '🟣', title: 'GymPass'),
            TextField(
              controller: _wellhubTokenCtrl,
              obscureText: _obscureWellhub,
              decoration: _fieldDecoration('Bearer token (Access Control API)').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureWellhub ? Icons.visibility : Icons.visibility_off, color: AppColors.gray),
                  onPressed: () => setState(() => _obscureWellhub = !_obscureWellhub),
                ),
              ),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _wellhubGymIdCtrl,
              decoration: _fieldDecoration('X-Gym-Id (ID da academia no GymPass)'),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sandbox GymPass', style: TextStyle(color: AppColors.white, fontSize: 13, decoration: TextDecoration.none)),
              value: _wellhubSandbox,
              activeColor: AppColors.neon,
              onChanged: (v) => setState(() => _wellhubSandbox = v),
            ),
            TextField(
              controller: _testWellhubIdCtrl,
              decoration: _fieldDecoration('Testar ID GymPass (13 dígitos)'),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 8),
            GhostButton(label: _testing ? 'Testando...' : 'Testar GymPass', fullWidth: true, onPressed: _testing ? null : _testWellhub),
          ],
        ),
      ),
      const SizedBox(height: 16),
      PulguinhaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(icon: '🟢', title: 'TotalPass'),
            TextField(
              controller: _totalpassApiKeyCtrl,
              obscureText: _obscureTotalpass,
              decoration: _fieldDecoration('x-api-key').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureTotalpass ? Icons.visibility : Icons.visibility_off, color: AppColors.gray),
                  onPressed: () => setState(() => _obscureTotalpass = !_obscureTotalpass),
                ),
              ),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _totalpassServiceCodeCtrl,
              decoration: _fieldDecoration('Código da academia (service_provider_code)'),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _totalpassPlanCodeCtrl,
              decoration: _fieldDecoration('Código do plano (opcional se só 1 plano)'),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sandbox TotalPass', style: TextStyle(color: AppColors.white, fontSize: 13, decoration: TextDecoration.none)),
              value: _totalpassSandbox,
              activeColor: AppColors.neon,
              onChanged: (v) => setState(() => _totalpassSandbox = v),
            ),
            TextField(
              controller: _testTotalpassCtrl,
              decoration: _fieldDecoration('Testar token TotalPass'),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 8),
            GhostButton(label: _testing ? 'Testando...' : 'Testar TotalPass', fullWidth: true, onPressed: _testing ? null : _testTotalpass),
          ],
        ),
      ),
      if (_testResult != null) ...[
        const SizedBox(height: 12),
        PulguinhaCard(
          child: Text(_testResult!, style: const TextStyle(fontSize: 12, color: AppColors.white, decoration: TextDecoration.none)),
        ),
      ],
      const SizedBox(height: 16),
      NeonButton(
        label: _saving ? 'Salvando...' : '💾 Salvar integração',
        fullWidth: true,
        onPressed: _saving ? null : _save,
      ),
    ];
  }
}
