import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/models/billing_rules.dart';
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
    final mensalistas = state.alunosMensalistas;
    final parceiros = state.alunosParceirosAtivos;
    final inad = mensalistas.where((a) => a.status == 'Inadimplente').toList();
    final venc = mensalistas.where((a) {
      final d = DateHelper.diasAteVencimento(a.vencimento);
      return a.status == 'Ativo' && d >= 0 && d <= 7;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FINANCEIRO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 16),
        _configVencimentoCard(context, state),
        const SizedBox(height: 16),
        _regrasCobrancaSection(context, state),
        const SizedBox(height: 16),
        _indicacoesSection(context, state),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _valorCard('RECEITA MENSAL EST.', 'R\$ ${rec.toStringAsFixed(0)}', AppColors.neon, AppColors.neon.withValues(alpha: 0.08))),
            const SizedBox(width: 10),
            Expanded(child: _valorCard('INADIMPLENTES', '${inad.length}', AppColors.red, AppColors.red.withValues(alpha: 0.08))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _valorCard(
                'MENSALISTAS',
                '${mensalistas.where((a) => a.status == 'Ativo').length}',
                AppColors.yellow,
                AppColors.yellow.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _valorCard(
                'GYMPASS / TOTALPASS',
                '${parceiros.length}',
                AppColors.blue,
                AppColors.blue.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Alunos GymPass/TotalPass agendam normalmente; o repasse fica fora do financeiro do app.',
          style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.35),
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
        if (parceiros.isNotEmpty) ...[
          const SectionTitle(icon: '🎫', title: 'GymPass / TotalPass (sem mensalidade)'),
          ...parceiros.map((a) => _alunoFinanceiro(context, state, a, tipo: 'parceiro')),
          const SizedBox(height: 20),
        ],
        const SectionTitle(icon: '👥', title: 'Mensalistas'),
        ...mensalistas.map((a) => _alunoFinanceiro(context, state, a, tipo: 'todos')),
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
    if (tipo == 'parceiro') border = AppColors.blue.withValues(alpha: 0.25);

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
                      if (a.ehAlunoParceiro)
                        PulguinhaBadge(label: a.labelBeneficio, variant: BadgeVariant.blue)
                      else
                        PulguinhaBadge(
                          label: a.status,
                          variant: a.status == 'Ativo'
                              ? BadgeVariant.neon
                              : a.status == 'Inadimplente'
                                  ? BadgeVariant.red
                                  : BadgeVariant.gray,
                        ),
                    ],
                  ),
                  Text(
                    a.ehAlunoParceiro
                        ? 'Check-in via ${a.labelBeneficio} · sem mensalidade no app'
                        : a.status == 'Pendente'
                            ? 'Aguardando aprovação · ${a.plano}'
                            : tipo == 'inad'
                                ? 'Venceu ${DateHelper.formatarData(a.vencimento)} · ${a.plano}'
                                : tipo == 'venc'
                                    ? 'Vence em ${DateHelper.diasAteVencimento(a.vencimento)}d · ${a.plano}'
                                    : '${a.plano} · ${VencimentoHelper.temPlanoAtivo(a) ? 'Venc. ${DateHelper.formatarData(a.vencimento)}' : 'Sem vencimento'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: tipo == 'inad'
                          ? AppColors.red
                          : tipo == 'venc'
                              ? AppColors.yellow
                              : tipo == 'parceiro'
                                  ? AppColors.blue
                                  : AppColors.gray,
                    ),
                  ),
                ],
              ),
            ),
            if (!a.ehAlunoParceiro &&
                (tipo == 'inad' || (a.status == 'Ativo' && DateHelper.diasAteVencimento(a.vencimento) <= 0)))
              TextButton(
                onPressed: () {
                  state.marcarPago(a.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pagamento registrado — ${a.nome}')));
                },
                child: const Text('✓ Baixa', style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w800)),
              )
            else if (!a.ehAlunoParceiro && a.status == 'Ativo')
              OutlinedButton(
                onPressed: () => state.renovarPlano(a),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tipo == 'venc' ? AppColors.yellow : AppColors.neon,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('Renovar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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

  Widget _regrasCobrancaSection(BuildContext context, AppState state) {
    final regras = state.regrasCobranca;

    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Regras de cobrança', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
          const SizedBox(height: 6),
          const Text(
            'Configure descontos e novas regras. O app aplica desconto antecipado, indicação e crédito na loja.',
            style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (regras.isEmpty)
            const Text('Nenhuma regra configurada.', style: TextStyle(fontSize: 12, color: AppColors.grayDim))
          else ...regras.map((r) => _regraCard(context: context, state: state, regra: r)),
          const SizedBox(height: 12),
          NeonButton(
            label: '➕ Nova regra',
            fullWidth: true,
            onPressed: () => _abrirFormRegra(context, state),
          ),
        ],
      ),
    );
  }

  Widget _indicacoesSection(BuildContext context, AppState state) {
    final lista = state.indicacoes;
    final pendentes = lista.where((i) => i.status == 'pendente').length;
    final convertidas = lista.where((i) => i.status == 'convertida').length;

    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Indique e Ganhe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
          const SizedBox(height: 6),
          Text(
            '$pendentes pendentes · $convertidas convertidas',
            style: const TextStyle(fontSize: 11, color: AppColors.gray),
          ),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            const Text('Nenhuma indicação registrada ainda.', style: TextStyle(fontSize: 12, color: AppColors.grayDim))
          else
            ...lista.take(20).map((ind) {
              final indicador = state.alunoPorId(ind.indicadorId);
              final indicado = state.alunoPorId(ind.indicadoId);
              final statusLabel = ind.status == 'convertida'
                  ? 'Convertida'
                  : ind.status == 'pendente'
                      ? 'Pendente'
                      : ind.status;
              final variant = ind.status == 'convertida'
                  ? BadgeVariant.neon
                  : ind.status == 'pendente'
                      ? BadgeVariant.yellow
                      : BadgeVariant.gray;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PulguinhaCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${indicador?.nome ?? 'Aluno #${ind.indicadorId}'} → ${indicado?.nome ?? 'Aluno #${ind.indicadoId}'}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Código ${ind.codigoUsado} · ${DateHelper.formatarData(ind.dataCriacao)}${ind.dataConversao != null ? ' · conv. ${DateHelper.formatarData(ind.dataConversao!)}' : ''}',
                              style: const TextStyle(fontSize: 10, color: AppColors.gray),
                            ),
                          ],
                        ),
                      ),
                      PulguinhaBadge(label: statusLabel, variant: variant),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _regraCard({required BuildContext context, required AppState state, required RegraCobranca regra}) {
    final valor =
        regra.tipo == 'desconto_antecipado' ? '${regra.valorPercent.toStringAsFixed(0)}%' : regra.valorFixo > 0 ? 'R\$ ${regra.valorFixo.toStringAsFixed(0)}' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PulguinhaCard(
        borderColor: regra.ativo ? AppColors.neon.withValues(alpha: 0.25) : AppColors.border,
        backgroundColor: regra.ativo ? AppColors.neon.withValues(alpha: 0.06) : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(regra.nome, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text('${regra.tipo.replaceAll('_', ' ')}${valor.isNotEmpty ? ' · $valor' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ),
            ),
            PulguinhaBadge(
              label: regra.ativo ? 'Ativa' : 'Inativa',
              variant: regra.ativo ? BadgeVariant.neon : BadgeVariant.gray,
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Editar regra',
              icon: const Icon(Icons.edit_rounded, color: AppColors.neon),
              onPressed: () => _abrirFormRegra(context, state, editando: regra),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormRegra(
    BuildContext context,
    AppState state, {
    RegraCobranca? editando,
  }) async {
    String tipoSel = editando?.tipo ?? 'desconto_antecipado';
    final tipoPersonalizadaCtrl = TextEditingController(
      text: (editando != null && !['desconto_antecipado', 'indique_ganhe'].contains(editando.tipo)) ? editando.tipo : 'personalizada',
    );
    final nomeCtrl = TextEditingController(text: editando?.nome ?? '');
    final ativo = editando?.ativo ?? true;
    final percCtrl = TextEditingController(text: '${editando?.valorPercent ?? 10}');
    final fixCtrl = TextEditingController(text: '${editando?.valorFixo ?? 30}');

    bool ativoLocal = ativo;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
          title: Text(editando == null ? 'Nova regra' : 'Editar regra', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipoSel,
                    items: const [
                      DropdownMenuItem(value: 'desconto_antecipado', child: Text('Desconto antes do vencimento')),
                      DropdownMenuItem(value: 'indique_ganhe', child: Text('Indique e ganhe')),
                      DropdownMenuItem(value: 'personalizada', child: Text('Personalizada (novo tipo)')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => tipoSel = v);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tipoSel == 'personalizada')
                    FieldLabel(
                      label: 'Tipo (id da regra)',
                      child: TextField(
                        controller: tipoPersonalizadaCtrl,
                        decoration: const InputDecoration(hintText: 'ex.: regra_cpf_valido'),
                      ),
                    ),
                  FieldLabel(
                    label: 'Nome da regra',
                    child: TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(hintText: 'Ex.: Desconto antes do vencimento'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativa', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.white)),
                    value: ativoLocal,
                    activeColor: AppColors.neon,
                    onChanged: (v) => setLocal(() => ativoLocal = v),
                  ),
                  const SizedBox(height: 10),
                  if (tipoSel == 'desconto_antecipado' || tipoSel == 'personalizada')
                    FieldLabel(
                      label: 'Desconto (%)',
                      child: TextField(
                        controller: percCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '10'),
                      ),
                    ),
                  if (tipoSel == 'indique_ganhe' || tipoSel == 'personalizada')
                    FieldLabel(
                      label: 'Crédito/valor fixo (R\$)',
                      child: TextField(
                        controller: fixCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '30'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final tipoFinal = tipoSel == 'personalizada' ? tipoPersonalizadaCtrl.text.trim() : tipoSel;
                if (tipoFinal.isEmpty) return;

                final nome = nomeCtrl.text.trim().isEmpty ? tipoFinal.replaceAll('_', ' ') : nomeCtrl.text.trim();
                final valorPercent = double.tryParse(percCtrl.text.replaceAll(',', '.')) ?? (tipoFinal == 'desconto_antecipado' ? 10 : 0);
                final valorFixo = double.tryParse(fixCtrl.text.replaceAll(',', '.')) ?? (tipoFinal == 'indique_ganhe' ? 30 : 0);

                final id = (tipoFinal == 'desconto_antecipado' || tipoFinal == 'indique_ganhe') ? tipoFinal : 'custom_${DateTime.now().millisecondsSinceEpoch}';

                final regra = RegraCobranca(
                  id: id,
                  nome: nome,
                  tipo: tipoFinal,
                  valorPercent: valorPercent,
                  valorFixo: valorFixo,
                  ativo: ativoLocal,
                  descricao: '',
                );

                final novaLista = List<RegraCobranca>.from(state.regrasCobranca);
                final idx = novaLista.indexWhere((r) => r.id == regra.id);
                if (idx >= 0) {
                  novaLista[idx] = regra;
                } else {
                  novaLista.add(regra);
                }
                await state.salvarRegrasCobranca(novaLista);
                if (!context.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Salvar', style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
