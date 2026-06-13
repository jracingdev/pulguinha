import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/qr_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:pulguinha/widgets/qr_widgets.dart';

/// Admin/professor: exibe QR para alunos escanearem. Sem câmera — zero trabalho manual.
class AdminPresencaScreen extends StatelessWidget {
  const AdminPresencaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = MockData.today;
    final presHoje = state.presencasHoje(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRESENÇA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 4),
        Text(
          '${presHoje.length} check-ins hoje · ${DateHelper.formatarData(data)}',
          style: const TextStyle(fontSize: 12, color: AppColors.gray),
        ),
        const SizedBox(height: 8),
        const Text(
          'Exiba o QR na tela ou projetor. Os alunos fazem check-in pelo celular.',
          style: TextStyle(fontSize: 12, color: AppColors.grayDim),
        ),
        const SizedBox(height: 20),
        NeonButton(
          label: '📱 QR do Dia — Tela Cheia',
          fullWidth: true,
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
            builder: (_) => QrDisplayCard(
              data: QrHelper.payloadDia(data),
              titulo: 'QR do Dia',
              subtitulo: DateHelper.formatarDataLonga(data),
              fullScreen: true,
            ),
          )),
        ),
        const SizedBox(height: 20),
        const SectionTitle(icon: '🕐', title: 'QR por Aula — Toque para exibir'),
        ...state.horarios.map((h) {
          final pres = presHoje.where((p) => p.horarioId == h.id).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => QrDisplayCard(
                  data: QrHelper.payloadAula(h.id, data),
                  titulo: 'Aula ${h.hora}',
                  subtitulo: '${h.dias} · ${DateHelper.formatarData(data)}',
                  fullScreen: true,
                ),
              )),
              borderRadius: BorderRadius.circular(16),
              child: PulguinhaCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.neon.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neon.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(h.hora, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neon, fontSize: 13)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.dias, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 14)),
                          Text('Toque para QR em tela cheia', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                        ],
                      ),
                    ),
                    if (pres > 0)
                      PulguinhaBadge(label: '✅ $pres', variant: BadgeVariant.neon)
                    else
                      const Icon(Icons.qr_code_2, color: AppColors.neon, size: 28),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        const SectionTitle(icon: '✅', title: 'Check-ins de Hoje (automático)'),
        if (presHoje.isEmpty)
          const PulguinhaCard(
            child: Column(
              children: [
                PulguinhaLogo(size: 72, showShadow: false),
                SizedBox(height: 8),
                Text('Aguardando check-ins dos alunos', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w700)),
                Text('Exiba o QR acima — os alunos escaneiam ao chegar', style: TextStyle(fontSize: 11, color: AppColors.grayDim)),
              ],
            ),
          )
        else
          ...presHoje.map((p) {
            final aluno = state.alunoPorId(p.alunoId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PulguinhaCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    PulguinhaAvatar(initials: aluno?.avatar ?? '?', size: AvatarSize.sm, fotoBase64: aluno?.foto),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nomeAluno ?? aluno?.nome ?? 'Aluno', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 13)),
                          Text('${p.horario} · ${_formatHora(p.timestamp)}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                        ],
                      ),
                    ),
                    if ((aluno?.streakPresenca ?? 0) >= 3)
                      PulguinhaBadge(label: '🔥 ${aluno!.streakPresenca}', variant: BadgeVariant.yellow),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatHora(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
