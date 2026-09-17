import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/services/notifications/notification_payload.dart';
import 'package:pulguinha/services/notifications/notification_tap_handler.dart';

Aluno _aluno({
  required String status,
  String plano = 'Mensal',
  String? beneficioOrigem,
  String? wellhubId,
  String? totalpassCpf,
}) {
  return Aluno(
    id: 1,
    nome: 'Teste',
    email: 't@t.com',
    senha: '1234',
    telefone: '1',
    plano: plano,
    vencimento: '2099-12-31',
    status: status,
    avatar: 'T',
    beneficioOrigem: beneficioOrigem,
    wellhubId: wellhubId,
    totalpassCpf: totalpassCpf,
  );
}

void main() {
  group('passaFiltroAdmin Pendente', () {
    test('mensalista pendente aparece em Pendente e Todos', () {
      final a = _aluno(status: 'Pendente');
      expect(a.passaFiltroAdmin('Pendente'), isTrue);
      expect(a.passaFiltroAdmin('Todos'), isTrue);
      expect(a.passaFiltroAdmin('Mensalistas'), isTrue);
      expect(a.passaFiltroAdmin('Ativo'), isFalse);
      expect(a.passaFiltroAdmin('Parceiros'), isFalse);
    });

    test('GymPass/Wellhub pendente aparece em Pendente (não só em Todos)', () {
      final a = _aluno(status: 'Pendente', plano: 'GymPass', beneficioOrigem: 'wellhub', wellhubId: '1234567890123');
      expect(a.ehSemMensalidade, isTrue);
      expect(a.pagaMensalidade, isFalse);
      expect(a.passaFiltroAdmin('Pendente'), isTrue);
      expect(a.passaFiltroAdmin('Todos'), isTrue);
      expect(a.passaFiltroAdmin('Parceiros'), isTrue);
      expect(a.passaFiltroAdmin('Mensalistas'), isFalse);
      expect(a.passaFiltroAdmin('Ativo'), isFalse);
    });

    test('TotalPass e Avulso pendentes também entram em Pendente', () {
      final tp = _aluno(status: 'Pendente', plano: 'TotalPass', beneficioOrigem: 'totalpass', totalpassCpf: '12345678901');
      final av = _aluno(status: 'Pendente', plano: 'Avulso', beneficioOrigem: 'avulso');
      expect(tp.passaFiltroAdmin('Pendente'), isTrue);
      expect(av.passaFiltroAdmin('Pendente'), isTrue);
    });

    test('status com trim/caixa diferente continua Pendente', () {
      expect(_aluno(status: ' pendente ').estaPendente, isTrue);
      expect(_aluno(status: 'PENDENTE').passaFiltroAdmin('Pendente'), isTrue);
    });

    test('Ativo parceiro fica na aba Parceiros, não em Ativo', () {
      final a = _aluno(status: 'Ativo', beneficioOrigem: 'wellhub', wellhubId: '1234567890123');
      expect(a.passaFiltroAdmin('Ativo'), isFalse);
      expect(a.passaFiltroAdmin('Parceiros'), isTrue);
    });
  });

  group('NotificationPayload cadastro', () {
    test('decode do payload local', () {
      const payload = NotificationPayload(type: NotificationPayloadType.cadastro);
      expect(NotificationPayload.decode(payload.encode())?.type, NotificationPayloadType.cadastro);
    });

    test('fromFcmData aceita type=cadastro', () {
      final p = NotificationPayload.fromFcmData({'type': 'cadastro'});
      expect(p?.type, NotificationPayloadType.cadastro);
    });
  });

  group('NotificationTapHandler', () {
    tearDown(NotificationTapHandler.instance.unbind);

    test('retém payload até bind e entrega ao listener', () {
      NotificationPayload? recebido;
      NotificationTapHandler.instance.handle(
        const NotificationPayload(type: NotificationPayloadType.cadastro),
      );
      NotificationTapHandler.instance.bind((p) => recebido = p);
      expect(recebido?.type, NotificationPayloadType.cadastro);
    });
  });
}
