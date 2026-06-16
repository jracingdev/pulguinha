import 'package:flutter/material.dart';
import 'package:pulguinha/screens/shared/legal_screen.dart';
import 'package:pulguinha/services/app_version_service.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:pulguinha/widgets/studio_contact_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SobreAppScreen extends StatelessWidget {
  const SobreAppScreen({super.key});

  Future<void> _openDeveloperSite() async {
    final uri = Uri.parse('https://jracing.dev.br');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sobre o app'),
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const PulguinhaLogo(size: 176, borderRadius: 28),
                const SizedBox(height: 16),
                const Text(
                  'Funcional do Pulguinha',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Versão ${AppVersionService.version} (build ${AppVersionService.buildNumber})',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PulguinhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(icon: '🏋️', title: 'Sobre'),
                const Text(
                  'App de gestão e agendamento para o estúdio Funcional do Pulguinha. '
                  'Inclui check-in por QR, controle de presença, planos, loja com Mercado Pago e PagBank, '
                  'anamnese e gamificação com Pulguinha Points.',
                  style: TextStyle(fontSize: 13, color: AppColors.white, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const StudioContactCard(),
          const SizedBox(height: 16),
          PulguinhaCard(
            child: InkWell(
              onTap: _openDeveloperSite,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.neon.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.code, color: AppColors.neon),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Desenvolvedor', style: TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w700)),
                        Text('jracing.dev.br', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.neon)),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new, color: AppColors.grayDim, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PulguinhaCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('📄', style: TextStyle(fontSize: 22)),
                  title: const Text('Termos de Uso', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.grayDim),
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.termos))),
                ),
                const Divider(height: 1, color: AppColors.card2),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🔒', style: TextStyle(fontSize: 22)),
                  title: const Text('Política de Privacidade', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.grayDim),
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.privacidade))),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
