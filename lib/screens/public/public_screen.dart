import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/screens/shared/loja_screen.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class PublicScreen extends StatefulWidget {
  const PublicScreen({super.key});

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  String step = 'home';
  int semana = 0;
  final nomeCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String horarioId = '';
  String data = MockData.today;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHero(),
              if (step == 'home') _buildHome(state),
              if (step == 'agendar') _buildAgendar(state),
              if (step == 'loja') _buildLoja(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.neon,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.4), blurRadius: 30)],
            ),
            alignment: Alignment.center,
            child: const Text('⚡', style: TextStyle(fontSize: 28)),
          ),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _homeCard('📅', 'Agendar Aula', 'Escolha horário e garanta sua vaga', AppColors.neon, () => setState(() => step = 'agendar'))),
            const SizedBox(width: 12),
            Expanded(child: _homeCard('💳', 'Assinar Plano', 'Planos mensais a partir de R\$150', AppColors.mercadoPago, () => setState(() => step = 'loja'))),
          ],
        ),
        const SizedBox(height: 24),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: '📋', title: 'Horários disponíveis'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.horarios.map((h) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 72) / 2,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.card2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.hora, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neon, fontSize: 15)),
                          Text(h.dias, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                          Text('até ${h.capacidade} alunos', style: const TextStyle(fontSize: 11, color: AppColors.grayDim)),
                        ],
                      ),
                    ),
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
            _navBtn(() => setState(() => semana++)),
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

  Widget _navBtn(VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(backgroundColor: AppColors.card2, side: const BorderSide(color: AppColors.border)),
      icon: const Icon(Icons.chevron_left, color: AppColors.white),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.horarios.map((h) {
                final ags = state.agendamentosPorDataHorario(dia.iso, h.id);
                final lotado = ags.length >= h.capacidade;
                final sel = horarioId == '${h.id}' && data == dia.iso;
                return GestureDetector(
                  onTap: lotado
                      ? null
                      : () => setState(() {
                            horarioId = '${h.id}';
                            data = dia.iso;
                          }),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 88) / 2,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.neon.withValues(alpha: 0.12) : AppColors.card2,
                      border: Border.all(color: sel ? AppColors.neon : lotado ? AppColors.red.withValues(alpha: 0.2) : AppColors.border, width: sel ? 2 : 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.hora, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: sel ? AppColors.neon : AppColors.white)),
                        Text('${ags.length}/${h.capacidade} ${lotado ? "LOTADO" : "vagas"}', style: TextStyle(fontSize: 11, color: lotado ? AppColors.red : AppColors.gray)),
                      ],
                    ),
                  ),
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
