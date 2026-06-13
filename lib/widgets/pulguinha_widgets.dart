import 'package:flutter/material.dart';
import 'package:pulguinha/theme/app_colors.dart';

enum BadgeVariant { neon, red, yellow, gray, blue, mercadoPago }

class PulguinhaAvatar extends StatelessWidget {
  const PulguinhaAvatar({
    super.key,
    required this.initials,
    this.size = AvatarSize.md,
  });

  final String initials;
  final AvatarSize size;

  @override
  Widget build(BuildContext context) {
    final dim = switch (size) {
      AvatarSize.sm => 30.0,
      AvatarSize.md => 40.0,
      AvatarSize.lg => 52.0,
    };
    final fontSize = switch (size) {
      AvatarSize.sm => 10.0,
      AvatarSize.md => 13.0,
      AvatarSize.lg => 16.0,
    };

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: AppColors.neon.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.neon.withValues(alpha: 0.35), width: 1.5),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w900, fontSize: fontSize),
      ),
    );
  }
}

enum AvatarSize { sm, md, lg }

class PulguinhaBadge extends StatelessWidget {
  const PulguinhaBadge({super.key, required this.label, this.variant = BadgeVariant.neon});

  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, color, border) = switch (variant) {
      BadgeVariant.neon => (AppColors.neon.withValues(alpha: 0.12), AppColors.neon, AppColors.neon.withValues(alpha: 0.3)),
      BadgeVariant.red => (AppColors.red.withValues(alpha: 0.12), AppColors.red, AppColors.red.withValues(alpha: 0.3)),
      BadgeVariant.yellow => (AppColors.yellow.withValues(alpha: 0.12), AppColors.yellow, AppColors.yellow.withValues(alpha: 0.3)),
      BadgeVariant.gray => (Colors.white.withValues(alpha: 0.06), AppColors.gray, AppColors.border),
      BadgeVariant.blue => (AppColors.blue.withValues(alpha: 0.12), AppColors.blue, AppColors.blue.withValues(alpha: 0.3)),
      BadgeVariant.mercadoPago => (AppColors.mercadoPago.withValues(alpha: 0.12), AppColors.mercadoPago, AppColors.mercadoPago.withValues(alpha: 0.3)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class PulguinhaCard extends StatelessWidget {
  const PulguinhaCard({super.key, required this.child, this.borderColor, this.backgroundColor, this.padding});

  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        border: Border.all(color: borderColor ?? AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, this.icon, required this.title});

  final String? icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(color: AppColors.neon)),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gray, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, required this.child});

  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label!.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.neon,
          foregroundColor: textColor ?? const Color(0xFF111111),
          disabledBackgroundColor: AppColors.card2,
          disabledForegroundColor: AppColors.gray,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
    this.borderColor,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color? borderColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.gray,
          side: BorderSide(color: borderColor ?? AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed, this.fullWidth = false});

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          backgroundColor: AppColors.red.withValues(alpha: 0.12),
          side: BorderSide(color: AppColors.red.withValues(alpha: 0.25)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

Future<T?> showPulguinhaModal<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.white)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: AppColors.gray, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card2,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(28, 28),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    ),
  );
}
