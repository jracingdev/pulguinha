import 'package:intl/intl.dart';
import 'package:pulguinha/data/mock_data.dart';

class DateHelper {
  static final _br = DateFormat('dd-MM-yyyy');
  static final _iso = DateFormat('yyyy-MM-dd');

  static DateTime parseData(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return DateTime.now();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
      return DateTime.parse(trimmed.split('T').first);
    }
    if (RegExp(r'^\d{2}-\d{2}-\d{4}').hasMatch(trimmed)) {
      return _br.parse(trimmed);
    }
    if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(trimmed)) {
      return DateFormat('dd/MM/yyyy').parse(trimmed);
    }
    return DateTime.parse(trimmed.split('T').first);
  }

  static String paraIso(String value) => _iso.format(parseData(value));

  static int diasAteVencimento(String vencimento) {
    final hoje = parseData(MockData.today);
    final venc = parseData(vencimento);
    return DateTime(venc.year, venc.month, venc.day).difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  }

  static List<DiaSemana> diasDaSemana(int semanaOffset) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final base = monday.add(Duration(days: semanaOffset * 7));
    return List.generate(7, (i) {
      final d = base.add(Duration(days: i));
      final iso = _iso.format(d);
      return DiaSemana(
        iso: iso,
        num: d.day,
        nome: DateFormat('EEEE', 'pt_BR').format(d).toUpperCase(),
        mes: DateFormat('MMMM', 'pt_BR').format(d),
        label: _br.format(d),
      );
    });
  }

  static String labelSemana(List<DiaSemana> dias) {
    final ini = dias.first;
    final fim = dias.last;
    return '${ini.label} — ${fim.label}';
  }

  static String formatarData(String value) {
    return _br.format(parseData(value));
  }

  static String formatarDataLonga(String value) {
    final d = parseData(value);
    final dia = DateFormat('EEEE', 'pt_BR').format(d);
    return '$dia, ${formatarData(value)}';
  }

  static String hojeFormatado() {
    return formatarDataLonga(_iso.format(DateTime.now()));
  }

  static String hojeIso() => _iso.format(DateTime.now());

  static bool isAniversarioHoje(String? dataNascimento) {
    if (dataNascimento == null || dataNascimento.isEmpty) return false;
    final nasc = parseData(dataNascimento);
    final hoje = DateTime.now();
    return nasc.month == hoje.month && nasc.day == hoje.day;
  }

  static int diasAteAniversario(String dataNascimento) {
    final nasc = parseData(dataNascimento);
    final hoje = DateTime.now();
    var proximo = DateTime(hoje.year, nasc.month, nasc.day);
    if (proximo.isBefore(DateTime(hoje.year, hoje.month, hoje.day))) {
      proximo = DateTime(hoje.year + 1, nasc.month, nasc.day);
    }
    return proximo.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  }

  static bool aniversarioNoMes(String? dataNascimento, int mes) {
    if (dataNascimento == null || dataNascimento.isEmpty) return false;
    return parseData(dataNascimento).month == mes;
  }

  static String formatarAniversario(String dataNascimento) {
    return _br.format(parseData(dataNascimento));
  }
}

class DiaSemana {
  const DiaSemana({
    required this.iso,
    required this.num,
    required this.nome,
    required this.mes,
    required this.label,
  });

  final String iso;
  final int num;
  final String nome;
  final String mes;
  final String label;
}
