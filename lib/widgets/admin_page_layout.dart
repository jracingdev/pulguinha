import 'package:flutter/material.dart';
import 'package:pulguinha/theme/app_colors.dart';

/// Cabeçalho padrão para telas admin (dentro do AppShell ou em rota própria).
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white, decoration: TextDecoration.none),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.35, decoration: TextDecoration.none),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            _CompactActionButton(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neon,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111111), decoration: TextDecoration.none),
          ),
        ),
      ),
    );
  }
}

/// Tela admin aberta via Navigator (com AppBar e SafeArea).
class AdminStandalonePage extends StatelessWidget {
  const AdminStandalonePage({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          if (actionLabel != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CompactActionButton(label: actionLabel!, onPressed: onAction!),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.35, decoration: TextDecoration.none)),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Conteúdo admin dentro do AppShell (sem AppBar duplicada).
class AdminTabPage extends StatelessWidget {
  const AdminTabPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminPageHeader(title: title, subtitle: subtitle, actionLabel: actionLabel, onAction: onAction),
        ...children,
      ],
    );
  }
}
