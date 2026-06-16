import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class DesafiosAlunoSection extends StatelessWidget {
  const DesafiosAlunoSection({super.key, required this.alunoId});

  final int alunoId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final desafios = state.desafiosAtivos();
    if (desafios.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: '🏆', title: 'Desafios ativos'),
        const SizedBox(height: 8),
        ...desafios.map((d) {
          final prog = state.progressoDesafio(alunoId, d.id);
          final atual = prog?.progresso ?? 0;
          final pct = d.meta > 0 ? (atual / d.meta).clamp(0.0, 1.0) : 0.0;
          final concluido = prog?.concluido == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PulguinhaCard(
              borderColor: concluido ? AppColors.yellow.withValues(alpha: 0.35) : AppColors.neon.withValues(alpha: 0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_icone(d.tipo), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d.titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white))),
                      if (concluido)
                        const PulguinhaBadge(label: '✓ Feito', variant: BadgeVariant.yellow)
                      else
                        PulguinhaBadge(label: '+${d.pontosRecompensa} pts', variant: BadgeVariant.neon),
                    ],
                  ),
                  if (d.descricao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(d.descricao, style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.35)),
                    ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.card3, color: concluido ? AppColors.yellow : AppColors.neon),
                  ),
                  const SizedBox(height: 4),
                  Text('$atual / ${d.meta}', style: const TextStyle(fontSize: 10, color: AppColors.grayDim, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _icone(TipoDesafio t) => switch (t) {
        TipoDesafio.checkins => '✅',
        TipoDesafio.streak => '🔥',
        TipoDesafio.agua => '💧',
      };
}
