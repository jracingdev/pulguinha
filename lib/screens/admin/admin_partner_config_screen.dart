import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/models/partner_access.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/services/partner_access_service.dart';
import 'package:pulguinha/services/partner_config_storage.dart';
import 'package:pulguinha/services/wellhub_sync_service.dart';
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
  bool _syncing = false;
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
    if (_wellhubGymIdCtrl.text.trim().isEmpty) {
      _wellhubGymIdCtrl.text = _wellhubSandbox ? PartnerConfig.sandboxGymId : PartnerConfig.productionGymId;
    }
    if (_testWellhubIdCtrl.text.trim().isEmpty) {
      _testWellhubIdCtrl.text = PartnerConfig.testGympassIds.first;
    }
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

  Future<void> _copyWebhook() async {
    await Clipboard.setData(ClipboardData(text: PartnerConfig.webhookUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL do webhook copiada')),
    );
  }

  Future<void> _syncGrade() async {
    setState(() {
      _syncing = true;
      _testResult = null;
    });
    final result = await WellhubSyncService.instance.syncSchedule();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _testResult = result['ok'] == true
          ? 'Grade sincronizada: ${result['classes'] ?? '?'} classes, ${result['slots_created'] ?? 0} slots novos, ${result['slots_updated'] ?? 0} atualizados.'
          : 'Falha ao sincronizar: ${result['message'] ?? result}';
    });
  }

  void _applyGymIdForSandbox(bool sandbox) {
    final current = _wellhubGymIdCtrl.text.trim();
    final switchingFromProd = current.isEmpty || current == PartnerConfig.productionGymId;
    final switchingFromSandbox = current.isEmpty || current == PartnerConfig.sandboxGymId;
    setState(() {
      _wellhubSandbox = sandbox;
      if (sandbox && switchingFromProd) {
        _wellhubGymIdCtrl.text = PartnerConfig.sandboxGymId;
      } else if (!sandbox && switchingFromSandbox) {
        _wellhubGymIdCtrl.text = PartnerConfig.productionGymId;
      }
    });
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
        title: const Text('Wellhub & TotalPass', style: TextStyle(fontWeight: FontWeight.w900)),
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
          const SectionTitle(icon: '🎫', title: 'Controle de Acesso & Agendamento'),
          Text(
            PartnerConfig.integrationLabel(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white, decoration: TextDecoration.none),
          ),
          const SizedBox(height: 8),
          const Text(
            'Integração oficial para validação de check-in e agendamento de aulas.\n\n'
            '📌 Fluxo de Acesso e Repasse:\n'
            '• Wellhub: aluno faz check-in no app oficial; Pulguinha valida via /access/v1/validate.\n'
            '• Automated Trigger: webhook de check-in + validate (uma vez por dia).\n'
            '• Attendance: login no app com ID Wellhub (não revalida o mesmo check-in no dia).\n'
            '• Booking: grade sincronizada (classes/slots); PATCH de reserva em até 15 min.\n'
            '• TotalPass: aluno faz check-in no app oficial; Pulguinha confirma via /v1/track_usages.\n\n'
            '⚖️ Diretrizes Contratuais e Compliance LGPD:\n'
            '1. Gratuidade: É proibido cobrar taxas adicionais dos alunos pelo uso da integração.\n'
            '2. Privacidade: Os dados (nome, email, telefone, ID/CPF) são estritamente para agendamento e acesso. Proibido contato para marketing próprio ou venda a terceiros.\n'
            '3. SLAs e Titulares: Resposta de suporte em até 24h (12h para incidentes graves). Atendimento a solicitações de titulares (LGPD) em até 48h úteis.\n\n'
            'Unidade de produção: Funcional do Pulguinha · Gym ID 824346\n'
            'Sandbox (e-mail de teste): Gym ID 683 + WELLHUB_SANDBOX=true\n\n'
            'Configuração segura no Supabase (recomendado):\n'
            '1. Edite supabase/secrets.local.env com as chaves (não commitar a api_key).\n'
            '2. Execute scripts/configurar-secrets-parceiros.ps1 e scripts/deploy-wellhub.ps1.\n'
            '3. Envie a URL do webhook e o WELLHUB_WEBHOOK_SECRET à Wellhub.\n'
            '4. No app, o Gym ID da unidade de produção é 824346.',
            style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.45, decoration: TextDecoration.none),
          ),
          if (_unlocked) ...[
            const SizedBox(height: 12),
            _checklistRow('Wellhub token configurado', _wellhubTokenCtrl.text.trim().isNotEmpty),
            _checklistRow('Wellhub Gym ID configurado', _wellhubGymIdCtrl.text.trim().isNotEmpty),
            _checklistRow('TotalPass API key configurada', _totalpassApiKeyCtrl.text.trim().isNotEmpty),
            _checklistRow('TotalPass código academia configurado', _totalpassServiceCodeCtrl.text.trim().isNotEmpty),
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
            const SectionTitle(icon: '🟣', title: 'Wellhub (GymPass)'),
            const Text(
              'Unidade de produção: Funcional do Pulguinha\n'
              'Gym ID produção (X-Gym-Id): 824346\n'
              'Sandbox (teste): 683',
              style: TextStyle(fontSize: 12, color: AppColors.white, height: 1.4, fontWeight: FontWeight.w700, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _wellhubTokenCtrl,
              obscureText: _obscureWellhub,
              decoration: _fieldDecoration('Bearer token (Access Control / Booking API)').copyWith(
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
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                _wellhubSandbox
                    ? 'Gym ID sandbox (683)'
                    : 'Gym ID produção — Funcional do Pulguinha (824346)',
              ),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cole o ID da unidade. Produção: 824346. Testes do e-mail Wellhub: 683 + sandbox ligado.',
              style: TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sandbox Wellhub (apitesting · gym_id 683)', style: TextStyle(color: AppColors.white, fontSize: 13, decoration: TextDecoration.none)),
              value: _wellhubSandbox,
              activeColor: AppColors.neon,
              onChanged: _applyGymIdForSandbox,
            ),
            const SizedBox(height: 8),
            const Text('URL única do webhook (enviar à Wellhub)', style: TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
            const SizedBox(height: 6),
            SelectableText(
              PartnerConfig.webhookUrl,
              style: const TextStyle(fontSize: 11, color: AppColors.neon, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 8),
            GhostButton(label: 'Copiar URL do webhook', fullWidth: true, onPressed: _copyWebhook),
            const SizedBox(height: 10),
            GhostButton(
              label: _syncing ? 'Sincronizando grade...' : 'Sincronizar grade (classes + slots 14 dias)',
              fullWidth: true,
              onPressed: _syncing ? null : _syncGrade,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _testWellhubIdCtrl,
              decoration: _fieldDecoration('ID de teste da coleção: 1000000000001 ou 1000000000003'),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in PartnerConfig.testGympassIds)
                  ActionChip(
                    label: Text(id, style: const TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _testWellhubIdCtrl.text = id),
                    backgroundColor: AppColors.card2,
                    labelStyle: const TextStyle(color: AppColors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GhostButton(label: _testing ? 'Testando...' : 'Testar Wellhub', fullWidth: true, onPressed: _testing ? null : _testWellhub),
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
              decoration: _fieldDecoration('Código do plano (service_provider_plan_code opcional)'),
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sandbox TotalPass (staging)', style: TextStyle(color: AppColors.white, fontSize: 13, decoration: TextDecoration.none)),
              value: _totalpassSandbox,
              activeColor: AppColors.neon,
              onChanged: (v) => setState(() => _totalpassSandbox = v),
            ),
            TextField(
              controller: _testTotalpassCtrl,
              decoration: _fieldDecoration('Testar token ou CPF TotalPass'),
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
