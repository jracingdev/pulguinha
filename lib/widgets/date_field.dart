import 'package:flutter/material.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';

/// Campo de data com calendário nativo (pt_BR).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.controller,
    this.hintText,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? hintText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final now = DateTime.now();
    final initial = controller.text.trim().isEmpty
        ? now
        : DateHelper.parseData(DateHelper.paraIso(controller.text.trim()));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(1920),
      lastDate: lastDate ?? DateTime(now.year + 5, 12, 31),
      locale: const Locale('pt', 'BR'),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neon,
              onPrimary: Color(0xFF111111),
              surface: AppColors.card,
              onSurface: AppColors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.card),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    final formatted = DateHelper.formatarData(DateHelper.paraIso(
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
    ));
    controller.text = formatted;
    onChanged?.call(DateHelper.paraIso(formatted));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      onTap: () => _pick(context),
      decoration: InputDecoration(
        hintText: hintText ?? 'Toque para escolher',
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, size: 18, color: AppColors.neon),
          onPressed: enabled ? () => _pick(context) : null,
        ),
      ),
    );
  }
}
