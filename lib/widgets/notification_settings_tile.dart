import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/providers/app_state.dart';import 'package:pulguinha/theme/app_colors.dart';

class NotificationSettingsTile extends StatelessWidget {
  const NotificationSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.notificationSettings;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card2,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notificações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.white)),
          const SizedBox(height: 4),
          const Text('Lembretes locais no celular (push FCM em breve)', style: TextStyle(fontSize: 11, color: AppColors.gray)),
          const SizedBox(height: 10),
          _switch(context, state, 'Ativadas', s.enabled, (v) => state.setNotificationSettings(s.copyWith(enabled: v))),
          _switch(context, state, 'Som', s.sound, (v) => state.setNotificationSettings(s.copyWith(sound: v))),
          _switch(context, state, 'Lembrete de aula', s.lembreteAula, (v) => state.setNotificationSettings(s.copyWith(lembreteAula: v))),
          _switch(context, state, 'Vencimento', s.lembreteVencimento, (v) => state.setNotificationSettings(s.copyWith(lembreteVencimento: v))),
          _switch(context, state, 'Avisos e eventos', s.comunicacao, (v) => state.setNotificationSettings(s.copyWith(comunicacao: v))),
        ],
      ),
    );
  }

  Widget _switch(BuildContext context, AppState state, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray))),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.neon),
      ],
    );
  }
}
