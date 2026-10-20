import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/utils/horario_helper.dart';

void main() {
  group('HorarioHelper.ocorreNoDia', () {
    test('Seg/Qua/Sex só nos dias certos', () {
      // 2026-08-10 = segunda, 11=ter, 12=qua
      expect(HorarioHelper.ocorreNoDia('Seg/Qua/Sex', '2026-08-10'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Seg/Qua/Sex', '2026-08-11'), isFalse);
      expect(HorarioHelper.ocorreNoDia('Seg/Qua/Sex', '2026-08-12'), isTrue);
    });

    test('Seg a Sex cobre segunda a sexta', () {
      expect(HorarioHelper.ocorreNoDia('Seg a Sex', '2026-08-10'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Seg a Sex', '2026-08-14'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Seg a Sex', '2026-08-15'), isFalse);
      expect(HorarioHelper.ocorreNoDia('Seg a Sex', '2026-08-16'), isFalse);
    });

    test('Ter/Qui', () {
      expect(HorarioHelper.ocorreNoDia('Ter/Qui', '2026-08-11'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Ter/Qui', '2026-08-13'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Ter/Qui', '2026-08-10'), isFalse);
    });

    test('Segunda a Sexta não inclui sábado nem domingo', () {
      expect(HorarioHelper.weekdaysFromDias('Segunda a Sexta'), {1, 2, 3, 4, 5});
      expect(HorarioHelper.weekdaysFromDias('Segunda a Sexta-feira'), {1, 2, 3, 4, 5});
      expect(HorarioHelper.ocorreNoDia('Segunda a sexta-feira!', '2026-08-15'), isFalse);
      expect(HorarioHelper.ocorreNoDia('Segunda a sexta-feira!', '2026-08-16'), isFalse);
      expect(HorarioHelper.ocorreNoDia('Segunda a Sexta-feira', '2026-08-14'), isTrue);
    });

    test('sábado e domingo só quando o texto marca esses dias', () {
      expect(HorarioHelper.weekdaysFromDias('Domingo'), {7});
      expect(HorarioHelper.weekdaysFromDias('Dom'), {7});
      expect(HorarioHelper.weekdaysFromDias('Sábado'), {6});
      expect(HorarioHelper.weekdaysFromDias('Sáb'), {6});
      expect(HorarioHelper.weekdaysFromDias('Sáb e Dom'), {6, 7});
      expect(HorarioHelper.weekdaysFromDias('Seg a Sáb'), {1, 2, 3, 4, 5, 6});
      expect(HorarioHelper.ocorreNoDia('Seg a Sáb', '2026-08-15'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Seg a Sáb', '2026-08-16'), isFalse);
      expect(HorarioHelper.weekdaysFromDias('Seg a Dom'), {1, 2, 3, 4, 5, 6, 7});
      expect(HorarioHelper.weekdaysFromDias('Todos os dias'), {1, 2, 3, 4, 5, 6, 7});
      expect(HorarioHelper.weekdaysFromDias('Seg, Sáb e Dom'), {1, 6, 7});
      expect(HorarioHelper.ocorreNoDia('Dom', '2026-08-16'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Dom', '2026-08-15'), isFalse);
      expect(HorarioHelper.ocorreNoDia('Sáb', '2026-08-15'), isTrue);
      expect(HorarioHelper.ocorreNoDia('Sáb', '2026-08-10'), isFalse);
    });
  });

  group('HorarioHelper.formatDias', () {
    test('grava texto que o parser entende de volta', () {
      expect(HorarioHelper.formatDias({1, 2, 3, 4, 5}), 'Seg a Sex');
      expect(HorarioHelper.formatDias({1, 2, 3, 4, 5, 6}), 'Seg a Sáb');
      expect(HorarioHelper.formatDias({1, 2, 3, 4, 5, 6, 7}), 'Todos os dias');
      expect(HorarioHelper.formatDias({6, 7}), 'Sáb e Dom');
      expect(HorarioHelper.formatDias({7}), 'Dom');
      expect(HorarioHelper.formatDias({1, 3, 7}), 'Seg/Qua/Dom');
      for (final raw in ['Seg a Sex', 'Seg a Sáb', 'Todos os dias', 'Sáb e Dom', 'Dom', 'Seg/Qua/Dom']) {
        expect(HorarioHelper.formatDias(HorarioHelper.weekdaysFromDias(raw)), raw);
      }
    });
  });
}
