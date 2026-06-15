import 'package:shared_preferences/shared_preferences.dart';

class FinanceSettingsStorage {
  FinanceSettingsStorage._();
  static final instance = FinanceSettingsStorage._();

  static const diaVencimentoKey = 'finance_dia_vencimento_padrao';
  static const defaultDiaVencimento = 10;

  Future<int> loadDiaVencimento() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(diaVencimentoKey) ?? defaultDiaVencimento;
  }

  Future<void> saveDiaVencimento(int dia) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(diaVencimentoKey, dia.clamp(1, 28));
  }
}
