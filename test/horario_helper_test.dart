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
  });
}
