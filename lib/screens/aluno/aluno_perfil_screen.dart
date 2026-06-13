import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AlunoPerfilScreen extends StatelessWidget {
  const AlunoPerfilScreen({super.key, required this.usuario, required this.onLogout});

  final Usuario usuario;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final aluno = state.alunoPorId(usuario.id) ?? Aluno(
      id: usuario.id ?? 0,
      nome: usuario.nome,
      email: usuario.email,
      senha: '',
      telefone: usuario.telefone ?? '',
      plano: usuario.plano ?? 'Mensal',
      vencimento: usuario.vencimento ?? MockData.today,
      status: usuario.status ?? 'Ativo',
      avatar: usuario.avatar ?? 'AL',
    );
    final d = DateHelper.diasAteVencimento(aluno.vencimento);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MEU PERFIL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 20),
        PulguinhaCard(
          child: Column(
            children: [
              PulguinhaAvatar(initials: aluno.avatar, size: AvatarSize.lg),
              const SizedBox(height: 12),
              Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.white)),
              Text(aluno.email, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
              Text(aluno.telefone, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
              const SizedBox(height: 12),
              PulguinhaBadge(label: aluno.status, variant: aluno.status == 'Ativo' ? BadgeVariant.neon : BadgeVariant.red),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: '📅', title: 'Meu Plano'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _infoBox('Plano', aluno.plano),
                  _infoBox('Status', aluno.status),
                  _infoBox('Vencimento', DateHelper.formatarData(aluno.vencimento)),
                  _infoBox('Dias restantes', d < 0 ? '${d.abs()}d atrasado' : d == 0 ? 'Hoje!' : '${d}d', highlight: d < 0),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: '🔐', title: 'Segurança'),
              _securityItem(context, '🔑', 'Biometria / Face ID', 'Entrar sem senha', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometria disponível na tela de login após marcar "Lembrar".')),
                );
              }),
              const SizedBox(height: 8),
              _securityItem(context, '🔒', 'Alterar senha', 'Atualizar credenciais', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alteração de senha em breve.')),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DangerButton(label: '🚪 Sair da conta', fullWidth: true, onPressed: onLogout),
      ],
    );
  }

  Widget _infoBox(String label, String val, {bool highlight = false}) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w700)),
            Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: highlight ? AppColors.red : AppColors.neon)),
          ],
        ),
      ),
    );
  }

  Widget _securityItem(BuildContext context, String icon, String label, String sub, VoidCallback onTap) {
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
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grayDim),
          ],
        ),
      ),
    );
  }
}
