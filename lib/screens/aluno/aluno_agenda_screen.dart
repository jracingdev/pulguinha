import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/agendamento_rules.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/horario_helper.dart';
import 'package:pulguinha/widgets/date_field.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AlunoAgendaScreen extends StatefulWidget {
  const AlunoAgendaScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<AlunoAgendaScreen> createState() => _AlunoAgendaScreenState();
}

class _AlunoAgendaScreenState extends State<AlunoAgendaScreen> {
  int semana = 0;
  bool _agendando = false;

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
            NeonButton(label: '+ Agendar', onPressed: _agendando ? null : () => _modalAgendar(context, state, aluno)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neon.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.neon.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Você só pode agendar entre 24 horas e 1 hora antes do horário do treino. Só aparecem aulas do dia da semana correspondente.',
            style: TextStyle(fontSize: 11, color: AppColors.neon, height: 1.4, fontWeight: FontWeight.w600),
          ),
        ),
        if (aluno.horarioId != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neon.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.neon.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Sua turma principal é ${state.labelTurma(aluno)} — para controle e mural. Você pode agendar qualquer horário com vaga disponível na janela permitida.',
              style: const TextStyle(fontSize: 11, color: AppColors.neon, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
    final slotsDoDia = state.horariosOrdenados.where((h) => HorarioHelper.ocorreNoDia(h.dias, dia.iso)).toList();

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
            if (slotsDoDia.isEmpty)
              const Text(
                'Sem aulas neste dia da semana.',
                style: TextStyle(fontSize: 12, color: AppColors.grayDim),
              )
            else
              HorarioGrid(
                children: slotsDoDia.map((h) {
                  final ags = state.agendamentosPorDataHorario(dia.iso, h.id);
                  final lotado = ags.length >= h.capacidade;
                  final eu = state.agendamentos.where((ag) => ag.alunoId == aluno.id && ag.data == dia.iso && ag.horarioId == h.id).firstOrNull;
                  final turmaPrincipal = aluno.horarioId == h.id;
                  final naJanela = AgendamentoRules.podeAgendar(dia.iso, h.hora);
                  final podeEntrar = !_agendando && eu == null && !lotado && naJanela;
                  return HorarioSlotCard(
                    hora: h.hora,
                    ocupados: ags.length,
                    capacidade: h.capacidade,
                    subtitle: turmaPrincipal ? 'Sua turma principal' : h.dias,
                    selected: eu != null,
                    enabled: eu != null || podeEntrar,
                    onTap: podeEntrar ? () => _agendarDireto(state, aluno, dia.iso, h) : null,
                    footer: eu != null
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _agendando ? null : () => _cancelar(context, state, eu.id),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Cancelar', style: TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w700)),
                            ),
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _footerSlot(lotado: lotado, naJanela: naJanela, data: dia.iso, hora: h.hora),
                              style: TextStyle(
                                fontSize: 10,
                                color: podeEntrar ? AppColors.neon : AppColors.grayDim,
                                fontWeight: FontWeight.w700,
                              ),
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

  String _footerSlot({required bool lotado, required bool naJanela, required String data, required String hora}) {
    if (lotado) return 'Lotada';
    if (naJanela) return 'Toque para entrar';
    final inicio = AgendamentoRules.inicioAula(data, hora);
    final now = DateTime.now();
    if (now.isAfter(inicio.subtract(AgendamentoRules.antecedenciaMinima))) {
      return 'Encerrado';
    }
    final abre = inicio.subtract(AgendamentoRules.antecedenciaMaxima);
    final horas = abre.difference(now).inHours;
    if (horas >= 1) return 'Abre em ~${horas}h';
    final mins = abre.difference(now).inMinutes;
    if (mins > 0) return 'Abre em ${mins}min';
    return 'Abre em breve';
  }

  Future<void> _agendarDireto(AppState state, Aluno aluno, String data, Horario h) async {
    if (_agendando) return;
    setState(() => _agendando = true);
    final result = await state.criarAgendamento(
      alunoId: aluno.id,
      nomeAluno: aluno.nome,
      horarioId: h.id,
      data: data,
      horario: h.hora,
    );
    if (!mounted) return;
    setState(() => _agendando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.mensagem ?? (result.ok ? 'Agendamento confirmado!' : 'Não foi possível agendar.'))),
    );
  }

  Future<void> _modalAgendar(BuildContext context, AppState state, Aluno aluno) async {
    var data = MockData.today;
    var horarioId = '';
    final dataCtrl = TextEditingController(text: DateHelper.formatarData(data));
    final now = DateTime.now();

    await showPulguinhaModal(
      context: context,
      title: 'Confirmar Agendamento',
      child: StatefulBuilder(
        builder: (ctx, setModal) {
          final horariosDia = state.horariosOrdenados.where((h) => HorarioHelper.ocorreNoDia(h.dias, data)).toList();
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
                child: const Text(
                  '⏰ Agende apenas entre 24h e 1h antes do treino',
                  style: TextStyle(fontSize: 12, color: AppColors.neon),
                ),
              ),
              const SizedBox(height: 14),
              FieldLabel(
                label: 'Data',
                child: DateField(
                  controller: dataCtrl,
                  firstDate: now,
                  lastDate: now.add(AgendamentoRules.antecedenciaMaxima),
                  onChanged: (iso) => setModal(() {
                    data = iso;
                    horarioId = '';
                  }),
                ),
              ),
              FieldLabel(
                label: 'Horário',
                child: DropdownButtonFormField<String>(
                  value: horarioId.isEmpty ? null : horarioId,
                  hint: Text(horariosDia.isEmpty ? 'Sem aulas neste dia' : 'Selecione...'),
                  items: horariosDia.map((h) {
                    final v = state.agendamentosPorDataHorario(data, h.id);
                    final lotado = v.length >= h.capacidade;
                    final naJanela = AgendamentoRules.podeAgendar(data, h.hora);
                    final disponivel = !lotado && naJanela;
                    final sufixo = lotado
                        ? ' LOTADO'
                        : (!naJanela ? ' FORA DA JANELA' : '');
                    return DropdownMenuItem(
                      value: '${h.id}',
                      enabled: disponivel,
                      child: Text('${h.hora} · ${h.dias} (${v.length}/${h.capacidade})$sufixo'),
                    );
                  }).toList(),
                  onChanged: horariosDia.isEmpty ? null : (v) => setModal(() => horarioId = v ?? ''),
                ),
              ),
              Row(
                children: [
                  Expanded(child: GhostButton(label: 'Cancelar', onPressed: () => Navigator.pop(ctx))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: _agendando ? 'Salvando...' : '✅ Confirmar',
                      onPressed: _agendando || horarioId.isEmpty
                          ? null
                          : () async {
                              final h = state.horariosOrdenados.firstWhere((x) => x.id == int.parse(horarioId));
                              Navigator.pop(ctx);
                              await _agendarDireto(state, aluno, data, h);
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
    dataCtrl.dispose();
  }

  Future<void> _cancelar(BuildContext context, AppState state, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cancelar este agendamento?', style: TextStyle(color: AppColors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _agendando = true);
    final result = await state.cancelarAgendamento(id);
    if (!mounted) return;
    setState(() => _agendando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.mensagem ?? (result.ok ? 'Cancelado.' : 'Falha ao cancelar.'))),
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
