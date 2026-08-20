import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulguinha/data/studio_info.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card institucional: professor, CREF, Instagram, WhatsApp e CNPJ/PIX.
class StudioContactCard extends StatelessWidget {
  const StudioContactCard({super.key, this.compact = false});

  final bool compact;

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copiar(BuildContext context, String texto, String msg) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return PulguinhaCard(
      borderColor: AppColors.neon.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '🏋️', title: 'Funcional do Pulguinha'),
          Text(
            StudioInfo.professor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'CREF ${StudioInfo.cref}',
            style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          _linha(
            context,
            asset: 'assets/icons/instagram.svg',
            titulo: 'Instagram',
            valor: StudioInfo.instagramHandle,
            onTap: () => _open(Uri.parse(StudioInfo.instagramUrl)),
          ),
          const SizedBox(height: 8),
          _linha(
            context,
            asset: 'assets/icons/whatsapp.svg',
            titulo: 'WhatsApp',
            valor: StudioInfo.whatsappDisplay,
            onTap: () => _open(Uri.parse(StudioInfo.whatsappUrl)),
          ),
          const SizedBox(height: 8),
          _linha(
            context,
            asset: 'assets/icons/pix.svg',
            titulo: 'CNPJ (PIX)',
            valor: StudioInfo.cnpj,
            onTap: () => _copiar(context, StudioInfo.cnpjDigits, 'CNPJ copiado para colar no PIX'),
            trailing: const Icon(Icons.copy_rounded, size: 16, color: AppColors.grayDim),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neon.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FUNCIONAL DO PULGUINHA',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gray, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            '${StudioInfo.professor} · CREF ${StudioInfo.cref}',
            style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _chip(
                  context,
                  asset: 'assets/icons/instagram.svg',
                  label: 'Instagram',
                  onTap: () => _open(Uri.parse(StudioInfo.instagramUrl)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _chip(
                  context,
                  asset: 'assets/icons/whatsapp.svg',
                  label: 'WhatsApp',
                  onTap: () => _open(Uri.parse(StudioInfo.whatsappUrl)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _chip(
                  context,
                  asset: 'assets/icons/pix.svg',
                  label: 'PIX',
                  onTap: () => _copiar(context, StudioInfo.cnpjDigits, 'CNPJ copiado para colar no PIX'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String asset,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              SvgPicture.asset(asset, width: 20, height: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linha(
    BuildContext context, {
    required String asset,
    required String titulo,
    required String valor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            SvgPicture.asset(asset, width: 28, height: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w700)),
                  Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.open_in_new, size: 16, color: AppColors.grayDim),
          ],
        ),
      ),
    );
  }
}
