import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/mention_helper.dart';
import 'package:pulguinha/widgets/mention_text_field.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AlunoAvisosScreen extends StatelessWidget {
  const AlunoAvisosScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final alunoId = usuario.id!;
    final paraVoce = <dynamic>[];
    for (final a in state.avisosParaAluno(alunoId)) {
      if (MentionHelper.alunoMencionado(alunoId, a.mencoes) && !state.comunicacaoLida('aviso', a.id)) {
        paraVoce.add(a);
      }
    }
    for (final e in state.eventosProximos()) {
      if (MentionHelper.alunoMencionado(alunoId, e.mencoes) && !state.comunicacaoLida('evento', e.id)) {
        paraVoce.add(e);
      }
    }
    final avisos = state.avisosParaAluno(alunoId);
    final eventos = state.eventosProximos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AVISOS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 4),
        const Text('Quadro oficial e eventos do estúdio', style: TextStyle(fontSize: 12, color: AppColors.gray)),
        const SizedBox(height: 16),
        if (paraVoce.isNotEmpty) ...[
          const SectionTitle(icon: '@', title: 'Para você'),
          ...paraVoce.map((item) => _itemCard(context, state, alunoId, item)),
          const SizedBox(height: 16),
        ],
        const SectionTitle(icon: '📢', title: 'Quadro de avisos'),
        if (avisos.isEmpty)
          const PulguinhaCard(child: Text('Nenhum aviso no momento.', style: TextStyle(color: AppColors.gray)))
        else
          ...avisos.map((a) => _avisoCard(context, state, alunoId, a)),
        const SizedBox(height: 20),
        const SectionTitle(icon: '📅', title: 'Próximos eventos'),
        if (eventos.isEmpty)
          const PulguinhaCard(child: Text('Nenhum evento próximo.', style: TextStyle(color: AppColors.gray)))
        else
          ...eventos.map((e) => _eventoCard(context, state, alunoId, e)),
      ],
    );
  }

  Widget _itemCard(BuildContext context, AppState state, int alunoId, dynamic item) {
    if (item is Aviso) return _avisoCard(context, state, alunoId, item, destaque: true);
    return _eventoCard(context, state, alunoId, item as EventoEstudio, destaque: true);
  }

  Widget _avisoCard(BuildContext context, AppState state, int alunoId, Aviso a, {bool destaque = false}) {
    final lido = state.comunicacaoLida('aviso', a.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => state.marcarComunicacaoLida(alunoId, 'aviso', a.id),
        borderRadius: BorderRadius.circular(14),
        child: PulguinhaCard(
          borderColor: destaque ? AppColors.neon.withValues(alpha: 0.4) : (lido ? AppColors.border : AppColors.neon.withValues(alpha: 0.2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white))),
                  if (!lido) const PulguinhaBadge(label: 'Novo', variant: BadgeVariant.neon),
                  if (a.fixado) const PulguinhaBadge(label: 'Fixado', variant: BadgeVariant.yellow),
                ],
              ),
              const SizedBox(height: 8),
              MentionText(text: a.texto),
              const SizedBox(height: 6),
              Text(DateHelper.formatarDataHora(a.dataHora), style: const TextStyle(fontSize: 10, color: AppColors.gray)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventoCard(BuildContext context, AppState state, int alunoId, EventoEstudio e, {bool destaque = false}) {
    final lido = state.comunicacaoLida('evento', e.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => state.marcarComunicacaoLida(alunoId, 'evento', e.id),
        borderRadius: BorderRadius.circular(14),
        child: PulguinhaCard(
          borderColor: destaque ? AppColors.neon.withValues(alpha: 0.4) : AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white))),
                  if (!lido) const PulguinhaBadge(label: 'Novo', variant: BadgeVariant.neon),
                ],
              ),
              const SizedBox(height: 4),
              Text(DateHelper.formatarDataHora(e.dataInicio), style: const TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w700)),
              if (e.local != null && e.local!.isNotEmpty) Text(e.local!, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
              if (e.descricao.isNotEmpty) ...[
                const SizedBox(height: 6),
                MentionText(text: e.descricao),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
