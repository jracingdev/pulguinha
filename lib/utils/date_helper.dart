import 'package:intl/intl.dart';
import 'package:pulguinha/data/mock_data.dart';

class DateHelper {
  static int diasAteVencimento(String vencimento) {
    final hoje = DateTime.parse(MockData.today);
    final venc = DateTime.parse(vencimento);
    return venc.difference(hoje).inDays;
  }

  static List<DiaSemana> diasDaSemana(int semanaOffset) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final base = monday.add(Duration(days: semanaOffset * 7));
    return List.generate(7, (i) {
      final d = base.add(Duration(days: i));
      final iso = DateFormat('yyyy-MM-dd').format(d);
      return DiaSemana(
        iso: iso,
        num: d.day,
        nome: DateFormat('EEEE', 'pt_BR').format(d).toUpperCase(),
        mes: DateFormat('MMMM', 'pt_BR').format(d),
      );
    });
  }

  static String labelSemana(List<DiaSemana> dias) {
    final ini = dias.first;
    final fim = dias.last;
    final ano = DateTime.parse(fim.iso).year;
    return '${ini.num} ${ini.mes.substring(0, 3)} — ${fim.num} ${fim.mes.substring(0, 3)} $ano';
  }

  static String formatarData(String iso) {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
  }

  static String formatarDataLonga(String iso) {
    return DateFormat("EEEE, d 'de' MMM", 'pt_BR').format(DateTime.parse('${iso}T12:00:00'));
  }

  static String hojeFormatado() {
    return DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR').format(DateTime.now());
  }

  static bool isAniversarioHoje(String? dataNascimento) {
    if (dataNascimento == null || dataNascimento.isEmpty) return false;
    final nasc = DateTime.parse(dataNascimento);
    final hoje = DateTime.now();
    return nasc.month == hoje.month && nasc.day == hoje.day;
  }

  static int diasAteAniversario(String dataNascimento) {
    final nasc = DateTime.parse(dataNascimento);
    final hoje = DateTime.now();
    var proximo = DateTime(hoje.year, nasc.month, nasc.day);
    if (proximo.isBefore(DateTime(hoje.year, hoje.month, hoje.day))) {
      proximo = DateTime(hoje.year + 1, nasc.month, nasc.day);
    }
    return proximo.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  }

  static bool aniversarioNoMes(String? dataNascimento, int mes) {
    if (dataNascimento == null || dataNascimento.isEmpty) return false;
    return DateTime.parse(dataNascimento).month == mes;
  }

  static String formatarAniversario(String dataNascimento) {
    return DateFormat("d 'de' MMMM", 'pt_BR').format(DateTime.parse(dataNascimento));
  }
}

class DiaSemana {
  const DiaSemana({
    required this.iso,
    required this.num,
    required this.nome,
    required this.mes,
  });

  final String iso;
  final int num;
  final String nome;
  final String mes;
}
