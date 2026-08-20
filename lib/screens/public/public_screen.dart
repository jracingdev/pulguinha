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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        children: [
          const PulguinhaLogo(size: 64, borderRadius: 14),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FUNCIONAL DO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 1.6,
                  ),
                ),
                Text(
                  'PULGUINHA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neon,
                    letterSpacing: 1.4,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Treino funcional de verdade',
                  style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHome(AppState state) {
    final precoMensal = state.precoPlano('Mensal').toStringAsFixed(0);
    final horarios = state.horariosOrdenados;
    final diasUnicos = horarios.map((h) => h.dias.trim()).where((d) => d.isNotEmpty).toSet();
    final capacidadeMax = horarios.isEmpty ? 0 : horarios.map((h) => h.capacidade).reduce((a, b) => a > b ? a : b);
    final resumoHorarios = [
      if (diasUnicos.length == 1) diasUnicos.first,
      if (capacidadeMax > 0) 'até $capacidadeMax alunos',
      'agende com login (24h–1h antes)',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeonButton(
          label: 'Já sou aluno — Entrar',
          fullWidth: true,
          onPressed: () => state.irParaLogin(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Criar conta',
                fullWidth: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const CadastroAlunoScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GhostButton(
                label: 'Planos a R\$$precoMensal',
                fullWidth: true,
                borderColor: AppColors.mercadoPago.withValues(alpha: 0.35),
                textColor: AppColors.mercadoPago,
                onPressed: () => setState(() => step = 'loja'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PulguinhaCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HORÁRIOS DISPONÍVEIS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resumoHorarios,
                style: const TextStyle(fontSize: 11, color: AppColors.grayDim, height: 1.3),
              ),
              const SizedBox(height: 10),
              HorarioGrid(
                columns: 3,
                spacing: 8,
                childAspectRatio: 1.15,
                children: horarios.map((h) {
                  final ocupadosHoje = state.agendamentosPorDataHorario(MockData.today, h.id).length;
                  return HorarioInfoCard(
                    hora: h.hora,
                    dias: h.dias,
                    capacidade: h.capacidade,
                    ocupadosHoje: ocupadosHoje,
                    compact: true,
                    showDias: false,
                    onTap: () => state.irParaLogin(),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const StudioContactCard(compact: true),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.termos)),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Termos de Uso', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            ),
            const Text('·', style: TextStyle(color: AppColors.grayDim)),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.privacidade)),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Privacidade', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            ),
          ],
        ),
      ],
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
