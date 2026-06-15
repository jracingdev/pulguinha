import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulguinha/config/mercado_pago_config.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMpConfigScreen extends StatelessWidget {
  const AdminMpConfigScreen({super.key});

  Future<void> _copyToClipboard(BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado')),
    );
  }

  Future<void> _openMpDevelopers() async {
    final uri = Uri.parse('https://www.mercadopago.com.br/developers/panel/app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mercado Pago'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionAccessToken(context),
            const SizedBox(height: 20),
            _sectionCurrentStatus(),
          ],
        ),
      ),
    );
  }

  Widget _sectionAccessToken(BuildContext context) {
    return PulguinhaCard(
      borderColor: AppColors.red.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🔐', title: 'Access Token (SECRETO)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'O Access Token NUNCA deve ficar no app ou no navegador.\n'
              'Configure em um destes locais:',
              style: TextStyle(fontSize: 12, color: AppColors.white, height: 1.5, fontWeight: FontWeight.w600, decoration: TextDecoration.none),
            ),
          ),
          const SizedBox(height: 14),
          _secretStep(
            context,
            number: '1',
            title: 'Supabase (recomendado)',
            lines: const [
              'Project Settings → Edge Functions → Secrets',
              'Nome: MP_ACCESS_TOKEN',
              'Deploy: supabase/functions/create-mp-preference',
            ],
            copyText: 'MP_ACCESS_TOKEN',
          ),
          const SizedBox(height: 12),
          _secretStep(
            context,
            number: '2',
            title: 'GitHub Actions (deploy web)',
            lines: const [
              'Repository → Settings → Secrets → Actions',
              'MP_ACCESS_TOKEN',
            ],
            copyText: 'MP_ACCESS_TOKEN',
          ),
          const SizedBox(height: 12),
          _secretStep(
            context,
            number: '3',
            title: 'Desenvolvimento local',
            lines: const [
              'supabase secrets set MP_ACCESS_TOKEN=APP_USR-...',
            ],
            copyText: 'supabase secrets set MP_ACCESS_TOKEN=APP_USR-...',
          ),
        ],
      ),
    );
  }

  Widget _secretStep(
    BuildContext context, {
    required String number,
    required String title,
    required List<String> lines,
    required String copyText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mercadoPago.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.mercadoPago, decoration: TextDecoration.none)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.white, decoration: TextDecoration.none)),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(context, copyText, 'Comando/nome'),
                icon: const Icon(Icons.copy, size: 16, color: AppColors.mercadoPago),
                label: const Text('Copiar', style: TextStyle(fontSize: 11, color: AppColors.mercadoPago)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 2),
              child: Text('→ $line', style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.4, decoration: TextDecoration.none)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCurrentStatus() {
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '📊', title: 'Status atual'),
          _statusRow('Modo de checkout', MercadoPagoConfig.checkoutModeLabel()),
          _statusRow('Chave pública', MercadoPagoConfig.hasPublicKey ? 'Configurada' : 'Não configurada'),
          _statusRow('Links de planos', MercadoPagoConfig.hasStaticPaymentLinks ? 'Ativos' : 'Nenhum'),
          _statusRow(
            'Edge Function',
            SupabaseConfig.isConfigured ? 'Supabase conectado' : 'Supabase não configurado',
          ),
          _statusRow('Access Token', 'Somente no servidor (secret)'),
          const SizedBox(height: 12),
          GhostButton(
            label: '🌐 Abrir painel Mercado Pago Developers',
            onPressed: _openMpDevelopers,
            fullWidth: true,
            borderColor: AppColors.mercadoPago.withValues(alpha: 0.3),
            textColor: AppColors.mercadoPago,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.none)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }
}
