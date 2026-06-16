import 'package:pulguinha/models/models.dart';

import 'package:pulguinha/services/notifications/notification_payload.dart';

import 'package:pulguinha/services/notifications/notification_service.dart';

import 'package:pulguinha/services/notifications/notification_settings_storage.dart';

import 'package:pulguinha/utils/date_helper.dart';

import 'package:pulguinha/utils/vencimento_helper.dart';



class NotificationScheduler {

  NotificationScheduler._();

  static final instance = NotificationScheduler._();



  NotificationSettings _settings = const NotificationSettings();

  int _diasParaInadimplencia = 7;



  Future<void> loadSettings() async {

    _settings = await NotificationSettingsStorage.instance.load();

  }



  Future<void> refreshSettings(NotificationSettings settings) async {

    _settings = settings;

  }



  void setDiasParaInadimplencia(int dias) {

    _diasParaInadimplencia = dias.clamp(1, 60);

  }



  bool get _on => _settings.enabled;



  int _idAula(int agId) => 10000 + agId;

  int _idVenc(int alunoId, int offset) => 20000 + alunoId * 1000 + offset;

  int _idEvento(int eventoId) => 30000 + eventoId;



  Future<void> rescheduleAll({

    required List<Agendamento> agendamentos,

    required List<Aluno> alunos,

    required List<Horario> horarios,

    int? alunoLogadoId,

    bool isAdmin = false,

    int diasParaInadimplencia = 7,

  }) async {

    _diasParaInadimplencia = diasParaInadimplencia;

    if (!_on) return;

    await NotificationService.instance.cancelAll();



    if (_settings.lembreteAula && alunoLogadoId != null) {

      for (final ag in agendamentos.where((a) => a.alunoId == alunoLogadoId)) {

        await _scheduleAula(ag, horarios);

      }

    }



    if (_settings.lembreteVencimento && alunoLogadoId != null) {

      final aluno = alunos.where((a) => a.id == alunoLogadoId).firstOrNull;

      if (aluno != null && VencimentoHelper.temPlanoAtivo(aluno)) {

        await _scheduleVencimento(aluno);

      }

    }



    if (isAdmin) {

      final pendentes = alunos.where((a) => a.status == 'Pendente').length;

      if (pendentes > 0) {

        await NotificationService.instance.showNow(

          id: 9001,

          title: 'Cadastros pendentes',

          body: '$pendentes aluno(s) aguardando aprovação',

          payload: const NotificationPayload(type: NotificationPayloadType.cadastro),

        );

      }

    }

  }



  Future<void> _scheduleAula(Agendamento ag, List<Horario> horarios) async {

    final hor = horarios.where((h) => h.id == ag.horarioId).firstOrNull;

    if (hor == null) return;

    final parts = ag.horario.split(':');

    final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;

    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final base = DateHelper.parseData(ag.data);

    final aula = DateTime(base.year, base.month, base.day, h, m);

    final lembrete = aula.subtract(const Duration(hours: 1));

    if (lembrete.isAfter(DateTime.now())) {

      await NotificationService.instance.schedule(

        id: _idAula(ag.id),

        when: lembrete,

        title: 'Aula em 1 hora',

        body: '${ag.horario} — não esqueça!',

        payload: NotificationPayload(

          type: NotificationPayloadType.aula,

          itemId: ag.id,

          alunoId: ag.alunoId,

        ),

      );

    }

  }



  Future<void> _scheduleVencimento(Aluno aluno) async {

    final dias = DateHelper.diasAteVencimento(aluno.vencimento);

    final venc = DateHelper.parseData(aluno.vencimento);



    // 3 dias antes — às 9h do dia correspondente

    if (dias == 3) {

      final when = DateTime(venc.year, venc.month, venc.day, 9, 0).subtract(const Duration(days: 3));

      if (when.isAfter(DateTime.now())) {

        await NotificationService.instance.schedule(

          id: _idVenc(aluno.id, 1),

          when: when,

          title: 'Mensalidade em 3 dias',

          body: 'Vencimento em ${DateHelper.formatarData(aluno.vencimento)}',

          payload: NotificationPayload(type: NotificationPayloadType.vencimento, alunoId: aluno.id),

        );

      }

    }



    // No dia do vencimento — às 9h

    if (dias == 0) {

      final when = DateTime(venc.year, venc.month, venc.day, 9);

      if (when.isAfter(DateTime.now())) {

        await NotificationService.instance.schedule(

          id: _idVenc(aluno.id, 2),

          when: when,

          title: 'Mensalidade vence hoje',

          body: 'Regularize para manter seu plano ativo',

          payload: NotificationPayload(type: NotificationPayloadType.vencimento, alunoId: aluno.id),

        );

      } else {

        await NotificationService.instance.showNow(

          id: _idVenc(aluno.id, 2),

          title: 'Mensalidade vence hoje',

          body: 'Regularize para manter seu plano ativo',

          payload: NotificationPayload(type: NotificationPayloadType.vencimento, alunoId: aluno.id),

        );

      }

    }



    // Após vencimento — atraso (período de tolerância)
    // Agenda lembretes diários no horário das 09:00 e, se o horário do dia atual já passou,
    // dispara como showNow.
    if (dias < 0) {
      final dueAt9 = DateTime(venc.year, venc.month, venc.day, 9);
      for (int i = 1; i <= _diasParaInadimplencia; i++) {
        final when = dueAt9.add(Duration(days: i));
        final id = _idVenc(aluno.id, 20 + i);
        final body = 'Venceu há $i dia(s) — evite bloqueio do plano';

        if (when.isAfter(DateTime.now())) {
          await NotificationService.instance.schedule(
            id: id,
            when: when,
            title: 'Mensalidade em atraso',
            body: body,
            payload: NotificationPayload(type: NotificationPayloadType.vencimento, alunoId: aluno.id),
          );
        } else if (dias == -i) {
          await NotificationService.instance.showNow(
            id: id,
            title: 'Mensalidade em atraso',
            body: body,
            payload: NotificationPayload(type: NotificationPayloadType.vencimento, alunoId: aluno.id),
          );
        }
      }
    }



    // Inadimplência — após período de tolerância
    final inadAt9 = DateTime(venc.year, venc.month, venc.day, 9).add(Duration(days: _diasParaInadimplencia + 1));
    if (inadAt9.isAfter(DateTime.now())) {
      await NotificationService.instance.schedule(
        id: _idVenc(aluno.id, 999),
        when: inadAt9,
        title: 'Mensalidade inadimplente',
        body: 'Mensalidade vencida há mais de $_diasParaInadimplencia dias — entre em contato com o estúdio',
        payload: NotificationPayload(type: NotificationPayloadType.vencimento, alunoId: aluno.id),
      );
    } else if (dias < -_diasParaInadimplencia || aluno.status == 'Inadimplente') {
      await NotificationService.instance.showNow(
        id: _idVenc(aluno.id, 999),
        title: 'Mensalidade inadimplente',
        body: 'Mensalidade vencida há mais de $_diasParaInadimplencia dias — entre em contato com o estúdio',
        payload: NotificationPayload(type: NotificationPayloadType.vencimento, alunoId: aluno.id),
      );
    }

  }



  Future<void> notifyComunicacao({

    required NotificationPayloadType tipo,

    required String titulo,

    required String corpo,

    required bool notificarTodos,

    required List<int> mencoes,

    List<Aluno>? alunosAtivos,

    int? itemId,

    DateTime? lembreteEvento,

  }) async {

    if (!_on || !_settings.comunicacao) return;

    final svc = NotificationService.instance;

    final baseId = DateTime.now().millisecondsSinceEpoch % 100000;



    if (notificarTodos && alunosAtivos != null) {

      for (var i = 0; i < alunosAtivos.length; i++) {

        final a = alunosAtivos[i];

        await svc.showNow(

          id: baseId + i,

          title: titulo,

          body: corpo,

          payload: NotificationPayload(type: tipo, itemId: itemId, alunoId: a.id),

        );

      }

    } else {

      for (var i = 0; i < mencoes.length; i++) {

        await svc.showNow(

          id: baseId + i,

          title: '@ Você foi mencionado',

          body: '$titulo — $corpo',

          payload: NotificationPayload(type: NotificationPayloadType.mencao, itemId: itemId, alunoId: mencoes[i]),

        );

      }

    }



    if (lembreteEvento != null && itemId != null && lembreteEvento.isAfter(DateTime.now())) {

      await svc.schedule(

        id: _idEvento(itemId),

        when: lembreteEvento,

        title: 'Evento amanhã',

        body: titulo,

        payload: NotificationPayload(type: NotificationPayloadType.evento, itemId: itemId),

      );

    }

  }



  Future<void> notifyPagamento(String nomeAluno, int alunoId) async {

    if (!_on) return;

    await NotificationService.instance.showNow(

      id: 8000 + alunoId,

      title: 'Pagamento confirmado',

      body: nomeAluno,

      payload: NotificationPayload(type: NotificationPayloadType.pagamento, alunoId: alunoId),

    );

  }

}



extension _FirstSched<T> on Iterable<T> {

  T? get firstOrNull {

    final it = iterator;

    if (!it.moveNext()) return null;

    return it.current;

  }

}

