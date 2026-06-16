import 'dart:convert';

import 'package:pulguinha/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local de indicações (modo mock / fallback).
class ReferralStorage {
  ReferralStorage._();
  static final instance = ReferralStorage._();

  static const _indicacoesKey = 'referral_indicacoes';

  Future<List<Indicacao>> loadIndicacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indicacoesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Indicacao.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveIndicacoes(List<Indicacao> indicacoes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(indicacoes.map((i) {
      final map = i.toJson();
      map['id'] = i.id;
      return map;
    }).toList());
    await prefs.setString(_indicacoesKey, encoded);
  }
}
