import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulguinha/data/training_tips.dart';

class WaterDayData {
  const WaterDayData({
    required this.date,
    required this.copos,
    required this.streak,
    required this.metaCopos,
  });

  final String date;
  final int copos;
  final int streak;
  final int metaCopos;

  int get ml => copos * TrainingTipsData.mlPorCopo;
  int get metaMl => metaCopos * TrainingTipsData.mlPorCopo;
  double get progress => (copos / metaCopos).clamp(0.0, 1.0);
  bool get metaBatida => copos >= metaCopos;
}

class BmiData {
  const BmiData({this.pesoKg, this.alturaCm});

  final double? pesoKg;
  final double? alturaCm;

  double? get imc {
    if (pesoKg == null || alturaCm == null || alturaCm! <= 0) return null;
    final alturaM = alturaCm! / 100;
    return pesoKg! / (alturaM * alturaM);
  }
}

class BmiCategory {
  const BmiCategory({required this.label, required this.colorHex, required this.descricao});

  final String label;
  final int colorHex;
  final String descricao;
}

class WellnessService {
  WellnessService._();
  static final WellnessService instance = WellnessService._();

  static const _keyWaterDate = 'wellness_water_date';
  static const _keyWaterCopos = 'wellness_water_copos';
  static const _keyWaterStreak = 'wellness_water_streak';
  static const _keyBmiPeso = 'wellness_bmi_peso';
  static const _keyBmiAltura = 'wellness_bmi_altura';

  String _todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<WaterDayData> getWaterToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayIso();
    final savedDate = prefs.getString(_keyWaterDate);
    var copos = prefs.getInt(_keyWaterCopos) ?? 0;
    var streak = prefs.getInt(_keyWaterStreak) ?? 0;
    const meta = TrainingTipsData.metaCoposAgua;

    if (savedDate != null && savedDate != today) {
      final metaBatidaOntem = copos >= meta;
      if (metaBatidaOntem) {
        streak += 1;
      } else {
        streak = 0;
      }
      copos = 0;
      await prefs.setString(_keyWaterDate, today);
      await prefs.setInt(_keyWaterCopos, 0);
      await prefs.setInt(_keyWaterStreak, streak);
    } else if (savedDate == null) {
      await prefs.setString(_keyWaterDate, today);
      await prefs.setInt(_keyWaterCopos, 0);
    }

    return WaterDayData(date: today, copos: copos, streak: streak, metaCopos: meta);
  }

  Future<WaterDayData> addCopo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await getWaterToday();
    final novo = data.copos + 1;
    await prefs.setInt(_keyWaterCopos, novo);
    return WaterDayData(date: data.date, copos: novo, streak: data.streak, metaCopos: data.metaCopos);
  }

  Future<WaterDayData> removeCopo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await getWaterToday();
    final novo = (data.copos - 1).clamp(0, 999);
    await prefs.setInt(_keyWaterCopos, novo);
    return WaterDayData(date: data.date, copos: novo, streak: data.streak, metaCopos: data.metaCopos);
  }

  String mensagemAgua(WaterDayData data) {
    if (data.metaBatida) {
      if (data.streak >= 3) {
        return 'Meta batida! 🔥 ${data.streak} dias seguidos!';
      }
      return 'Meta batida! 🎉';
    }
    if (data.copos == 0) return 'Comece o dia hidratado! 💧';
    if (data.progress >= 0.75) return 'Quase lá! Mais um gole! 💪';
    if (data.progress >= 0.5) return 'Metade do caminho! 🚀';
    return 'Mais um gole! 💪';
  }

  Future<BmiData> getBmi() async {
    final prefs = await SharedPreferences.getInstance();
    return BmiData(
      pesoKg: prefs.getDouble(_keyBmiPeso),
      alturaCm: prefs.getDouble(_keyBmiAltura),
    );
  }

  Future<BmiData> saveBmi({required double pesoKg, required double alturaCm}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBmiPeso, pesoKg);
    await prefs.setDouble(_keyBmiAltura, alturaCm);
    return BmiData(pesoKg: pesoKg, alturaCm: alturaCm);
  }

  BmiCategory categoriaImc(double imc) {
    if (imc < 18.5) {
      return const BmiCategory(
        label: 'Abaixo do peso',
        colorHex: 0xFF4A9EFF,
        descricao: 'IMC abaixo do recomendado. Consulte um profissional de saúde.',
      );
    }
    if (imc < 25) {
      return const BmiCategory(
        label: 'Normal',
        colorHex: 0xFFAAFF00,
        descricao: 'Faixa considerada saudável para a maioria dos adultos.',
      );
    }
    if (imc < 30) {
      return const BmiCategory(
        label: 'Sobrepeso',
        colorHex: 0xFFFFB800,
        descricao: 'Acima do ideal. Combine treino e alimentação equilibrada.',
      );
    }
    return const BmiCategory(
      label: 'Obesidade',
      colorHex: 0xFFFF4444,
      descricao: 'Consulte um profissional de saúde para orientação personalizada.',
    );
  }
}
