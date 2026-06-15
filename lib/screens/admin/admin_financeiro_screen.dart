import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/screens/admin/admin_mp_config_screen.dart';
import 'package:pulguinha/screens/admin/admin_pagbank_config_screen.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/vencimento_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminFinanceiroScreen extends StatelessWidget {
  const AdminFinanceiroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rec = state.receitaMensalEstimada;
    final inad = state.alunos.where((a) => a.status == 'Inadimplente').toList();
    final venc = state.alunos.where((a) {
      final d = DateHelper.diasAteVencimento(a.vencimento);
      return a.status == 'Ativo' && d >= 0 && d <= 7;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FINANCEIRO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 16),
        _configVencimentoCard(context, state),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _valorCard('RECEITA MENSAL EST.', 'R\$ ${rec.toStringAsFixed(0)}', AppColors.neon, AppColors.neon.withValues(alpha: 0.08))),
            const SizedBox(width: 10),
            Expanded(child: _valorCard('INADIMPLENTES', '${inad.length}', AppColors.red, AppColors.red.withValues(alpha: 0.08))),
          ],
        ),
        const SizedBox(height: 20),
        _mpCard(context, rec),
        _pagbankCard(context),
        if (inad.isNotEmpty) ...[
          const SectionTitle(icon: '⚠️', title: 'Em Atraso'),
          ...inad.map((a) => _alunoFinanceiro(context, state, a, tipo: 'inad')),
          const SizedBox(height: 20),
        ],
        if (venc.isNotEmpty) ...[
          const SectionTitle(icon: '⏰', title: 'Vencendo em 7 dias'),
          ...venc.map((a) => _alunoFinanceiro(context, state, a, tipo: 'venc')),
          const SizedBox(height: 20),
        ],
        const SectionTitle(icon: '👥', title: 'Todos os Alunos'),
        ...state.alunos.map((a) => _alunoFinanceiro(context, state, a, tipo: 'todos')),
      ],
    );
  }

  Widget _valorCard(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, border: Border.all(color: color.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w700)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _mpCard(BuildContext context, double rec) {
    final configured = MercadoPagoConfig.isRealCheckoutAvailable;
    final badgeLabel = configured ? 'Ativo' : 'Não configurado';
    final badgeVariant = configured ? BadgeVariant.mercadoPago : BadgeVariant.yellow;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AdminMpConfigScreen()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.mercadoPago.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.mercadoPago.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💳', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mercado Pago', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.mercadoPago)),
                    Text(MercadoPagoConfig.integrationLabel(), style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ],
                ),
              ),
              PulguinhaBadge(label: badgeLabel, variant: badgeVariant),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.grayDim, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('Recebido mês', 'R\$ ${(rec * 0.92).toStringAsFixed(0)}', AppColors.neon)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Taxa MP', '2%~5%', AppColors.gray)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Próx. repasse', 'Seg 16/06', AppColors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Toque para configurar chave pública e links', style: TextStyle(fontSize: 10, color: AppColors.grayDim)),
        ],
      ),
    ),
    );
  }

  Widget _pagbankCard(BuildContext context) {
    final configured = PagBankConfig.isRealCheckoutAvailable;
    final badgeLabel = configured ? 'Ativo' : 'Não configurado';
    final badgeVariant = configured ? BadgeVariant.pagBank : BadgeVariant.yellow;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AdminPagBankConfigScreen()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.pagBank.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.pagBank.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🏦', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PagBank / PagSeguro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.pagBank)),
                  Text(PagBankConfig.integrationLabel(), style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ),
            ),
            PulguinhaBadge(label: badgeLabel, variant: badgeVariant),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.grayDim, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w700)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _alunoFinanceiro(BuildContext context, AppState state, Aluno a, {required String tipo}) {
    Color border = AppColors.border;
    if (tipo == 'inad') border = AppColors.red.withValues(alpha: 0.2);
    if (tipo == 'venc') border = AppColors.yellow.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PulguinhaCard(
        borderColor: border,
        child: Row(
          children: [
            PulguinhaAvatar(initials: a.avatar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
                      PulguinhaBadge(
                        label: a.status,
                        variant: a.status == 'Ativo' ? BadgeVariant.neon : a.status == 'Inadimplente' ? BadgeVariant.red : BadgeVariant.gray,
                      ),
                    ],
                  ),
                  Text(
                    a.status == 'Pendente'
                        ? 'Aguardando aprovação · ${a.plano}'
                        : tipo == 'inad'
                            ? 'Venceu ${DateHelper.formatarData(a.vencimento)} · ${a.plano}'
                            : tipo == 'venc'
                                ? 'Vence em ${DateHelper.diasAteVencimento(a.vencimento)}d · ${a.plano}'
                                : '${a.plano} · ${VencimentoHelper.temPlanoAtivo(a) ? 'Venc. ${DateHelper.formatarData(a.vencimento)}' : 'Sem vencimento'}',
                    style: TextStyle(fontSize: 11, color: tipo == 'inad' ? AppColors.red : tipo == 'venc' ? AppColors.yellow : AppColors.gray),
                  ),
                ],
              ),
            ),
            if (tipo == 'inad' || (a.status == 'Ativo' && DateHelper.diasAteVencimento(a.vencimento) <= 0))
              TextButton(
                onPressed: () {
                  state.marcarPago(a.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pagamento registrado — ${a.nome}')));
                },
                child: const Text('✓ Baixa', style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w800)),
              )
            else if (a.status == 'Ativo')
              OutlinedButton(
                onPressed: () => state.renovarPlano(a),
                style: OutlinedButton.styleFrom(foregroundColor: tipo == 'venc' ? AppColors.yellow : AppColors.neon, side: BorderSide(color: AppColors.border)),
                child: Text(tipo == 'venc' ? 'Renovar' : 'Renovar', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _configVencimentoCard(BuildContext context, AppState state) {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dia de vencimento das mensalidades', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
          const SizedBox(height: 4),
          const Text(
            'Novos alunos e renovações usam este dia. Pagamentos pela loja (MP/PagBank) dão baixa automática.',
            style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.35),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: state.diaVencimentoPadrao,
            decoration: const InputDecoration(hintText: 'Dia do mês'),
            items: List.generate(28, (i) => i + 1)
                .map((d) => DropdownMenuItem(value: d, child: Text('Todo dia $d')))
                .toList(),
            onChanged: (v) {
              if (v != null) state.setDiaVencimentoPadrao(v);
            },
          ),
        ],
      ),
    );
  }
}
