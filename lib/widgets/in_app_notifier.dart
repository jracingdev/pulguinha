import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulguinha/theme/app_colors.dart';
/// Banner in-app no topo + callback opcional de som (SystemSound).
class InAppNotifier {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    Color color = AppColors.neon,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
  }) {
    hide();
    if (playSound) {
      SystemSound.play(SystemSoundType.alert);
    }

    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 8,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: color.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12)],
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
                      Text(message, style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.3)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.gray),
                  onPressed: hide,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    Future.delayed(duration, hide);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
