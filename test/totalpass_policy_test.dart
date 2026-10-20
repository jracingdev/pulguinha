import 'package:flutter_test/flutter_test.dart';
import 'package:pulguinha/utils/totalpass_policy.dart';

void main() {
  group('TotalpassPolicy.tpWeekday', () {
    test('domingo ISO 7 vira 0 na TotalPass', () {
      expect(TotalpassPolicy.tpWeekday(7), 0);
      expect(TotalpassPolicy.tpWeekday(1), 1);
      expect(TotalpassPolicy.tpWeekday(6), 6);
    });
  });

  group('TotalpassPolicy.decidePublish', () {
    test('J Racing publica aula de teste, não a grade real', () {
      expect(TotalpassPolicy.decidePublish(66691), TotalpassPublishMode.portalTest);
      expect(TotalpassPolicy.decidePublish(TotalpassPolicy.portalTestPlaceId), isNot(TotalpassPublishMode.production));
    });

    test('FUNCIONAL DO PULGUINHA só publica a grade no place 203438', () {
      expect(TotalpassPolicy.decidePublish(203438), TotalpassPublishMode.production);
      expect(TotalpassPolicy.decidePublish(TotalpassPolicy.productionPlaceId), TotalpassPublishMode.production);
    });

    test('outro place ou ausência recusa, sem misturar grade', () {
      expect(TotalpassPolicy.decidePublish(null), TotalpassPublishMode.refuse);
      expect(TotalpassPolicy.decidePublish(0), TotalpassPublishMode.refuse);
      expect(TotalpassPolicy.decidePublish(1), TotalpassPublishMode.refuse);
    });
  });
}
