import 'package:flutter/material.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/services/finance_settings_storage.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';

/// Textos, cores e cálculo de vencimento de mensalidades.
class VencimentoHelper {
  static bool temPlanoAtivo(Aluno aluno) =>
      aluno.status != 'Pendente' && aluno.vencimento != MockData.vencimentoPendente;

  /// Primeiro vencimento ao cadastrar/aprovar — sempre no futuro, no dia configurado.
  static String calcularVencimentoInicial(
    String plano,
    int diaVencimento, [
    String? baseIso,
  ]) {
    final base = DateHelper.parseData(baseIso ?? MockData.today);
    final meses = MockData.mesesPlano[plano] ?? 1;
    return _proximaDataNoDia(
      diaVencimento: diaVencimento,
      ano: base.year,
      mes: base.month + meses,
      referencia: base,
      incluirHoje: false,
    );
  }

  /// Após pagamento manual ou automático (loja / MP / PagBank).
  static String proximoVencimentoAposPagamento({
    required String plano,
    required int diaVencimento,
    required String vencimentoAtual,
  }) {
    final hoje = DateHelper.parseData(MockData.today);
    final atual = DateHelper.parseData(vencimentoAtual);
    final base = atual.isAfter(hoje) ? atual : hoje;
    final meses = MockData.mesesPlano[plano] ?? 1;
    return _proximaDataNoDia(
      diaVencimento: diaVencimento,
      ano: base.year,
      mes: base.month + meses,
      referencia: base,
      incluirHoje: true,
    );
  }

  static String _proximaDataNoDia({
    required int diaVencimento,
    required int ano,
    required int mes,
    required DateTime referencia,
    required bool incluirHoje,
  }) {
    final dia = diaVencimento.clamp(1, 28);
    var y = ano;
    var m = mes;
    while (m > 12) {
      m -= 12;
      y++;
    }
    while (m < 1) {
      m += 12;
      y--;
    }

    var candidato = DateTime(y, m, dia);
    final ref = DateTime(referencia.year, referencia.month, referencia.day);

    bool precisaAvancar(DateTime d) => incluirHoje ? d.isBefore(ref) : !d.isAfter(ref);

    while (precisaAvancar(candidato)) {
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
      candidato = DateTime(y, m, dia);
    }

    return '${candidato.year}-${candidato.month.toString().padLeft(2, '0')}-${candidato.day.toString().padLeft(2, '0')}';
  }

  static String textoCurto(Aluno aluno) {
    if (aluno.status == 'Pendente') return 'Aguardando aprovação';
    if (aluno.status == 'Inadimplente') return 'Em atraso';
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return 'Vencido ${d.abs()}d';
    if (d == 0) return 'Vence hoje!';
    if (d <= 7) return 'Vence em ${d}d';
    return 'Venc. ${DateHelper.formatarData(aluno.vencimento)}';
  }

  static String textoLongo(Aluno aluno) {
    if (aluno.status == 'Pendente') return 'Aguardando aprovação do professor';
    if (aluno.status == 'Inadimplente') return 'Mensalidade em atraso';
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return 'Vencido há ${d.abs()} dias';
    if (d == 0) return 'Vence hoje!';
    if (d <= 7) return 'Vence em $d dias';
    return DateHelper.formatarData(aluno.vencimento);
  }

  static Color cor(Aluno aluno) {
    if (aluno.status == 'Pendente') return AppColors.yellow;
    if (aluno.status == 'Inadimplente') return AppColors.red;
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return AppColors.red;
    if (d <= 7) return AppColors.yellow;
    return AppColors.gray;
  }

  static Color corDestaque(Aluno aluno) {
    if (aluno.status == 'Pendente') return AppColors.yellow;
    if (aluno.status == 'Inadimplente') return AppColors.red;
    final d = DateHelper.diasAteVencimento(aluno.vencimento);
    if (d < 0) return AppColors.red;
    if (d <= 7) return AppColors.yellow;
    return AppColors.neon;
  }

  static String hintVencimento(String plano, int diaVencimento) {
    final prox = calcularVencimentoInicial(plano, diaVencimento);
    return 'Ex.: ${DateHelper.formatarData(prox)} (dia $diaVencimento)';
  }

  static int get diaPadrao => FinanceSettingsStorage.defaultDiaVencimento;
}
