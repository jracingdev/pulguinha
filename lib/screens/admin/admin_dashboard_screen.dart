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
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/screens/admin/admin_partner_config_screen.dart';
import 'package:pulguinha/screens/admin/admin_pagbank_config_screen.dart';
import 'package:pulguinha/screens/admin/admin_produtos_screen.dart';
import 'package:pulguinha/screens/shared/sobre_app_screen.dart';
import 'package:pulguinha/widgets/theme_settings_tile.dart';
import 'package:pulguinha/screens/admin/admin_desafios_screen.dart';
import 'package:pulguinha/screens/admin/admin_dicas_screen.dart';
import 'package:pulguinha/screens/admin/admin_turma_mural_screen.dart';
import 'package:pulguinha/widgets/change_password_dialog.dart';
import 'package:pulguinha/widgets/notification_settings_tile.dart';
import 'package:pulguinha/widgets/admin_analytics.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ativos = state.alunos.where((a) => a.status == 'Ativo').length;
    final inadimp = state.alunos.where((a) => a.pagaMensalidade && a.status == 'Inadimplente').length;
    final agHoje = state.agendamentos.where((ag) => ag.data == MockData.today).length;
    final presHoje = state.presencasHoje().length;
    final venc7 = state.alunos.where((a) {
      if (!a.pagaMensalidade || a.status != 'Ativo') return false;
      final d = DateHelper.diasAteVencimento(a.vencimento);
      return d >= 0 && d <= 7;
    }).length;

    final aulasHoje = state.horarios.map((h) {
      final ags = state.agendamentos.where((ag) => ag.data == MockData.today && ag.horarioId == h.id).toList();
      return (h, ags);
    }).where((e) => e.$2.isNotEmpty || ['06:00', '18:00', '19:00'].contains(e.$1.hora)).toList();

    final hora = DateTime.now().hour;
    final saudacao = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';
    final alertas = <Widget>[
      ...state.alunos.where((a) => a.status == 'Pendente').map(_alertaPendente),
      ...state.alunos.where((a) => a.pagaMensalidade && a.status == 'Inadimplente').map(_alertaInadimplente),
      ...state.alunos.where((a) {
        if (!a.pagaMensalidade) return false;
        final d = DateHelper.diasAteVencimento(a.vencimento);
        return d >= 0 && d <= 7 && a.status == 'Ativo';
      }).map(_alertaVencendo),
    ];
    final avisos = state.avisosAtivos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$saudacao, Pulguinha',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.white, height: 1.15),
                    ),
                    const SizedBox(height: 2),
                    Text(DateHelper.hojeFormatado(), style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neon.withValues(alpha: 0.25)),
                ),
                child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.neon, letterSpacing: 0.8)),
              ),
            ],
          ),
        ),
        if (state.useMock) ...[
          const SizedBox(height: 10),
          PulguinhaCard(
            padding: const EdgeInsets.all(12),
            borderColor: AppColors.yellow.withValues(alpha: 0.35),
            backgroundColor: AppColors.yellow.withValues(alpha: 0.06),
            child: Text(
              SupabaseConfig.isConfigured
                  ? '⚠️ Sem conexão com o banco — puxe para atualizar.'
                  : '⚠️ Modo local — reinstale o APK oficial do Pulguinha.',
              style: const TextStyle(fontSize: 11, color: AppColors.yellow, height: 1.35, decoration: TextDecoration.none),
            ),
          ),
        ],
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.05,
          children: [
            _statCard('👥', '$ativos', 'Ativos', AppColors.neon, AppColors.neon.withValues(alpha: 0.08)),
            _statCard('⚠️', '$inadimp', 'Inadimp.', AppColors.red, AppColors.red.withValues(alpha: 0.08)),
            _statCard('✅', '$presHoje', 'Presenças', AppColors.neon, AppColors.neon.withValues(alpha: 0.08)),
            _statCard('📅', '$agHoje', 'Agendados', AppColors.blue, AppColors.blue.withValues(alpha: 0.08)),
            _statCard('💰', '$venc7', 'Vence 7d', AppColors.yellow, AppColors.yellow.withValues(alpha: 0.08)),
            _statCard('🎂', '${state.aniversariantesDoMes()}', 'Aniv. mês', AppColors.red, AppColors.red.withValues(alpha: 0.08)),
          ],
        ),
        const SizedBox(height: 18),
        const SectionTitle(icon: '📋', title: 'Aulas de Hoje'),
        if (aulasHoje.isEmpty)
          const PulguinhaCard(
            padding: EdgeInsets.all(12),
            child: Text('Nenhuma turma com movimento hoje.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
          )
        else
          ...aulasHoje.map((e) => _aulaCard(e.$1, e.$2, state)),
        if (alertas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: SectionTitle(icon: '🔔', title: 'Alertas')),
              Text(
                '${alertas.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.gray),
              ),
            ],
          ),
          ...alertas.take(4),
          if (alertas.length > 4)
            TextButton(
              onPressed: () => state.setAdminTab('financeiro'),
              child: Text('Ver todos os ${alertas.length} alertas', style: const TextStyle(color: AppColors.neon, fontWeight: FontWeight.w700)),
            ),
        ],
        const SizedBox(height: 16),
        const SectionTitle(icon: '📢', title: 'Comunicação'),
        const SizedBox(height: 8),
        _configTile(
          context,
          icon: '📢',
          title: 'Quadro de avisos e eventos',
          subtitle: '${avisos.length} aviso(s) · ${state.eventosProximos(dias: 30).length} evento(s)',
          color: AppColors.neon,
          onTap: () => state.setAdminTab('comunicacao'),
        ),
        if (avisos.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...avisos.take(2).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => state.setAdminTab('comunicacao'),
                  borderRadius: BorderRadius.circular(12),
                  child: PulguinhaCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                              Text(a.texto.length > 60 ? '${a.texto.substring(0, 60)}...' : a.texto, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                            ],
                          ),
                        ),
                        if (a.fixado) const Text('📌', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
        const SizedBox(height: 18),
        AdminAnalyticsSection(state: state),
        const SizedBox(height: 18),
        const SectionTitle(icon: '⚙️', title: 'Configurações'),
        const SizedBox(height: 8),
        _configTile(
          context,
          icon: '👥',
          title: 'Mural das turmas',
          subtitle: 'Moderar posts (sem dados privados)',
          color: AppColors.blue,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminTurmaMuralScreen())),
        ),
        const SizedBox(height: 10),
        _configTile(
          context,
          icon: '🏋️',
          title: 'Dicas de Evolução',
          subtitle: '${state.dicasAtivas().length} dicas ativas',
          color: AppColors.neon,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminDicasScreen())),
        ),
        const SizedBox(height: 10),
        _configTile(
          context,
          icon: '🏆',
          title: 'Desafios & gamificação',
          subtitle: '${state.desafiosAtivos().length} desafio(s) vigente(s)',
          color: AppColors.yellow,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminDesafiosScreen())),
        ),
        const SizedBox(height: 10),
        _configTile(
          context,
          icon: '🔒',
          title: 'Alterar minha senha',
          subtitle: 'Senha de administrador',
          color: AppColors.neon,
          onTap: () async {
            final email = context.read<AppState>().usuario?.email ?? 'admin@pulguinha.com';
            final ok = await showChangePasswordDialog(
              context,
              titulo: 'Senha do admin',
              exigeSenhaAtual: true,
              onConfirm: (atual, nova) => context.read<AppState>().alterarSenhaAdmin(email, atual, nova),
            );
            if (ok == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Senha de admin alterada!'), behavior: SnackBarBehavior.floating),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        const NotificationSettingsTile(),
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
          icon: '🎫',
          title: 'GymPass & TotalPass',
          subtitle: PartnerConfig.integrationLabel(),
          color: AppColors.neon,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminPartnerConfigScreen()),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: AppColors.card2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grayDim, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String icon, String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _aulaCard(dynamic h, List ags, AppState state) {
    final pres = state.presencasHoje().where((p) => p.horarioId == h.id).length;
    final pct = ags.isEmpty ? 0.0 : ags.length / h.capacidade * 100;
    final barC = pct >= 90 ? AppColors.red : pct >= 60 ? AppColors.yellow : AppColors.neon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PulguinhaCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(h.hora, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neon)),
                const SizedBox(width: 8),
                Expanded(child: Text(h.dias, style: const TextStyle(fontSize: 11, color: AppColors.gray), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (pres > 0) PulguinhaBadge(label: '✅ $pres', variant: BadgeVariant.neon),
                const SizedBox(width: 6),
                Text('${ags.length}/${h.capacidade}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: (pct / 100).clamp(0.0, 1.0), minHeight: 3, backgroundColor: AppColors.card2, color: barC),
            ),
            const SizedBox(height: 8),
            if (ags.isEmpty)
              const Text('Nenhum aluno agendado', style: TextStyle(fontSize: 12, color: AppColors.grayDim))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ags.take(12).map<Widget>((ag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
