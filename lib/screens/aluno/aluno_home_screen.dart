import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/celebration_widgets.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:pulguinha/widgets/wellness_widgets.dart';

class AlunoHomeScreen extends StatelessWidget {
  const AlunoHomeScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final aluno = state.alunoPorId(usuario.id) ?? Aluno(
      id: usuario.id ?? 0,
      nome: usuario.nome,
      email: usuario.email,
      senha: '',
      telefone: usuario.telefone ?? '',
      plano: usuario.plano ?? 'Mensal',
      vencimento: usuario.vencimento ?? MockData.today,
      status: usuario.status ?? 'Ativo',
      avatar: usuario.avatar ?? 'AL',
      streakPresenca: usuario.streakPresenca ?? 0,
      pulguinhaPoints: usuario.pulguinhaPoints ?? 0,
    );
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    final meusAgs = state.agendamentos.where((ag) => ag.alunoId == aluno.id && ag.data.compareTo(MockData.today) >= 0).take(5).toList();
    final isBirthday = DateHelper.isAniversarioHoje(aluno.dataNascimento);
    final jaCheckinHoje = state.presencasHoje().any((p) => p.alunoId == aluno.id);

    return ConfettiOverlay(
      active: isBirthday,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBirthday)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.yellow.withValues(alpha: 0.2), AppColors.neon.withValues(alpha: 0.1)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.yellow.withValues(alpha: 0.4)),
              ),
              child: Text(
                '🎉 Parabéns, ${aluno.nome.split(' ').first}! Feliz aniversário!',
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), AppColors.bg]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    PulguinhaAvatar(initials: aluno.avatar, size: AvatarSize.lg, fotoBase64: aluno.foto),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Olá, ${aluno.nome.split(' ').first}! 💪', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.white)),
                          const Text('Pronto para treinar?', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                          if (aluno.streakPresenca >= 2) ...[
                            const SizedBox(height: 6),
                            PulguinhaBadge(label: '🔥 ${aluno.streakPresenca} treinos seguidos', variant: BadgeVariant.yellow),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                NeonButton(
                  label: jaCheckinHoje ? '✅ Check-in feito hoje!' : '📷 Fazer Check-in',
                  fullWidth: true,
                  enabled: !jaCheckinHoje,
                  onPressed: () => state.setAlunoTab('checkin'),
                ),
                if (aluno.pulguinhaPoints > 0) ...[
                  const SizedBox(height: 8),
                  Text('⭐ ${aluno.pulguinhaPoints} Pulguinha Points', style: const TextStyle(fontSize: 11, color: AppColors.neon, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card2,
                    border: Border.all(color: d < 0 ? AppColors.red : d <= 7 ? AppColors.yellow.withValues(alpha: 0.4) : AppColors.neon.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PLANO ${aluno.plano.toUpperCase()}', style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w700)),
                            Text(
                              d < 0 ? 'Vencido há ${d.abs()} dias' : d == 0 ? 'Vence hoje!' : d <= 7 ? 'Vence em $d dias' : DateHelper.formatarData(aluno.vencimento),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: d < 0 ? AppColors.red : d <= 7 ? AppColors.yellow : AppColors.neon),
                            ),
                          ],
                        ),
                      ),
                      PulguinhaBadge(label: aluno.status, variant: aluno.status == 'Ativo' ? BadgeVariant.neon : BadgeVariant.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MegaAguaCard(
            compact: true,
            onVerMais: () => state.setAlunoTab('evolucao'),
          ),
          const SizedBox(height: 16),
          DicaDoDiaCard(onVerTodas: () => state.setAlunoTab('evolucao')),
          const SizedBox(height: 20),
          const SectionTitle(icon: '📅', title: 'Meus Próximos Treinos'),
          if (meusAgs.isEmpty)
            const PulguinhaCard(
              child: Column(
                children: [
                  PulguinhaLogo(size: 40, showShadow: false),
                  SizedBox(height: 8),
                  Text('Nenhum treino agendado', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray)),
                  SizedBox(height: 4),
                  Text('Vá para Agenda e agende sua aula!', style: TextStyle(fontSize: 12, color: AppColors.grayDim)),
                ],
              ),
            )
          else
            ...meusAgs.map((ag) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PulguinhaCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.neon.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.neon.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(ag.horario, style: const TextStyle(color: AppColors.neon, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateHelper.formatarDataLonga(ag.data), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                              const Text('Treino funcional', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                            ],
                          ),
                        ),
                        const PulguinhaBadge(label: '✓ Conf.'),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
