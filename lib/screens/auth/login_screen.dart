import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserType role = UserType.aluno;
  final emailCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();
  bool mostrarSenha = false;
  bool lembrar = false;
  bool loading = false;
  bool bioDisp = false;
  String erro = '';

  @override
  void initState() {
    super.initState();
    _carregarSalvo();
  }

  Future<void> _carregarSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('pulg_email');
    final savedRole = prefs.getString('pulg_role');
    if (savedEmail != null && savedRole != null) {
      setState(() {
        emailCtrl.text = savedEmail;
        role = savedRole == 'admin' ? UserType.admin : UserType.aluno;
        lembrar = true;
        bioDisp = true;
      });
    }
  }

  Future<void> _biometria() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('pulg_email');
    final savedRole = prefs.getString('pulg_role');
    if (savedEmail == null || savedRole == null) {
      setState(() => erro = 'Nenhuma conta salva para biometria. Faça login e marque "Lembrar".');
      return;
    }

    setState(() {
      erro = '';
      loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final appState = context.read<AppState>();
    final rl = savedRole == 'admin' ? UserType.admin : UserType.aluno;

    if (rl == UserType.admin) {
      if (savedEmail == MockData.adminEmail) {
        setState(() => loading = false);
        appState.login(Usuario(tipo: UserType.admin, nome: MockData.adminNome, email: savedEmail));
        return;
      }
    } else {
      final matches = appState.alunos.where((a) => a.email == savedEmail);
      if (matches.isNotEmpty) {
        setState(() => loading = false);
        appState.login(matches.first.toUsuario());
        return;
      }
    }

    setState(() {
      loading = false;
      erro = 'Conta salva não encontrada. Faça login novamente.';
    });
  }

  Future<void> _tentarLogin({String? email, String? senha, UserType? tipo}) async {
    final em = email ?? emailCtrl.text.trim();
    final sn = senha ?? senhaCtrl.text;
    final rl = tipo ?? role;

    setState(() {
      erro = '';
      loading = true;
    });

    final appState = context.read<AppState>();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    final user = await appState.autenticar(em, sn, rl);
    if (user == null) {
      setState(() {
        loading = false;
        erro = 'E-mail ou senha inválidos.';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (lembrar) {
      await prefs.setString('pulg_email', em);
      await prefs.setString('pulg_role', rl == UserType.admin ? 'admin' : 'aluno');
    } else {
      await prefs.remove('pulg_email');
      await prefs.remove('pulg_role');
    }

    if (!mounted) return;
    setState(() => loading = false);
    appState.login(user);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 36),
              _buildRoleToggle(),
              const SizedBox(height: 28),
              SizedBox(width: 360, child: _buildForm()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.neon,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.4), blurRadius: 30)],
          ),
          alignment: Alignment.center,
          child: const Text('⚡', style: TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 12),
        const Text('FUNCIONAL DO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 2)),
        const Text('PULGUINHA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _roleButton(UserType.aluno, '👤 Aluno'),
            _roleButton(UserType.admin, '⚙️ Admin'),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(UserType tipo, String label) {
    final selected = role == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          role = tipo;
          erro = '';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.neon : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? const Color(0xFF111111) : AppColors.gray),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (role == UserType.admin)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neon.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.neon.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🔐 Acesso restrito — Painel Administrativo', style: TextStyle(fontSize: 11, color: AppColors.neon, fontWeight: FontWeight.w600)),
          ),
        FieldLabel(
          label: 'E-mail',
          child: TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: role == UserType.admin ? MockData.adminEmail : 'seu@email.com'),
          ),
        ),
        FieldLabel(
          label: 'Senha',
          child: TextField(
            controller: senhaCtrl,
            obscureText: !mostrarSenha,
            onSubmitted: (_) => _tentarLogin(),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                onPressed: () => setState(() => mostrarSenha = !mostrarSenha),
                icon: Text(mostrarSenha ? '🙈' : '👁️', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => lembrar = !lembrar),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: lembrar ? AppColors.neon : AppColors.card2,
                      border: Border.all(color: lembrar ? AppColors.neon : AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: lembrar ? const Text('✓', style: TextStyle(fontSize: 12, color: Color(0xFF111111))) : null,
                  ),
                  const SizedBox(width: 8),
                  const Text('Lembrar neste dispositivo', style: TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('Esqueci a senha', style: TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w700))),
          ],
        ),
        const SizedBox(height: 8),
        if (erro.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('⚠️ $erro', style: const TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        NeonButton(
          label: loading ? '⏳ Entrando...' : 'Entrar',
          fullWidth: true,
          enabled: !loading,
          onPressed: () => _tentarLogin(),
        ),
        if (bioDisp) ...[
          const SizedBox(height: 12),
          GhostButton(
            label: '🔑 Entrar com Biometria / Face ID',
            fullWidth: true,
            onPressed: loading ? null : _biometria,
          ),
        ],
        const SizedBox(height: 16),
        PulguinhaCard(
          backgroundColor: AppColors.card2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧪 ACESSO DEMONSTRAÇÃO', style: TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Admin: admin@pulguinha.com / admin123\nAluno: ana@email.com / 1234', style: TextStyle(fontSize: 11, color: AppColors.grayDim, height: 1.8)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: '⚡ Demo Admin',
                      onPressed: () => _tentarLogin(email: MockData.adminEmail, senha: MockData.adminSenha, tipo: UserType.admin),
                      borderColor: AppColors.neon.withValues(alpha: 0.2),
                      textColor: AppColors.neon,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GhostButton(
                      label: '👤 Demo Aluno',
                      onPressed: () {
                        setState(() => role = UserType.aluno);
                        _tentarLogin(email: 'ana@email.com', senha: '1234', tipo: UserType.aluno);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
