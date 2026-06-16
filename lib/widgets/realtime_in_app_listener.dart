import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/in_app_notifier.dart';

/// Exibe banner in-app quando novos dados chegam via realtime, sem trocar de tela.
class RealtimeInAppListener extends StatefulWidget {
  const RealtimeInAppListener({super.key, required this.child});

  final Widget child;

  @override
  State<RealtimeInAppListener> createState() => _RealtimeInAppListenerState();
}

class _RealtimeInAppListenerState extends State<RealtimeInAppListener> {
  bool _ready = false;
  int _avisosCount = 0;
  int _eventosCount = 0;
  int _postsCount = 0;
  int _agendamentosCount = 0;
  int _alunosPendentes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      _snapshot(state);
      state.addListener(_onStateChanged);
      _ready = true;
    });
  }

  @override
  void dispose() {
    context.read<AppState>().removeListener(_onStateChanged);
    super.dispose();
  }

  void _snapshot(AppState state) {
    _avisosCount = state.avisos.length;
    _eventosCount = state.eventos.length;
    _postsCount = state.postsTurma.length;
    _agendamentosCount = state.agendamentos.length;
    _alunosPendentes = state.alunos.where((a) => a.status == 'Pendente').length;
  }

  void _onStateChanged() {
    if (!_ready || !mounted) return;
    final state = context.read<AppState>();

    if (state.avisos.length > _avisosCount) {
      final novo = state.avisos.first;
      InAppNotifier.show(
        context,
        title: 'Novo aviso',
        message: novo.titulo,
        color: AppColors.neon,
      );
    }
    if (state.eventos.length > _eventosCount) {
      final novo = state.eventos.last;
      InAppNotifier.show(
        context,
        title: 'Novo evento',
        message: novo.titulo,
        color: AppColors.blue,
      );
    }
    if (state.postsTurma.length > _postsCount) {
      final novo = state.postsTurma.first;
      InAppNotifier.show(
        context,
        title: 'Nova publicação na turma',
        message: novo.nomeAluno,
        color: AppColors.neon,
      );
    }
    if (state.agendamentos.length > _agendamentosCount) {
      final novo = state.agendamentos.last;
      InAppNotifier.show(
        context,
        title: 'Novo agendamento',
        message: '${novo.nomeAluno} · ${novo.horario}',
        color: AppColors.yellow,
      );
    }
    final pendentes = state.alunos.where((a) => a.status == 'Pendente').length;
    if (state.usuario?.isAdmin == true && pendentes > _alunosPendentes) {
      InAppNotifier.show(
        context,
        title: 'Cadastro pendente',
        message: '$pendentes aluno(s) aguardando aprovação',
        color: AppColors.yellow,
      );
    }

    _snapshot(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
