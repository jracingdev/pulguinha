import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';

class ThemeSettingsTile extends StatelessWidget {
  const ThemeSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card2,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Modo escuro' : 'Modo claro',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white),
                ),
                Text(
                  isDark ? 'Tema neon escuro (padrão)' : 'Fundo claro com detalhes neon',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            onChanged: (_) => state.toggleThemeMode(),
          ),
        ],
      ),
    );
  }
}
