import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

/// Aviso visível quando o app está offline / sem Supabase — cadastros não sincronizam.
class MockModeBanner extends StatelessWidget {
  const MockModeBanner({super.key, this.compact = false, this.adminOnly = false});

  final bool compact;
  final bool adminOnly;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.useMock) return const SizedBox.shrink();
    if (adminOnly && !SupabaseConfig.isConfigured) {
      // Em telas públicas/aluno sem config, o banner confunde — mensagem fica no erro de login.
      return const SizedBox.shrink();
    }

    final semConexao = SupabaseConfig.isConfigured;
    final texto = semConexao
        ? 'ℹ️ Sem conexão com o banco no momento. Verifique a internet e puxe a tela para atualizar.'
        : 'ℹ️ Modo local — credenciais Supabase não encontradas. Reinstale o APK oficial ou configure em Configurações → Conexão Supabase (avançado).';

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
          semConexao
              ? 'Sem conexão — verifique internet'
              : 'Modo local — reinstale APK ou configure Supabase',
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
