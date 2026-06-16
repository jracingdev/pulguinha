import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/admin_page_layout.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminHorariosScreen extends StatelessWidget {
  const AdminHorariosScreen({super.key, this.standalone = true});

  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final content = state.horariosOrdenados.map((h) => _horarioCard(context, state, h)).toList();

    if (standalone) {
      return AdminStandalonePage(
        title: 'Horários',
        subtitle: 'Configure turmas, dias e vagas por horário.',
        actionLabel: '+ Novo',
        onAction: () => _abrirModal(context, state),
        children: content,
      );
    }

    return AdminTabPage(
      title: 'HORÁRIOS',
      subtitle: 'Configure turmas, dias e vagas por horário.',
      actionLabel: '+ Novo',
      onAction: () => _abrirModal(context, state),
      children: content,
    );
  }

  Widget _horarioCard(BuildContext context, AppState state, Horario h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.neon.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.neon.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(h.hora, style: const TextStyle(color: AppColors.neon, fontWeight: FontWeight.w900, fontSize: 13, decoration: TextDecoration.none)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.dias, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white, decoration: TextDecoration.none)),
                  Text('Capacidade: ${h.capacidade} vagas', style: const TextStyle(fontSize: 11, color: AppColors.gray, decoration: TextDecoration.none)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _abrirModal(context, state, editando: h),
              icon: const Text('✏️'),
              style: IconButton.styleFrom(backgroundColor: AppColors.neon.withValues(alpha: 0.1)),
            ),
            IconButton(
              onPressed: () => _confirmarExclusao(context, state, h),
              icon: const Text('🗑️'),
              style: IconButton.styleFrom(backgroundColor: AppColors.red.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, AppState state, Horario h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir horário?', style: TextStyle(color: AppColors.white)),
        content: Text('Remover ${h.hora} (${h.dias})?', style: const TextStyle(color: AppColors.gray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true) state.removerHorario(h.id);
  }

  Future<void> _abrirModal(BuildContext context, AppState state, {Horario? editando}) async {
    final horaCtrl = TextEditingController(text: editando?.hora ?? '');
    final diasCtrl = TextEditingController(text: editando?.dias ?? '');
    final capCtrl = TextEditingController(text: '${editando?.capacidade ?? 12}');

    await showPulguinhaModal(
      context: context,
      title: editando == null ? 'Novo Horário' : 'Editar Horário',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldLabel(label: 'Horário', child: TextField(controller: horaCtrl, decoration: const InputDecoration(hintText: '06:00'))),
          FieldLabel(label: 'Dias', child: TextField(controller: diasCtrl, decoration: const InputDecoration(hintText: 'Seg/Qua/Sex'))),
          FieldLabel(label: 'Vagas (capacidade)', child: TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '12'))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: GhostButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 10),
              Expanded(
                child: NeonButton(
                  label: 'Salvar',
                  onPressed: () {
                    if (horaCtrl.text.trim().isEmpty || diasCtrl.text.trim().isEmpty) return;
                    final cap = int.tryParse(capCtrl.text.trim()) ?? 12;
                    final dados = Horario(
                      id: editando?.id ?? 0,
                      hora: horaCtrl.text.trim(),
                      dias: diasCtrl.text.trim(),
                      capacidade: cap.clamp(1, 50),
                    );
                    state.salvarHorario(editando: editando, dados: dados);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
