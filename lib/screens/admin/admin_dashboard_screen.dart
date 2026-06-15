import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/screens/admin/admin_horarios_screen.dart';
import 'package:pulguinha/config/pagbank_config.dart';
import 'package:pulguinha/screens/admin/admin_mp_config_screen.dart';
import 'package:pulguinha/screens/admin/admin_pagbank_config_screen.dart';
import 'package:pulguinha/screens/admin/admin_produtos_screen.dart';
import 'package:pulguinha/screens/shared/sobre_app_screen.dart';
import 'package:pulguinha/widgets/theme_settings_tile.dart';
import 'package:pulguinha/widgets/admin_analytics.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ativos = state.alunos.where((a) => a.status == 'Ativo').length;
    final inadimp = state.alunos.where((a) => a.status == 'Inadimplente').length;
    final agHoje = state.agendamentos.where((ag) => ag.data == MockData.today).length;
    final presHoje = state.presencasHoje().length;
    final venc7 = state.alunos.where((a) {
      if (a.status != 'Ativo') return false;
      final d = DateHelper.diasAteVencimento(a.vencimento);
      return d >= 0 && d <= 7;
    }).length;

    final aulasHoje = state.horarios.map((h) {
      final ags = state.agendamentos.where((ag) => ag.data == MockData.today && ag.horarioId == h.id).toList();
      return (h, ags);
    }).where((e) => e.$2.isNotEmpty || ['06:00', '18:00', '19:00'].contains(e.$1.hora)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), AppColors.bg]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚡ PAINEL ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.neon, letterSpacing: 2)),
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.white, height: 1.1),
                  children: [
                    TextSpan(text: 'BOM DIA, '),
                    TextSpan(text: 'PULGUINHA!', style: TextStyle(color: AppColors.neon)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(DateHelper.hojeFormatado(), style: const TextStyle(fontSize: 12, color: AppColors.gray)),
            ],
          ),
        ),
        if (state.useMock) ...[
          const SizedBox(height: 12),
          PulguinhaCard(
            borderColor: AppColors.yellow.withValues(alpha: 0.35),
            backgroundColor: AppColors.yellow.withValues(alpha: 0.06),
            child: Text(
              SupabaseConfig.isConfigured
                  ? '⚠️ Sem conexão com o banco — cadastros do site não sincronizam até a internet voltar. Puxe a tela para baixo para tentar de novo.'
                  : '⚠️ Modo local — reinstale o APK oficial do Pulguinha.',
              style: const TextStyle(fontSize: 11, color: AppColors.yellow, height: 1.4, decoration: TextDecoration.none),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _statCard('👥', '$ativos', 'Alunos Ativos', AppColors.neon, AppColors.neon.withValues(alpha: 0.08)),
            _statCard('⚠️', '$inadimp', 'Inadimplentes', AppColors.red, AppColors.red.withValues(alpha: 0.08)),
            _statCard('✅', '$presHoje', 'Presenças Hoje', AppColors.neon, AppColors.neon.withValues(alpha: 0.08)),
            _statCard('📅', '$agHoje', 'Agendados Hoje', AppColors.blue, AppColors.blue.withValues(alpha: 0.08)),
            _statCard('💰', '$venc7', 'Vencendo 7d', AppColors.yellow, AppColors.yellow.withValues(alpha: 0.08)),
            _statCard('🎂', '${state.aniversariantesDoMes()}', 'Aniv. do Mês', AppColors.red, AppColors.red.withValues(alpha: 0.08)),
          ],
        ),
        const SizedBox(height: 24),
        AdminAnalyticsSection(state: state),
        const SizedBox(height: 20),
        const SectionTitle(icon: '📋', title: 'Aulas de Hoje'),
        ...aulasHoje.map((e) => _aulaCard(e.$1, e.$2, state)),
        const SizedBox(height: 20),
        const SectionTitle(icon: '🔔', title: 'Alertas'),
        ...state.alunos.where((a) => a.status == 'Inadimplente').map(_alertaInadimplente),
        ...state.alunos.where((a) => a.status == 'Pendente').map(_alertaPendente),
        ...state.alunos.where((a) {
          final d = DateHelper.diasAteVencimento(a.vencimento);
          return d >= 0 && d <= 7 && a.status == 'Ativo';
        }).map(_alertaVencendo),
        const SizedBox(height: 24),
        const SectionTitle(icon: '⚙️', title: 'Configurações'),
        const SizedBox(height: 10),
        const ThemeSettingsTile(),
        const SizedBox(height: 10),
        _configTile(
          context,
          icon: '🕐',
          title: 'Horários e vagas',
          subtitle: '${state.horarios.length} turmas configuradas',
          color: AppColors.neon,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminHorariosScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _configTile(
          context,
          icon: '🛒',
          title: 'Planos e produtos',
          subtitle: '${state.produtos.length} itens na loja',
          color: AppColors.neon,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminProdutosScreen(standalone: true)),
          ),
        ),
        const SizedBox(height: 10),
        _configTile(
          context,
          icon: '💳',
          title: 'Mercado Pago',
          subtitle: MercadoPagoConfig.integrationLabel(),
          color: AppColors.mercadoPago,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminMpConfigScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _configTile(
          context,
          icon: '🏦',
          title: 'PagBank / PagSeguro',
          subtitle: PagBankConfig.integrationLabel(),
          color: AppColors.pagBank,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminPagBankConfigScreen()),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SobreAppScreen())),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Text('ℹ️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sobre o app', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                      Text('Versão, desenvolvedor e informações', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.grayDim),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _configTile(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grayDim),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String icon, String value, String label, Color color, Color bg) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color, height: 1)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _aulaCard(dynamic h, List ags, AppState state) {
    final pres = state.presencasHoje().where((p) => p.horarioId == h.id).length;
    final pct = ags.length / h.capacidade * 100;
    final barC = pct >= 90 ? AppColors.red : pct >= 60 ? AppColors.yellow : AppColors.neon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PulguinhaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(h.hora, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.neon)),
                    const SizedBox(width: 8),
                    Text(h.dias, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ],
                ),
                Row(
                  children: [
                    if (pres > 0) PulguinhaBadge(label: '✅ $pres', variant: BadgeVariant.neon),
                    const SizedBox(width: 6),
                    Text('${ags.length}/${h.capacidade}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: pct / 100, minHeight: 4, backgroundColor: AppColors.card2, color: barC),
            ),
            const SizedBox(height: 10),
            if (ags.isEmpty)
              const Text('Nenhum aluno agendado', style: TextStyle(fontSize: 12, color: AppColors.grayDim))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ags.map<Widget>((ag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.neon.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.neon.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(ag.nomeAluno.split(' ').first, style: const TextStyle(fontSize: 11, color: AppColors.neon, fontWeight: FontWeight.w700)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _alertaPendente(dynamic a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.neon.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.neon.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            PulguinhaAvatar(initials: a.avatar, size: AvatarSize.sm, fotoBase64: a.foto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                  const Text('Cadastro aguardando aprovação', style: TextStyle(fontSize: 11, color: AppColors.neon)),
                ],
              ),
            ),
            const Text('⏳', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _alertaInadimplente(dynamic a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            PulguinhaAvatar(initials: a.avatar, size: AvatarSize.sm, fotoBase64: a.foto),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                const Text('Mensalidade em atraso', style: TextStyle(fontSize: 11, color: AppColors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertaVencendo(dynamic a) {
    final d = DateHelper.diasAteVencimento(a.vencimento);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.yellow.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            PulguinhaAvatar(initials: a.avatar, size: AvatarSize.sm, fotoBase64: a.foto),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                Text('Vence em $d dias', style: const TextStyle(fontSize: 11, color: AppColors.yellow)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
