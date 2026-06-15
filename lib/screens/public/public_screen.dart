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
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/mock_mode_banner.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class PublicScreen extends StatefulWidget {
  const PublicScreen({super.key, this.initialStep = 'home'});

  final String initialStep;

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  late String step;
  int semana = 0;
  final nomeCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String horarioId = '';
  String data = MockData.today;

  @override
  void initState() {
    super.initState();
    step = widget.initialStep == 'loja' ? 'loja' : 'home';
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
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
                      if (step == 'agendar') _buildAgendar(state),
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
            Expanded(child: _homeCard('📅', 'Agendar Aula', 'Escolha horário e garanta sua vaga', AppColors.neon, () => setState(() => step = 'agendar'))),
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
              HorarioGrid(
                children: state.horarios.map((h) {
                  final ocupadosHoje = state.agendamentosPorDataHorario(MockData.today, h.id).length;
                  return HorarioInfoCard(
                    hora: h.hora,
                    dias: h.dias,
                    capacidade: h.capacidade,
                    ocupadosHoje: ocupadosHoje,
                    onTap: () => setState(() {
                      step = 'agendar';
                      horarioId = '${h.id}';
                      data = MockData.today;
                    }),
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

  Widget _buildAgendar(AppState state) {
    final dias = DateHelper.diasDaSemana(semana);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => step = 'home'),
          icon: const Icon(Icons.chevron_left, color: AppColors.gray, size: 18),
          label: const Text('Voltar', style: TextStyle(color: AppColors.gray)),
        ),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white),
            children: [
              TextSpan(text: 'AGENDE SUA '),
              TextSpan(text: 'AULA', style: TextStyle(color: AppColors.neon)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('Escolha o melhor horário para seu treino funcional.', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        const SizedBox(height: 20),
        FieldLabel(label: 'Seu nome', child: TextField(controller: nomeCtrl, decoration: const InputDecoration(hintText: 'Nome completo'))),
        FieldLabel(label: 'E-mail (opcional)', child: TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'email@exemplo.com'))),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navBtn(() => setState(() => semana--)),
            Text(DateHelper.labelSemana(dias), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
            _navBtn(() => setState(() => semana++), next: true),
          ],
        ),
        const SizedBox(height: 16),
        ...dias.map((dia) => _diaCard(state, dia)),
        const SizedBox(height: 8),
        NeonButton(
          label: '✅ Confirmar Agendamento',
          fullWidth: true,
          onPressed: () => _confirmarAg(state),
        ),
      ],
    );
  }

  Widget _navBtn(VoidCallback onTap, {bool next = false}) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(backgroundColor: AppColors.card2, side: const BorderSide(color: AppColors.border)),
      icon: Icon(next ? Icons.chevron_right : Icons.chevron_left, color: AppColors.white),
    );
  }

  Widget _diaCard(AppState state, DiaSemana dia) {
    final isToday = dia.iso == MockData.today;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PulguinhaCard(
        borderColor: isToday ? AppColors.neon.withValues(alpha: 0.3) : AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: isToday ? AppColors.neon : AppColors.card2, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text('${dia.num}', style: TextStyle(fontWeight: FontWeight.w900, color: isToday ? const Color(0xFF111111) : AppColors.gray)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dia.nome, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: isToday ? AppColors.neon : AppColors.white)),
                    Text('${dia.num} de ${dia.mes}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            HorarioGrid(
              children: state.horarios.map((h) {
                final ags = state.agendamentosPorDataHorario(dia.iso, h.id);
                final lotado = ags.length >= h.capacidade;
                final sel = horarioId == '${h.id}' && data == dia.iso;
                return HorarioSlotCard(
                  hora: h.hora,
                  ocupados: ags.length,
                  capacidade: h.capacidade,
                  selected: sel,
                  enabled: !lotado,
                  onTap: () => setState(() {
                    horarioId = '${h.id}';
                    data = dia.iso;
                  }),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarAg(AppState state) {
    if (nomeCtrl.text.trim().isEmpty || horarioId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha nome e horário.')));
      return;
    }
    final h = state.horarios.firstWhere((x) => x.id == int.parse(horarioId));
    if (state.aulaLotada(data, h.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aula lotada!')));
      return;
    }
    state.criarAgendamento(alunoId: 0, nomeAluno: nomeCtrl.text.trim(), horarioId: h.id, data: data, horario: h.hora);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Agendamento confirmado! ${nomeCtrl.text} às ${h.hora}')));
    setState(() => step = 'home');
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
