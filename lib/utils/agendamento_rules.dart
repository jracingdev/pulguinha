import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/horario_helper.dart';

/// Regras de janela para o aluno agendar aulas.
///
/// Permitido apenas entre **24h antes** e **1h antes** do início do treino.
class AgendamentoRules {
  static const Duration antecedenciaMaxima = Duration(hours: 24);
  static const Duration antecedenciaMinima = Duration(hours: 1);

  static DateTime inicioAula(String dataIso, String hora) {
    final dia = DateHelper.parseData(dataIso);
    final minutos = HorarioHelper.minutosDoDia(hora);
    return DateTime(dia.year, dia.month, dia.day, minutos ~/ 60, minutos % 60);
  }

  /// `true` se o aluno pode agendar agora para [dataIso] + [hora].
  static bool podeAgendar(String dataIso, String hora, {DateTime? agora}) {
    final now = agora ?? DateTime.now();
    final inicio = inicioAula(dataIso, hora);
    final abre = inicio.subtract(antecedenciaMaxima);
    final fecha = inicio.subtract(antecedenciaMinima);
    return !now.isBefore(abre) && !now.isAfter(fecha);
  }

  /// Mensagem amigável quando a janela não permite agendar.
  static String mensagemBloqueio(String dataIso, String hora, {DateTime? agora}) {
    final now = agora ?? DateTime.now();
    final inicio = inicioAula(dataIso, hora);
    final abre = inicio.subtract(antecedenciaMaxima);
    final fecha = inicio.subtract(antecedenciaMinima);

    if (now.isAfter(fecha)) {
      if (now.isAfter(inicio) || now.isAtSameMomentAs(inicio)) {
        return 'Esta aula já começou ou já passou.';
      }
      return 'Agendamento encerrado: só é possível até 1 hora antes do treino.';
    }
    if (now.isBefore(abre)) {
      return 'Agendamento abre 24 horas antes do treino. Ainda não está liberado.';
    }
    return 'Este horário não está disponível para agendamento.';
  }
}
