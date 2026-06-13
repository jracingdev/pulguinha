import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class SobreAppScreen extends StatefulWidget {
  const SobreAppScreen({super.key});

  @override
  State<SobreAppScreen> createState() => _SobreAppScreenState();
}

class _SobreAppScreenState extends State<SobreAppScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const PulguinhaLogo(size: 88, borderRadius: 22),
                const SizedBox(height: 16),
                const Text(
                  'Funcional do Pulguinha',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Versão $_version (build $_buildNumber)',
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
                  'Inclui check-in por QR, controle de presença, planos, loja com Mercado Pago, '
                  'anamnese e gamificação com Pulguinha Points.',
                  style: TextStyle(fontSize: 13, color: AppColors.white, height: 1.5),
                ),
              ],
            ),
          ),
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
        ],
      ),
    );
  }
}
