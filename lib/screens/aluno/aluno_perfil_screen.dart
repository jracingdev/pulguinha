import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/screens/shared/legal_screen.dart';
import 'package:pulguinha/screens/shared/sobre_app_screen.dart';
import 'package:pulguinha/utils/photo_picker_helper.dart';
import 'package:pulguinha/widgets/theme_settings_tile.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/utils/qr_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:pulguinha/utils/vencimento_helper.dart';
import 'package:pulguinha/widgets/qr_widgets.dart';

class AlunoPerfilScreen extends StatelessWidget {
  const AlunoPerfilScreen({super.key, required this.usuario, required this.onLogout});

  final Usuario usuario;
  final VoidCallback onLogout;

  Future<void> _pickPhoto(BuildContext context, AppState state, int alunoId) async {
    final base64 = await pickPhotoBase64(context);
    if (base64 == null) return;
    state.atualizarFotoAluno(alunoId, base64);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada!'), behavior: SnackBarBehavior.floating),
      );
    }
  }

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
    final d = VencimentoHelper.temPlanoAtivo(aluno) ? DateHelper.diasAteVencimento(aluno.vencimento) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MEU PERFIL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 20),
        PulguinhaCard(
          child: Column(
            children: [
              Stack(
                children: [
                  PulguinhaAvatar(initials: aluno.avatar, size: AvatarSize.lg, fotoBase64: aluno.foto),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _pickPhoto(context, state, aluno.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.neon, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF111111)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.white)),
              Text(aluno.email, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
              Text(aluno.telefone, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
              if (aluno.dataNascimento != null)
                Text('🎂 ${DateHelper.formatarAniversario(aluno.dataNascimento!)}', style: const TextStyle(fontSize: 12, color: AppColors.yellow)),
              if (aluno.alunoDesde != null && aluno.alunoDesde!.isNotEmpty)
                Text('🏋️ Aluno desde ${DateHelper.formatarData(aluno.alunoDesde!)}', style: const TextStyle(fontSize: 12, color: AppColors.neon)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PulguinhaBadge(label: aluno.status, variant: aluno.status == 'Ativo' ? BadgeVariant.neon : BadgeVariant.red),
                  if (aluno.streakPresenca >= 2) ...[
                    const SizedBox(width: 8),
                    PulguinhaBadge(label: '🔥 ${aluno.streakPresenca}', variant: BadgeVariant.yellow),
                  ],
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
              const SectionTitle(icon: '📅', title: 'Meu Plano'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _infoBox('Plano', aluno.plano),
                  _infoBox('Status', aluno.status),
                  if (VencimentoHelper.temPlanoAtivo(aluno)) ...[
                    _infoBox('Vencimento', DateHelper.formatarData(aluno.vencimento)),
                    _infoBox('Dias restantes', d < 0 ? '${d.abs()}d atrasado' : d == 0 ? 'Hoje!' : '${d}d', highlight: d < 0),
                  ] else
                    _infoBox('Mensalidade', 'Aguardando aprovação'),
                  if (aluno.alunoDesde != null && aluno.alunoDesde!.isNotEmpty)
                    _infoBox('Aluno desde', DateHelper.formatarData(aluno.alunoDesde!)),
                  if (aluno.pulguinhaPoints > 0) _infoBox('Points', '${aluno.pulguinhaPoints} ⭐'),
                ],
              ),
            ],
          ),
        ),
        if (!aluno.anamnese.isEmpty) ...[
          const SizedBox(height: 16),
          PulguinhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(icon: '🏥', title: 'Anamnese'),
                if (aluno.anamnese.objetivoTreino.isNotEmpty) _anamneseRow('Objetivo', aluno.anamnese.objetivoTreino),
                if (aluno.anamnese.nivelExperiencia.isNotEmpty) _anamneseRow('Nível', aluno.anamnese.nivelExperiencia),
                if (aluno.anamnese.restricoesMedicas.isNotEmpty) _anamneseRow('Restrições', aluno.anamnese.restricoesMedicas),
                if (aluno.anamnese.medicamentos.isNotEmpty) _anamneseRow('Medicamentos', aluno.anamnese.medicamentos),
                if (aluno.anamnese.contatoEmergencia.isNotEmpty)
                  _anamneseRow('Emergência', '${aluno.anamnese.contatoEmergencia} · ${aluno.anamnese.telefoneEmergencia}'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('QR de backup (opcional)', style: TextStyle(fontSize: 12, color: AppColors.grayDim, fontWeight: FontWeight.w600)),
          children: [
            QrDisplayCard(
              data: QrHelper.payloadAluno(aluno.id),
              titulo: 'Meu QR (backup)',
              subtitulo: 'Use apenas se o check-in da aula falhar',
            ),
          ],
        ),
        const SizedBox(height: 16),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: '⚙️', title: 'Configurações'),
              const SizedBox(height: 8),
              const ThemeSettingsTile(),
              const SizedBox(height: 10),
              _settingsItem(context, 'ℹ️', 'Sobre o app', 'Versão, desenvolvedor e informações', () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SobreAppScreen()));
              }),
              const SizedBox(height: 8),
              _settingsItem(context, '📄', 'Termos de Uso', 'Leia os termos do serviço', () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.termos)));
              }),
              const SizedBox(height: 8),
              _settingsItem(context, '🔒', 'Política de Privacidade', 'Como tratamos seus dados', () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.privacidade)));
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: '🔐', title: 'Segurança'),
              _securityItem(context, '🔒', 'Alterar senha', 'Em breve via Supabase Auth', () {
                showEmDesenvolvimentoDialog(context, titulo: 'Alterar senha', mensagem: 'Disponível quando Supabase Auth for configurado.');
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

  Widget _anamneseRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w700))),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 12, color: AppColors.white))),
        ],
      ),
    );
  }

  Widget _settingsItem(BuildContext context, String icon, String label, String sub, VoidCallback onTap) {
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
