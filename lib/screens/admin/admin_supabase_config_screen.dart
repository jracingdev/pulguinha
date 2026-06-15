import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/services/supabase_settings_storage.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminSupabaseConfigScreen extends StatefulWidget {
  const AdminSupabaseConfigScreen({super.key});

  @override
  State<AdminSupabaseConfigScreen> createState() => _AdminSupabaseConfigScreenState();
}

class _AdminSupabaseConfigScreenState extends State<AdminSupabaseConfigScreen> {
  final _senhaCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _anonCtrl = TextEditingController();

  bool _unlocked = false;
  bool _saving = false;
  bool _obscureKey = true;
  String? _erroSenha;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _urlCtrl.dispose();
    _anonCtrl.dispose();
    super.dispose();
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

    final stored = await SupabaseSettingsStorage.instance.load();
    _urlCtrl.text = stored.url;
    _anonCtrl.text = stored.anonKey;

    setState(() {
      _unlocked = true;
      _erroSenha = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await SupabaseSettingsStorage.instance.save(
      SupabaseStoredSettings(url: _urlCtrl.text, anonKey: _anonCtrl.text),
    );
    await SupabaseConfig.reload();
    if (!mounted) return;

    final state = context.read<AppState>();
    final conectou = await state.conectarSupabase();

    if (!mounted) return;
    setState(() => _saving = false);

    if (conectou && state.alunosPendentes > 0) {
      state.setAdminTab('alunos');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          conectou
              ? state.alunosPendentes > 0
                  ? 'Supabase conectado! ${state.alunosPendentes} cadastro(s) pendente(s) — aba Alunos aberta.'
                  : 'Supabase conectado! Cadastros da web já devem aparecer — puxe a tela para atualizar.'
              : 'Credenciais salvas, mas não foi possível conectar. Verifique URL, chave anon e internet.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grayDim, fontSize: 12),
        filled: true,
        fillColor: AppColors.card2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      );

  @override
  Widget build(BuildContext context) {
    final conectado = SupabaseConfig.isConfigured && !context.watch<AppState>().useMock;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('Conexão Supabase', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PulguinhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('☁️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        conectado ? 'Conectado ao banco na nuvem' : 'Não conectado',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white, decoration: TextDecoration.none),
                      ),
                    ),
                    PulguinhaBadge(
                      label: conectado ? 'Online' : 'Offline',
                      variant: conectado ? BadgeVariant.neon : BadgeVariant.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cadastros feitos no site só aparecem no admin quando o app está conectado ao mesmo projeto Supabase.',
                  style: TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_unlocked)
            PulguinhaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(icon: '🔒', title: 'Desbloquear'),
                  TextField(controller: _senhaCtrl, obscureText: true, decoration: _field('Senha do admin'), style: const TextStyle(color: AppColors.white)),
                  if (_erroSenha != null) ...[
                    const SizedBox(height: 8),
                    Text(_erroSenha!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  NeonButton(label: 'Desbloquear', fullWidth: true, onPressed: _unlock),
                ],
              ),
            )
          else ...[
            PulguinhaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(icon: '🔗', title: 'Credenciais'),
                  FieldLabel(label: 'Project URL', child: TextField(controller: _urlCtrl, decoration: _field('https://xxx.supabase.co'), style: const TextStyle(color: AppColors.white, fontSize: 12))),
                  FieldLabel(
                    label: 'Anon public key',
                    child: TextField(
                      controller: _anonCtrl,
                      obscureText: _obscureKey,
                      decoration: _field('eyJ...').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off, color: AppColors.gray),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NeonButton(label: _saving ? 'Salvando...' : '💾 Salvar e conectar', fullWidth: true, onPressed: _saving ? null : _save),
          ],
        ],
      ),
    );
  }
}
