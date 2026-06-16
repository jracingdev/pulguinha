import 'dart:convert';

import 'package:pulguinha/models/billing_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceSettingsStorage {
  FinanceSettingsStorage._();
  static final instance = FinanceSettingsStorage._();

  static const diaVencimentoKey = 'finance_dia_vencimento_padrao';
  static const diasInadimplenciaKey = 'finance_dias_inadimplencia';
  static const regrasCobrancaKey = 'finance_regras_cobranca';
  static const defaultDiaVencimento = 10;
  static const defaultDiasInadimplencia = 7;

  Future<int> loadDiaVencimento() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(diaVencimentoKey) ?? defaultDiaVencimento;
  }

  Future<void> saveDiaVencimento(int dia) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(diaVencimentoKey, dia.clamp(1, 28));
  }

  Future<int> loadDiasInadimplencia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(diasInadimplenciaKey) ?? defaultDiasInadimplencia;
  }

  Future<void> saveDiasInadimplencia(int dias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(diasInadimplenciaKey, dias.clamp(1, 60));
  }

  Future<List<RegraCobranca>> loadRegrasCobranca() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(regrasCobrancaKey);
    if (raw == null || raw.isEmpty) return RegraCobranca.padrao();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => RegraCobranca.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return RegraCobranca.padrao();
    }
  }

  Future<void> saveRegrasCobranca(List<RegraCobranca> regras) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(regras.map((r) => r.toJson()).toList());
    await prefs.setString(regrasCobrancaKey, encoded);
  }
}
