import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/date_field.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminDesafiosScreen extends StatelessWidget {
  const AdminDesafiosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('Desafios & Gamificação', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.neon), onPressed: () => _abrirForm(context, state)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          const PulguinhaCard(
            child: Text(
              'Crie desafios de check-in, streak ou hidratação. Alunos ganham Pulguinha Points ao concluir.',
              style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          ...state.desafios.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PulguinhaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_iconeTipo(d.tipo), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(d.titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white))),
                          PulguinhaBadge(label: d.ativo && d.vigente ? 'Ativo' : 'Inativo', variant: d.ativo ? BadgeVariant.neon : BadgeVariant.gray),
                        ],
                      ),
                      Text(d.descricao, style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.35)),
                      const SizedBox(height: 6),
                      Text('Meta: ${d.meta} · +${d.pontosRecompensa} pts · ${DateHelper.formatarData(d.dataInicio)}${d.dataFim != null ? ' → ${DateHelper.formatarData(d.dataFim!)}' : ''}',
                          style: const TextStyle(fontSize: 10, color: AppColors.grayDim)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GhostButton(label: 'Editar', onPressed: () => _abrirForm(context, state, editando: d)),
                          const SizedBox(width: 8),
                          GhostButton(label: 'Excluir', onPressed: () => state.removerDesafio(d.id)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.bg,
        onPressed: () => _abrirForm(context, state),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _iconeTipo(TipoDesafio t) => switch (t) {
        TipoDesafio.checkins => '✅',
        TipoDesafio.streak => '🔥',
        TipoDesafio.agua => '💧',
      };

  void _abrirForm(BuildContext context, AppState state, {Desafio? editando}) {
    final tituloCtrl = TextEditingController(text: editando?.titulo ?? '');
    final descCtrl = TextEditingController(text: editando?.descricao ?? '');
    final metaCtrl = TextEditingController(text: '${editando?.meta ?? 3}');
    final ptsCtrl = TextEditingController(text: '${editando?.pontosRecompensa ?? 30}');
    final inicioCtrl = TextEditingController(text: editando != null ? DateHelper.formatarData(editando.dataInicio) : DateHelper.formatarData(MockData.today));
    final fimCtrl = TextEditingController(text: editando?.dataFim != null ? DateHelper.formatarData(editando!.dataFim!) : '');
    var tipo = editando?.tipo ?? TipoDesafio.checkins;
    var inicioIso = editando?.dataInicio ?? MockData.today;
    String? fimIso = editando?.dataFim;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(editando == null ? 'Novo desafio' : 'Editar desafio', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.white)),
                const SizedBox(height: 12),
                FieldLabel(label: 'Título', child: TextField(controller: tituloCtrl)),
                FieldLabel(label: 'Descrição', child: TextField(controller: descCtrl, maxLines: 2)),
                FieldLabel(
                  label: 'Tipo',
                  child: DropdownButtonFormField<TipoDesafio>(
                    value: tipo,
                    dropdownColor: AppColors.card2,
                    items: const [
                      DropdownMenuItem(value: TipoDesafio.checkins, child: Text('Check-ins')),
                      DropdownMenuItem(value: TipoDesafio.streak, child: Text('Streak de presença')),
                      DropdownMenuItem(value: TipoDesafio.agua, child: Text('Meta de água (copos/dia)')),
                    ],
                    onChanged: (v) => setLocal(() => tipo = v ?? TipoDesafio.checkins),
                  ),
                ),
                FieldLabel(label: 'Meta', child: TextField(controller: metaCtrl, keyboardType: TextInputType.number)),
                FieldLabel(label: 'Pontos de recompensa', child: TextField(controller: ptsCtrl, keyboardType: TextInputType.number)),
                FieldLabel(label: 'Início', child: DateField(controller: inicioCtrl, onChanged: (v) => inicioIso = v)),
                FieldLabel(label: 'Fim (opcional)', child: DateField(controller: fimCtrl, onChanged: (v) => fimIso = v.isEmpty ? null : v)),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Salvar',
                  fullWidth: true,
                  onPressed: () {
                    final d = Desafio(
                      id: editando?.id ?? DateTime.now().millisecondsSinceEpoch,
                      titulo: tituloCtrl.text.trim(),
                      descricao: descCtrl.text.trim(),
                      tipo: tipo,
                      meta: int.tryParse(metaCtrl.text) ?? 3,
                      pontosRecompensa: int.tryParse(ptsCtrl.text) ?? 30,
                      dataInicio: inicioIso,
                      dataFim: fimIso,
                      ativo: editando?.ativo ?? true,
                    );
                    if (d.titulo.isEmpty) return;
                    state.salvarDesafio(d);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
