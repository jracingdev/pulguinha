import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/screens/auth/cadastro_aluno_screen.dart';
import 'package:pulguinha/screens/shared/legal_screen.dart';
import 'package:pulguinha/screens/shared/loja_screen.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/mock_mode_banner.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:pulguinha/widgets/studio_contact_card.dart';

class PublicScreen extends StatefulWidget {
  const PublicScreen({super.key, this.initialStep = 'home'});

  final String initialStep;

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  late String step;

  @override
  void initState() {
    super.initState();
    step = widget.initialStep == 'loja' ? 'loja' : 'home';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !SupabaseConfig.isConfigured) return;
      final state = context.read<AppState>();
      if (state.useMock) state.garantirConexaoSupabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neon,
          backgroundColor: AppColors.card2,
          onRefresh: SupabaseConfig.isConfigured
              ? () async {
                  if (state.useMock) await state.garantirConexaoSupabase();
                  await state.recarregarDados();
                }
              : () async {},
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _buildHero(),
                      const MockModeBanner(adminOnly: true),
                      if (step == 'home') _buildHome(state),
                      if (step == 'loja') _buildLoja(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const PulguinhaLogo(size: 136, borderRadius: 24),
          const SizedBox(height: 12),
          const Text('FUNCIONAL DO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 2)),
          const Text('PULGUINHA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neon, letterSpacing: 2)),
          const SizedBox(height: 6),
          const Text('Treino funcional de verdade', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _buildHome(AppState state) {
    final precoMensal = state.precoPlano('Mensal').toStringAsFixed(0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _homeCard(
                '📅',
                'Agendar Aula',
                'Faça login para escolher horário e garantir sua vaga',
                AppColors.neon,
                () => state.irParaLogin(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _homeCard('💳', 'Assinar Plano', 'Planos mensais a partir de R\$$precoMensal', AppColors.mercadoPago, () => setState(() => step = 'loja'))),
          ],
        ),
        const SizedBox(height: 24),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: '📋', title: 'Horários disponíveis'),
              const SizedBox(height: 4),
              const Text(
                'Agendamento somente com login, entre 24h e 1h antes do treino.',
                style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.4),
              ),
              const SizedBox(height: 12),
              HorarioGrid(
                children: state.horariosOrdenados.map((h) {
                  final ocupadosHoje = state.agendamentosPorDataHorario(MockData.today, h.id).length;
                  return HorarioInfoCard(
                    hora: h.hora,
                    dias: h.dias,
                    capacidade: h.capacidade,
                    ocupadosHoje: ocupadosHoje,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GhostButton(
          label: '🔐 Já sou aluno — Fazer login',
          fullWidth: true,
          borderColor: AppColors.neon.withValues(alpha: 0.2),
          textColor: AppColors.neon,
          onPressed: () => state.irParaLogin(),
        ),
        const SizedBox(height: 12),
        GhostButton(
          label: '📝 Criar conta de aluno',
          fullWidth: true,
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CadastroAlunoScreen())),
        ),
        const SizedBox(height: 16),
        const StudioContactCard(compact: true),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.termos))),
              child: const Text('Termos de Uso', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            ),
            const Text('·', style: TextStyle(color: AppColors.grayDim)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.privacidade))),
              child: const Text('Privacidade', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _homeCard(String icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.white)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoja() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => step = 'home'),
          icon: const Icon(Icons.chevron_left, color: AppColors.gray, size: 18),
          label: const Text('Voltar', style: TextStyle(color: AppColors.gray)),
        ),
        const LojaScreen(usuario: Usuario(tipo: UserType.publico, nome: 'Visitante', email: '')),
      ],
    );
  }
}
