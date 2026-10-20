import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/horario_helper.dart';
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
    await showPulguinhaModal(
      context: context,
      title: editando == null ? 'Novo Horário' : 'Editar Horário',
      child: _HorarioForm(
        editando: editando,
        onCancel: () => Navigator.pop(context),
        onSave: (dados) {
          state.salvarHorario(editando: editando, dados: dados);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _HorarioForm extends StatefulWidget {
  const _HorarioForm({required this.onSave, required this.onCancel, this.editando});

  final Horario? editando;
  final VoidCallback onCancel;
  final ValueChanged<Horario> onSave;

  @override
  State<_HorarioForm> createState() => _HorarioFormState();
}

class _HorarioFormState extends State<_HorarioForm> {
  static const _chips = <(int, String)>[
    (1, 'Seg'),
    (2, 'Ter'),
    (3, 'Qua'),
    (4, 'Qui'),
    (5, 'Sex'),
    (6, 'Sáb'),
    (7, 'Dom'),
  ];

  late final TextEditingController _horaCtrl;
  late final TextEditingController _capCtrl;
  late Set<int> _dias;

  @override
  void initState() {
    super.initState();
    final editando = widget.editando;
    _horaCtrl = TextEditingController(text: editando?.hora ?? '');
    _capCtrl = TextEditingController(text: '${editando?.capacidade ?? 12}');
    if (editando == null || editando.dias.trim().isEmpty) {
      _dias = {1, 2, 3, 4, 5, 6};
    } else {
      _dias = HorarioHelper.weekdaysFromDias(editando.dias);
    }
  }

  @override
  void dispose() {
    _horaCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  bool _mesmosDias(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);

  String _textoDias() {
    final original = widget.editando?.dias ?? '';
    if (widget.editando != null && original.trim().isNotEmpty && _mesmosDias(_dias, HorarioHelper.weekdaysFromDias(original))) {
      return original;
    }
    return HorarioHelper.formatDias(_dias);
  }

  void _salvar() {
    if (_horaCtrl.text.trim().isEmpty || _dias.isEmpty) return;
    final cap = int.tryParse(_capCtrl.text.trim()) ?? 12;
    widget.onSave(Horario(
      id: widget.editando?.id ?? 0,
      hora: _horaCtrl.text.trim(),
      dias: _textoDias(),
      capacidade: cap.clamp(1, 50),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final preview = _dias.isEmpty ? 'Marque ao menos um dia.' : _textoDias();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: 'Horário', child: TextField(controller: _horaCtrl, decoration: const InputDecoration(hintText: '06:00'))),
        const Text('Dias da aula', style: TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        const SizedBox(height: 6),
        const Text(
          'Sábado e domingo só entram na agenda se estiverem marcados.',
          style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.35, decoration: TextDecoration.none),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in _chips)
              ChoiceChip(
                label: Text(chip.$2),
                selected: _dias.contains(chip.$1),
                onSelected: (sel) {
                  setState(() {
                    final next = Set<int>.from(_dias);
                    if (sel) {
                      next.add(chip.$1);
                    } else {
                      next.remove(chip.$1);
                    }
                    _dias = next;
                  });
                },
                selectedColor: AppColors.neon,
                backgroundColor: AppColors.card2,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: _dias.contains(chip.$1) ? const Color(0xFF111111) : AppColors.gray,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(preview, style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        const SizedBox(height: 10),
        FieldLabel(label: 'Vagas (capacidade)', child: TextField(controller: _capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '12'))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: GhostButton(label: 'Cancelar', onPressed: widget.onCancel)),
            const SizedBox(width: 10),
            Expanded(child: NeonButton(label: 'Salvar', onPressed: _salvar)),
          ],
        ),
      ],
    );
  }
}
