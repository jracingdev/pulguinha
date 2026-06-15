import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AlunoAgendaScreen extends StatefulWidget {
  const AlunoAgendaScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<AlunoAgendaScreen> createState() => _AlunoAgendaScreenState();
}

class _AlunoAgendaScreenState extends State<AlunoAgendaScreen> {
  int semana = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final aluno = state.alunoPorId(widget.usuario.id);
    if (aluno == null) return const SizedBox.shrink();
    final dias = DateHelper.diasDaSemana(semana);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AGENDAMENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.neon, letterSpacing: 2)),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white),
                    children: [
                      TextSpan(text: 'AGENDE SUA '),
                      TextSpan(text: 'AULA', style: TextStyle(color: AppColors.neon)),
                    ],
                  ),
                ),
              ],
            ),
            NeonButton(label: '+ Agendar', onPressed: () => _modalAgendar(context, state, aluno)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: () => setState(() => semana--), icon: const Icon(Icons.chevron_left, color: AppColors.white)),
            Text(DateHelper.labelSemana(dias), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
            IconButton(onPressed: () => setState(() => semana++), icon: const Icon(Icons.chevron_right, color: AppColors.white)),
          ],
        ),
        ...dias.map((dia) => _diaCard(state, aluno, dia)),
      ],
    );
  }

  Widget _diaCard(AppState state, Aluno aluno, DiaSemana dia) {
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: isToday ? AppColors.neon : AppColors.card2, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text('${dia.num}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isToday ? const Color(0xFF111111) : AppColors.gray)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dia.nome, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isToday ? AppColors.neon : AppColors.white)),
                    Text('${dia.num} de ${dia.mes}', style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            HorarioGrid(
              children: state.horarios.map((h) {
                final ags = state.agendamentosPorDataHorario(dia.iso, h.id);
                final lotado = ags.length >= h.capacidade;
                final eu = state.agendamentos.where((ag) => ag.alunoId == aluno.id && ag.data == dia.iso && ag.horarioId == h.id).firstOrNull;
                return HorarioSlotCard(
                  hora: h.hora,
                  ocupados: ags.length,
                  capacidade: h.capacidade,
                  selected: eu != null,
                  enabled: eu != null || !lotado,
                  onTap: eu != null || lotado ? null : () => _agendarDireto(state, aluno, dia.iso, h),
                  footer: eu != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => _cancelar(context, state, eu.id),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Cancelar', style: TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w700)),
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            lotado ? 'Lotada' : 'Toque para entrar',
                            style: TextStyle(fontSize: 10, color: lotado ? AppColors.grayDim : AppColors.neon, fontWeight: FontWeight.w700),
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

  void _agendarDireto(AppState state, Aluno aluno, String data, dynamic h) {
    state.criarAgendamento(alunoId: aluno.id, nomeAluno: aluno.nome, horarioId: h.id, data: data, horario: h.hora);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento confirmado!')));
  }

  Future<void> _modalAgendar(BuildContext context, AppState state, Aluno aluno) async {
    var data = MockData.today;
    var horarioId = '';

    await showPulguinhaModal(
      context: context,
      title: 'Confirmar Agendamento',
      child: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neon.withValues(alpha: 0.06),
                  border: Border.all(color: AppColors.neon.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('⏰ Você pode cancelar até 1h antes da aula', style: TextStyle(fontSize: 12, color: AppColors.neon)),
              ),
              const SizedBox(height: 14),
              FieldLabel(
                label: 'Data',
                child: TextField(
                  decoration: InputDecoration(hintText: DateHelper.formatarData(data)),
                  onChanged: (v) => data = v.trim().isEmpty ? data : DateHelper.paraIso(v),
                ),
              ),
              FieldLabel(
                label: 'Horário',
                child: DropdownButtonFormField<String>(
                  value: horarioId.isEmpty ? null : horarioId,
                  hint: const Text('Selecione...'),
                  items: state.horarios.map((h) {
                    final v = state.agendamentosPorDataHorario(data, h.id);
                    final lotado = v.length >= h.capacidade;
                    return DropdownMenuItem(
                      value: '${h.id}',
                      enabled: !lotado,
                      child: Text('${h.hora} (${v.length}/${h.capacidade})${lotado ? " LOTADO" : ""}'),
                    );
                  }).toList(),
                  onChanged: (v) => setModal(() => horarioId = v ?? ''),
                ),
              ),
              Row(
                children: [
                  Expanded(child: GhostButton(label: 'Cancelar', onPressed: () => Navigator.pop(ctx))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: '✅ Confirmar',
                      onPressed: () {
                        if (horarioId.isEmpty) return;
                        final h = state.horarios.firstWhere((x) => x.id == int.parse(horarioId));
                        _agendarDireto(state, aluno, data, h);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _cancelar(BuildContext context, AppState state, int id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cancelar este agendamento?', style: TextStyle(color: AppColors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Não')),
          TextButton(
            onPressed: () {
              state.cancelarAgendamento(id);
              Navigator.pop(ctx);
            },
            child: const Text('Sim', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
