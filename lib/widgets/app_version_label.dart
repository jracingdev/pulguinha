import 'package:flutter/material.dart';
import 'package:pulguinha/services/app_version_service.dart';
import 'package:pulguinha/theme/app_colors.dart';

/// Rótulo discreto da versão do app (pubspec.yaml).
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppVersionService.label,
      style: style ??
          const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.grayDim,
            decoration: TextDecoration.none,
          ),
    );
  }
}
