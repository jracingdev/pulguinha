import 'package:flutter/material.dart';
import 'package:pulguinha/config/app_links.dart';
import 'package:pulguinha/data/legal_content.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

enum LegalDocType { termos, privacidade }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.type});

  final LegalDocType type;

  Future<void> _openOnline() async {
    final url = type == LegalDocType.termos ? AppLinks.termsOfUseUrl : AppLinks.privacyPolicyUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTermos = type == LegalDocType.termos;
    final title = isTermos ? LegalContent.termosTitulo : LegalContent.privacidadeTitulo;
    final body = isTermos ? LegalContent.termos : LegalContent.privacidade;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PulguinhaCard(
            child: Text(
              body,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _openOnline,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver online'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neon,
                side: BorderSide(color: AppColors.neon.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Desenvolvido por jracing.dev.br',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.gray.withValues(alpha: 0.8)),
          ),
        ],
      ),
      ),
    );
  }
}

/// Checkbox + links para termos na tela de cadastro.
class TermosAceiteWidget extends StatelessWidget {
  const TermosAceiteWidget({
    super.key,
    required this.aceito,
    required this.onChanged,
  });

  final bool aceito;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!aceito),
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: aceito ? AppColors.neon : AppColors.card2,
              border: Border.all(color: aceito ? AppColors.neon : AppColors.border, width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: aceito ? const Text('✓', style: TextStyle(fontSize: 12, color: Color(0xFF111111))) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            children: [
              GestureDetector(
                onTap: () => onChanged(!aceito),
                child: const Text('Li e aceito os ', style: TextStyle(fontSize: 12, color: AppColors.gray)),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.termos))),
                child: const Text('Termos de Uso', style: TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w700)),
              ),
              const Text(' e a ', style: TextStyle(fontSize: 12, color: AppColors.gray)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LegalScreen(type: LegalDocType.privacidade))),
                child: const Text('Política de Privacidade', style: TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w700)),
              ),
              const Text('.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
            ],
          ),
        ),
      ],
    );
  }
}
