import 'package:flutter/material.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class TabItem {
  const TabItem({required this.id, required this.label, required this.icon});

  final String id;
  final String label;
  final String icon;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabChanged,
    required this.child,
    this.headerRight,
    this.onLogout,
  });

  final List<TabItem> tabs;
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final Widget child;
  final Widget? headerRight;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const PulguinhaLogo(size: 32, borderRadius: 8, showShadow: false),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FUNCIONAL DO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 1.5)),
                      Text('PULGUINHA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.neon, letterSpacing: 1)),
                    ],
                  ),
                  const Spacer(),
                  if (headerRight != null) headerRight!,
                  if (headerRight != null) const SizedBox(width: 8),
                  if (onLogout != null)
                    OutlinedButton(
                      onPressed: onLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        backgroundColor: AppColors.red.withValues(alpha: 0.1),
                        side: BorderSide(color: AppColors.red.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Sair', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
            child: Row(
              children: tabs.map((t) {
                final active = activeTab == t.id;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTabChanged(t.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.icon, style: TextStyle(fontSize: 18, shadows: active ? [Shadow(color: AppColors.neon.withValues(alpha: 0.8), blurRadius: 5)] : null)),
                          const SizedBox(height: 2),
                          Text(
                            t.label,
                            style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w900 : FontWeight.w600, color: active ? AppColors.neon : AppColors.grayDim, letterSpacing: 0.5),
                          ),
                          if (active)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(color: AppColors.neon, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.8), blurRadius: 6)]),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
