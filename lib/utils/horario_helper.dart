import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/utils/date_helper.dart';

/// Ordenação e normalização de horários (ex.: 06:00 antes de 09:00).
class HorarioHelper {
  /// Converte "6:00", "06:00", "18:30" em minutos desde meia-noite.
  static int minutosDoDia(String hora) {
    final trimmed = hora.trim();
    final match = RegExp(r'^(\d{1,2})\s*[:hH]\s*(\d{0,2})').firstMatch(trimmed);
    if (match != null) {
      final h = int.tryParse(match.group(1) ?? '') ?? 0;
      final m = int.tryParse(match.group(2) ?? '') ?? 0;
      return h.clamp(0, 23) * 60 + m.clamp(0, 59);
    }
    final onlyHour = int.tryParse(trimmed.replaceAll(RegExp(r'\D'), ''));
    if (onlyHour != null) return onlyHour.clamp(0, 23) * 60;
    return 0;
  }

  /// Formato padrão HH:mm para persistência e exibição consistente.
  static String normalizar(String hora) {
    final min = minutosDoDia(hora);
    final h = min ~/ 60;
    final m = min % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static int compareHorarios(String a, String b) =>
      minutosDoDia(a).compareTo(minutosDoDia(b));

  static List<Horario> ordenar(List<Horario> lista) {
    final copia = List<Horario>.from(lista);
    copia.sort((a, b) => compareHorarios(a.hora, b.hora));
    return copia;
  }

  /// Normaliza texto de dias (`Seg/Qua/Sex`, `Seg a Sex`, etc.) para weekdays ISO
  /// (1 = segunda … 7 = domingo). Texto vazio = todos os dias.
  static Set<int> weekdaysFromDias(String raw) {
    final t = _semAcento(raw.toLowerCase().trim());
    if (t.isEmpty || t.contains('todos') || t == 'diario' || t == 'diariamente') {
      return {1, 2, 3, 4, 5, 6, 7};
    }

    if (RegExp(r'seg(?:unda)?\s*a\s*sex(?:ta)?').hasMatch(t) ||
        RegExp(r'seg(?:unda)?\s*[-–]\s*sex(?:ta)?').hasMatch(t) ||
        t.contains('segunda a sexta') ||
        t.contains('uteis') ||
        t.contains('util')) {
      return {1, 2, 3, 4, 5};
    }

    if (RegExp(r'sab(?:ado)?\s*e\s*dom(?:ingo)?').hasMatch(t) ||
        RegExp(r'sab(?:ado)?\s*/\s*dom(?:ingo)?').hasMatch(t)) {
      return {6, 7};
    }

    final parts = t
        .split(RegExp(r'[/|,;]+|\se\s+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);

    final out = <int>{};
    for (final part in parts) {
      final w = _tokenToWeekday(part);
      if (w != null) out.add(w);
    }
    return out;
  }

  /// `true` se o horário [diasTexto] ocorre na data ISO [dataIso].
  static bool ocorreNoDia(String diasTexto, String dataIso) {
    final parsed = DateHelper.parseData(dataIso);
    final weekday = DateTime(parsed.year, parsed.month, parsed.day).weekday;
    final days = weekdaysFromDias(diasTexto);
    if (days.isEmpty) return true; // formato desconhecido: não bloqueia
    return days.contains(weekday);
  }

  static String _semAcento(String s) => s
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  static int? _tokenToWeekday(String token) {
    final t = _semAcento(token.toLowerCase().trim());
    if (t.startsWith('seg') || t == 'mon' || t.startsWith('monday')) return 1;
    if (t.startsWith('ter') || t == 'tue' || t.startsWith('tuesday')) return 2;
    if (t.startsWith('qua') || t == 'wed' || t.startsWith('wednesday')) return 3;
    if (t.startsWith('qui') || t == 'thu' || t.startsWith('thursday')) return 4;
    if (t.startsWith('sex') || t == 'fri' || t.startsWith('friday')) return 5;
    if (t.startsWith('sab') || t == 'sat' || t.startsWith('saturday')) return 6;
    if (t.startsWith('dom') || t == 'sun' || t.startsWith('sunday')) return 7;
    return null;
  }
}
