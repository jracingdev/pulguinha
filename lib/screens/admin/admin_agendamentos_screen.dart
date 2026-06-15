import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminAgendamentosScreen extends StatefulWidget {
  const AdminAgendamentosScreen({super.key});

  @override
  State<AdminAgendamentosScreen> createState() => _AdminAgendamentosScreenState();
}

class _AdminAgendamentosScreenState extends State<AdminAgendamentosScreen> {
  int semana = 0;
  ({String d, int h})? verAula;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().recarregarAgendamentos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dias = DateHelper.diasDaSemana(semana);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AGENDA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
            NeonButton(label: '+ Agendar', onPressed: () => _novoAgendamento(context, state)),
          ],
        ),
        const SizedBox(height: 20),
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
        borderColor: isToday ? AppColors.neon.withValues(alpha: 0.35) : AppColors.border,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
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
                  if (isToday) ...[const Spacer(), const PulguinhaBadge(label: 'HOJE')],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: HorarioGrid(
                spacing: 10,
                children: state.horarios.map((h) {
                  final ags = state.agendamentosPorDataHorario(dia.iso, h.id);
                  final isVer = verAula?.d == dia.iso && verAula?.h == h.id;
                  return Column(
                    children: [
                      HorarioSlotCard(
                        hora: h.hora,
                        ocupados: ags.length,
                        capacidade: h.capacidade,
                        selected: isVer,
                        enabled: ags.isNotEmpty,
                        onTap: ags.isEmpty ? null : () => setState(() => verAula = isVer ? null : (d: dia.iso, h: h.id)),
                      ),
                      if (isVer)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            border: Border.all(color: AppColors.neon.withValues(alpha: 0.15)),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                          ),
                          child: Column(
                            children: ags.map((ag) {
                              final aluno = state.alunoPorId(ag.alunoId);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    PulguinhaAvatar(initials: aluno?.avatar ?? ag.nomeAluno.substring(0, 2).toUpperCase(), size: AvatarSize.sm),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(ag.nomeAluno.split(' ').first, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white))),
                                    TextButton(
                                      onPressed: () => _cancelar(context, state, ag.id),
                                      child: const Text('Cancelar', style: TextStyle(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _novoAgendamento(BuildContext context, AppState state) async {
    var data = MockData.today;
    var alunoId = '';
    var horarioId = '';

    await showPulguinhaModal(
      context: context,
      title: 'Novo Agendamento',
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
                child: const Text('⏰ Cancelamentos: entre 24h e 1h antes', style: TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w600)),
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
                label: 'Aluno *',
                child: DropdownButtonFormField<String>(
                  value: alunoId.isEmpty ? null : alunoId,
                  hint: const Text('Selecione...'),
                  items: state.alunos.where((a) => a.status == 'Ativo').map((a) => DropdownMenuItem(value: '${a.id}', child: Text(a.nome))).toList(),
                  onChanged: (v) => setModal(() => alunoId = v ?? ''),
                ),
              ),
              FieldLabel(
                label: 'Horário *',
                child: DropdownButtonFormField<String>(
                  value: horarioId.isEmpty ? null : horarioId,
                  hint: const Text('Selecione...'),
                  items: state.horarios.map((h) {
                    final v = state.agendamentosPorDataHorario(data, h.id);
                    final lotado = v.length >= h.capacidade;
                    return DropdownMenuItem(
                      value: '${h.id}',
                      enabled: !lotado,
                      child: Text('${h.hora} — ${h.dias} (${v.length}/${h.capacidade})${lotado ? " LOTADO" : ""}'),
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
                      label: 'Confirmar',
                      onPressed: () {
                        if (alunoId.isEmpty || horarioId.isEmpty) return;
                        final aluno = state.alunos.firstWhere((a) => a.id == int.parse(alunoId));
                        final h = state.horarios.firstWhere((x) => x.id == int.parse(horarioId));
                        if (state.aulaLotada(data, h.id)) return;
                        state.criarAgendamento(alunoId: aluno.id, nomeAluno: aluno.nome, horarioId: h.id, data: data, horario: h.hora);
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
        title: const Text('Cancelar agendamento?', style: TextStyle(color: AppColors.white)),
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
