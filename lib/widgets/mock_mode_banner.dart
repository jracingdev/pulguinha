import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

/// Aviso visível quando o app está offline / sem Supabase — cadastros não sincronizam.
class MockModeBanner extends StatelessWidget {
  const MockModeBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.useMock) return const SizedBox.shrink();

    final semConfig = !SupabaseConfig.isConfigured;
    final texto = semConfig
        ? '⚠️ Cadastros não sincronizam — servidor não configurado. No site: configure os secrets SUPABASE_URL e SUPABASE_ANON_KEY no GitHub. No app admin: Configurações → Conexão Supabase.'
        : '⚠️ Cadastros não sincronizam — sem conexão com o banco. Verifique a internet ou as credenciais em Configurações → Conexão Supabase.';

    if (compact) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.yellow.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Cadastros não sincronizam (modo offline)',
          style: const TextStyle(fontSize: 11, color: AppColors.yellow, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PulguinhaCard(
        borderColor: AppColors.yellow.withValues(alpha: 0.35),
        backgroundColor: AppColors.yellow.withValues(alpha: 0.06),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 11, color: AppColors.yellow, height: 1.45, decoration: TextDecoration.none),
        ),
      ),
    );
  }
}
