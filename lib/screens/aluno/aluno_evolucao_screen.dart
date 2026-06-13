import 'package:flutter/material.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/wellness_widgets.dart';

class AlunoEvolucaoScreen extends StatefulWidget {
  const AlunoEvolucaoScreen({super.key});

  @override
  State<AlunoEvolucaoScreen> createState() => _AlunoEvolucaoScreenState();
}

class _AlunoEvolucaoScreenState extends State<AlunoEvolucaoScreen> {
  int _section = 0;

  static const _sections = [
    ('💧', 'Água'),
    ('📊', 'IMC'),
    ('🏋️', 'Dicas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evolução',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hidratação, IMC e dicas para evoluir no funcional',
          style: TextStyle(fontSize: 12, color: AppColors.gray),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(_sections.length, (i) {
            final (icon, label) = _sections[i];
            final active = _section == i;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _sections.length - 1 ? 8 : 0),
                child: InkWell(
                  onTap: () => setState(() => _section = i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.neon.withValues(alpha: 0.12) : AppColors.card2,
                      border: Border.all(color: active ? AppColors.neon.withValues(alpha: 0.4) : AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(icon, style: TextStyle(fontSize: 18, shadows: active ? [Shadow(color: AppColors.neon.withValues(alpha: 0.6), blurRadius: 4)] : null)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                            color: active ? AppColors.neon : AppColors.grayDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        switch (_section) {
          0 => const MegaAguaCard(),
          1 => const ImcCalculatorWidget(),
          2 => const TrainingTipsList(),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}
