import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pulguinha/data/training_tips.dart';
import 'package:pulguinha/services/wellness_service.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class WaterProgressRing extends StatelessWidget {
  const WaterProgressRing({
    super.key,
    required this.progress,
    required this.copos,
    required this.metaCopos,
    this.size = 120,
  });

  final double progress;
  final int copos;
  final int metaCopos;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💧', style: TextStyle(fontSize: size * 0.22)),
              Text(
                '$copos/$metaCopos',
                style: TextStyle(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              Text(
                'copos',
                style: TextStyle(fontSize: size * 0.09, color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -math.pi / 2;
    const sweepFull = 2 * math.pi;

    final bgPaint = Paint()
      ..color = AppColors.card3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = progress >= 1 ? AppColors.yellow : AppColors.neon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * progress.clamp(0, 1),
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class MegaAguaCard extends StatefulWidget {
  const MegaAguaCard({super.key, this.compact = false, this.onVerMais});

  final bool compact;
  final VoidCallback? onVerMais;

  @override
  State<MegaAguaCard> createState() => _MegaAguaCardState();
}

class _MegaAguaCardState extends State<MegaAguaCard> with SingleTickerProviderStateMixin {
  WaterDayData? _data;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  String _mensagem = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseAnim = Tween<double>(begin: 1, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.elasticOut),
    );
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await WellnessService.instance.getWaterToday();
    if (!mounted) return;
    setState(() {
      _data = data;
      _mensagem = WellnessService.instance.mensagemAgua(data);
    });
  }

  Future<void> _addCopo() async {
    await _pulseCtrl.forward(from: 0);
    _pulseCtrl.reverse();
    final data = await WellnessService.instance.addCopo();
    if (!mounted) return;
    setState(() {
      _data = data;
      _mensagem = WellnessService.instance.mensagemAgua(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const PulguinhaCard(
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.neon, strokeWidth: 2))),
      );
    }

    return PulguinhaCard(
      borderColor: AppColors.blue.withValues(alpha: 0.3),
      backgroundColor: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mega Água',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.white),
                ),
              ),
              if (data.streak >= 2) PulguinhaBadge(label: '🔥 ${data.streak}d', variant: BadgeVariant.blue),
            ],
          ),
          const SizedBox(height: 4),
          Text(_mensagem, style: const TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (widget.compact) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: data.progress,
                minHeight: 10,
                backgroundColor: AppColors.card3,
                valueColor: AlwaysStoppedAnimation(data.metaBatida ? AppColors.yellow : AppColors.blue),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data.copos} copos · ${data.ml}ml', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                Text('Meta: ${data.metaMl}ml', style: const TextStyle(fontSize: 11, color: AppColors.grayDim)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ScaleTransition(
                    scale: _pulseAnim,
                    child: NeonButton(
                      label: '+1 Copo',
                      fullWidth: true,
                      backgroundColor: AppColors.blue,
                      onPressed: _addCopo,
                    ),
                  ),
                ),
                if (widget.onVerMais != null) ...[
                  const SizedBox(width: 8),
                  GhostButton(label: 'Ver +', onPressed: widget.onVerMais!),
                ],
              ],
            ),
          ] else ...[
            Center(child: WaterProgressRing(progress: data.progress, copos: data.copos, metaCopos: data.metaCopos, size: 140)),
            const SizedBox(height: 8),
            Text(
              '${data.ml}ml de ${data.metaMl}ml',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.gray, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: '− Copo',
                    onPressed: data.copos > 0
                        ? () async {
                            final d = await WellnessService.instance.removeCopo();
                            if (!mounted) return;
                            setState(() {
                              _data = d;
                              _mensagem = WellnessService.instance.mensagemAgua(d);
                            });
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ScaleTransition(
                    scale: _pulseAnim,
                    child: NeonButton(
                      label: '+1 Copo 💧',
                      fullWidth: true,
                      backgroundColor: AppColors.blue,
                      onPressed: _addCopo,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DicaDoDiaCard extends StatelessWidget {
  const DicaDoDiaCard({super.key, this.onVerTodas});

  final VoidCallback? onVerTodas;

  @override
  Widget build(BuildContext context) {
    final dica = TrainingTipsData.dicaDoDia();
    return PulguinhaCard(
      borderColor: AppColors.neon.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PulguinhaLogo(size: 48, showShadow: false, borderRadius: 10),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dica do dia', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gray, letterSpacing: 1)),
                    Text('Pulguinha recomenda', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.neon)),
                  ],
                ),
              ),
              PulguinhaBadge(label: dica.categoria, variant: BadgeVariant.gray),
            ],
          ),
          const SizedBox(height: 12),
          Text('${dica.icon} ${dica.titulo}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.white)),
          const SizedBox(height: 6),
          Text(dica.texto, style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.5)),
          if (onVerTodas != null) ...[
            const SizedBox(height: 12),
            GhostButton(label: 'Ver todas as dicas →', onPressed: onVerTodas!),
          ],
        ],
      ),
    );
  }
}

class ImcCalculatorWidget extends StatefulWidget {
  const ImcCalculatorWidget({super.key});

  @override
  State<ImcCalculatorWidget> createState() => _ImcCalculatorWidgetState();
}

class _ImcCalculatorWidgetState extends State<ImcCalculatorWidget> {
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  double? _imc;
  BmiCategory? _categoria;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await WellnessService.instance.getBmi();
    if (!mounted) return;
    if (data.pesoKg != null) _pesoCtrl.text = data.pesoKg!.toStringAsFixed(1);
    if (data.alturaCm != null) _alturaCtrl.text = data.alturaCm!.toStringAsFixed(0);
    _calcular(data);
  }

  void _calcular(BmiData data) {
    final imc = data.imc;
    setState(() {
      _imc = imc;
      _categoria = imc != null ? WellnessService.instance.categoriaImc(imc) : null;
    });
  }

  Future<void> _salvarECalcular() async {
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
    final altura = double.tryParse(_alturaCtrl.text.replaceAll(',', '.'));
    if (peso == null || altura == null || peso <= 0 || altura <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe peso e altura válidos.'), backgroundColor: AppColors.card2),
      );
      return;
    }
    final data = await WellnessService.instance.saveBmi(pesoKg: peso, alturaCm: altura);
    _calcular(data);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PulguinhaCard(
          child: Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calculadora de IMC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.white)),
                    Text('Índice de Massa Corporal', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(
                label: 'Peso (kg)',
                child: TextField(
                  controller: _pesoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Ex: 72.5'),
                ),
              ),
              FieldLabel(
                label: 'Altura (cm)',
                child: TextField(
                  controller: _alturaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Ex: 175'),
                ),
              ),
              const SizedBox(height: 16),
              NeonButton(label: 'Calcular IMC', fullWidth: true, onPressed: _salvarECalcular),
            ],
          ),
        ),
        if (_imc != null && _categoria != null) ...[
          const SizedBox(height: 12),
          PulguinhaCard(
            borderColor: Color(_categoria!.colorHex).withValues(alpha: 0.4),
            child: Column(
              children: [
                Text(
                  _imc!.toStringAsFixed(1),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(_categoria!.colorHex)),
                ),
                const Text('Seu IMC', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                const SizedBox(height: 8),
                PulguinhaBadge(label: _categoria!.label, variant: _badgeForImc(_imc!)),
                const SizedBox(height: 10),
                Text(_categoria!.descricao, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.5)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informação educativa apenas. O IMC não substitui avaliação de um profissional de saúde, nutricionista ou educador físico.',
                  style: TextStyle(fontSize: 11, color: AppColors.grayDim, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BadgeVariant _badgeForImc(double imc) {
    if (imc < 18.5) return BadgeVariant.blue;
    if (imc < 25) return BadgeVariant.neon;
    if (imc < 30) return BadgeVariant.yellow;
    return BadgeVariant.red;
  }
}

class TrainingTipsList extends StatefulWidget {
  const TrainingTipsList({super.key});

  @override
  State<TrainingTipsList> createState() => _TrainingTipsListState();
}

class _TrainingTipsListState extends State<TrainingTipsList> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PulguinhaCard(
          child: Row(
            children: [
              Text('🏋️', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dicas de Evolução', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.white)),
                    Text('Treino funcional com cara de Pulguinha', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...TrainingTipsData.tips.map((tip) {
          final open = _expanded.contains(tip.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PulguinhaCard(
              borderColor: open ? AppColors.neon.withValues(alpha: 0.3) : null,
              child: InkWell(
                onTap: () => setState(() {
                  if (open) {
                    _expanded.remove(tip.id);
                  } else {
                    _expanded.add(tip.id);
                  }
                }),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(tip.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(tip.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
                        ),
                        PulguinhaBadge(label: tip.categoria, variant: BadgeVariant.gray),
                        const SizedBox(width: 6),
                        Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.gray, size: 20),
                      ],
                    ),
                    if (open) ...[
                      const SizedBox(height: 10),
                      Text(tip.texto, style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.55)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
