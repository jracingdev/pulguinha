import 'package:pulguinha/models/models.dart';

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
}
