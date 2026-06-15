import 'package:flutter/material.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';

/// Textos e cores de vencimento — alunos Pendentes não exibem "Vence hoje".
class VencimentoHelper {
  static bool temPlanoAtivo(Aluno aluno) =>
      aluno.status != 'Pendente' && aluno.vencimento != MockData.vencimentoPendente;

  static String calcularVencimentoInicial(String plano, [String? baseIso]) {
    final base = DateTime.parse(baseIso ?? MockData.today);
    final meses = MockData.mesesPlano[plano] ?? 1;
    final nova = base.add(Duration(days: meses * 30));
    return '${nova.year}-${nova.month.toString().padLeft(2, '0')}-${nova.day.toString().padLeft(2, '0')}';
  }

  static String textoCurto(Aluno aluno) {
    if (aluno.status == 'Pendente') return 'Aguardando aprovação';
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return 'Vencido ${d.abs()}d';
    if (d == 0) return 'Vence hoje!';
    if (d <= 7) return 'Vence em ${d}d';
    return 'Venc. ${DateHelper.formatarData(aluno.vencimento)}';
  }

  static String textoLongo(Aluno aluno) {
    if (aluno.status == 'Pendente') return 'Aguardando aprovação do professor';
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return 'Vencido há ${d.abs()} dias';
    if (d == 0) return 'Vence hoje!';
    if (d <= 7) return 'Vence em $d dias';
    return DateHelper.formatarData(aluno.vencimento);
  }

  static Color cor(Aluno aluno) {
    if (aluno.status == 'Pendente') return AppColors.yellow;
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return AppColors.red;
    if (d <= 7) return AppColors.yellow;
    return AppColors.gray;
  }

  static Color corDestaque(Aluno aluno) {
    if (aluno.status == 'Pendente') return AppColors.yellow;
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return AppColors.red;
    if (d <= 7) return AppColors.yellow;
    return AppColors.neon;
  }
}
