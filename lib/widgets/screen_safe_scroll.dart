import 'package:flutter/material.dart';

/// Scroll com SafeArea e padding inferior para botões não ficarem cortados.
class ScreenSafeScroll extends StatelessWidget {
  const ScreenSafeScroll({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.bottomExtra = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final double bottomExtra;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: padding.copyWith(bottom: padding.bottom + bottom + bottomExtra),
        child: child,
      ),
    );
  }
}
