import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pulguinha/theme/app_colors.dart';

class PulguinhaLogo extends StatelessWidget {
  const PulguinhaLogo({
    super.key,
    this.size = 128,
    this.showShadow = true,
    this.borderRadius = 18,
  });

  final double size;
  final bool showShadow;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.neon.withValues(alpha: 0.18),
                  blurRadius: size * 0.12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/images/logo1.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.neon,
            alignment: Alignment.center,
            child: Text('P', style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w900, color: const Color(0xFF111111))),
          ),
        ),
      ),
    );
  }
}

Future<void> showEmDesenvolvimentoDialog(BuildContext context, {required String titulo, String? mensagem}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      title: Text(titulo, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      content: Text(
        mensagem ?? 'Esta funcionalidade estará disponível em uma próxima atualização.',
        style: const TextStyle(color: AppColors.gray, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendi', style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

enum BadgeVariant { neon, red, yellow, gray, blue, mercadoPago }

class PulguinhaAvatar extends StatelessWidget {
  const PulguinhaAvatar({
    super.key,
    required this.initials,
    this.size = AvatarSize.md,
    this.fotoBase64,
  });

  final String initials;
  final AvatarSize size;
  final String? fotoBase64;

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

    ImageProvider? imageProvider;
    if (fotoBase64 != null && fotoBase64!.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(fotoBase64!.contains(',') ? fotoBase64!.split(',').last : fotoBase64!));
      } catch (_) {}
    }

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: AppColors.neon.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.neon.withValues(alpha: 0.35), width: 1.5),
        shape: BoxShape.circle,
        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: imageProvider == null
          ? Text(
              initials,
              style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w900, fontSize: fontSize),
            )
          : null,
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

enum HorarioOccupancy { available, almostFull, full }

HorarioOccupancy horarioOccupancy(int ocupados, int capacidade) {
  if (ocupados >= capacidade) return HorarioOccupancy.full;
  if (ocupados / capacidade >= 0.75) return HorarioOccupancy.almostFull;
  return HorarioOccupancy.available;
}

Color horarioBarColor(int ocupados, int capacidade) {
  final pct = capacidade > 0 ? ocupados / capacidade : 0.0;
  if (pct >= 1) return AppColors.red;
  if (pct >= 0.75) return AppColors.yellow;
  return AppColors.neon;
}

BadgeVariant horarioBadgeVariant(HorarioOccupancy level) {
  return switch (level) {
    HorarioOccupancy.full => BadgeVariant.red,
    HorarioOccupancy.almostFull => BadgeVariant.yellow,
    HorarioOccupancy.available => BadgeVariant.neon,
  };
}

String horarioBadgeLabel(HorarioOccupancy level, int vagasRestantes) {
  return switch (level) {
    HorarioOccupancy.full => 'LOTADO',
    HorarioOccupancy.almostFull => '$vagasRestantes vagas',
    HorarioOccupancy.available => '$vagasRestantes vagas',
  };
}

class HorarioGrid extends StatelessWidget {
  const HorarioGrid({super.key, required this.children, this.spacing = 8});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawMax = constraints.maxWidth;
        final maxW = rawMax.isFinite && rawMax > 0
            ? rawMax
            : MediaQuery.sizeOf(context).width;
        final cols = maxW < 280 ? 1 : 2;
        final double itemWidth = (cols == 1 ? maxW : (maxW - spacing) / 2).clamp(0.0, double.infinity);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) => SizedBox(width: itemWidth, child: child)).toList(),
        );
      },
    );
  }
}

class HorarioOccupancyBar extends StatelessWidget {
  const HorarioOccupancyBar({super.key, required this.ocupados, required this.capacidade});

  final int ocupados;
  final int capacidade;

  @override
  Widget build(BuildContext context) {
    final pct = capacidade > 0 ? (ocupados / capacidade).clamp(0.0, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 3,
        backgroundColor: AppColors.card2,
        color: horarioBarColor(ocupados, capacidade),
      ),
    );
  }
}

class HorarioSlotCard extends StatefulWidget {
  const HorarioSlotCard({
    super.key,
    required this.hora,
    required this.ocupados,
    required this.capacidade,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.subtitle,
    this.footer,
    this.showProgress = true,
    this.showBadge = true,
  });

  final String hora;
  final int ocupados;
  final int capacidade;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? footer;
  final bool showProgress;
  final bool showBadge;

  @override
  State<HorarioSlotCard> createState() => _HorarioSlotCardState();
}

class _HorarioSlotCardState extends State<HorarioSlotCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final level = horarioOccupancy(widget.ocupados, widget.capacidade);
    final lotado = level == HorarioOccupancy.full;
    final vagas = widget.capacidade - widget.ocupados;
    final borderColor = widget.selected
        ? AppColors.neon
        : lotado
            ? AppColors.red.withValues(alpha: 0.25)
            : AppColors.border;

    return GestureDetector(
      onTapDown: widget.enabled && widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled && widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.neon.withValues(alpha: 0.12) : AppColors.card2,
            border: Border.all(color: borderColor, width: widget.selected ? 2 : 1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.selected
                ? [BoxShadow(color: AppColors.neon.withValues(alpha: 0.15), blurRadius: 8)]
                : null,
          ),
          child: Opacity(
            opacity: lotado && !widget.selected ? 0.55 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.hora,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: widget.selected ? AppColors.neon : AppColors.white,
                        ),
                      ),
                    ),
                    if (widget.showBadge)
                      PulguinhaBadge(
                        label: horarioBadgeLabel(level, vagas.clamp(0, widget.capacidade)),
                        variant: horarioBadgeVariant(level),
                      ),
                  ],
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(widget.subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
                const SizedBox(height: 4),
                Text(
                  '${widget.ocupados}/${widget.capacidade} ${lotado ? "LOTADO" : "ocupadas"}',
                  style: TextStyle(fontSize: 11, color: lotado ? AppColors.red : AppColors.gray),
                ),
                if (widget.showProgress) ...[
                  const SizedBox(height: 6),
                  HorarioOccupancyBar(ocupados: widget.ocupados, capacidade: widget.capacidade),
                ],
                if (widget.footer != null) ...[
                  const SizedBox(height: 6),
                  widget.footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HorarioInfoCard extends StatefulWidget {
  const HorarioInfoCard({
    super.key,
    required this.hora,
    required this.dias,
    required this.capacidade,
    required this.ocupadosHoje,
    this.onTap,
  });

  final String hora;
  final String dias;
  final int capacidade;
  final int ocupadosHoje;
  final VoidCallback? onTap;

  @override
  State<HorarioInfoCard> createState() => _HorarioInfoCardState();
}

class _HorarioInfoCardState extends State<HorarioInfoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final level = horarioOccupancy(widget.ocupadosHoje, widget.capacidade);
    final vagas = (widget.capacidade - widget.ocupadosHoje).clamp(0, widget.capacidade);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card2,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.hora, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neon, fontSize: 15)),
                  ),
                  PulguinhaBadge(label: horarioBadgeLabel(level, vagas), variant: horarioBadgeVariant(level)),
                ],
              ),
              Text(widget.dias, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
              Text('até ${widget.capacidade} alunos', style: const TextStyle(fontSize: 10, color: AppColors.grayDim, height: 1.6)),
              const SizedBox(height: 6),
              HorarioOccupancyBar(ocupados: widget.ocupadosHoje, capacidade: widget.capacidade),
            ],
          ),
        ),
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
