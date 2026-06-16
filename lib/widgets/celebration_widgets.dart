import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pulguinha/services/app_sound_service.dart';
import 'package:pulguinha/theme/app_colors.dart';

/// Partículas estilo confetti para celebrações (aniversário, streak).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.child,
    this.active = false,
    this.duration = const Duration(seconds: 3),
    this.playFireworksSound = false,
  });

  final Widget child;
  final bool active;
  final Duration duration;
  /// Toca som de fogos por 2s quando a celebração inicia (ex.: aniversário).
  final bool playFireworksSound;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _particles = <_Particle>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _start();
  }

  void _start() {
    _particles.clear();
    if (widget.playFireworksSound) {
      AppSoundService.instance.playFogos();
    }
    for (var i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: -0.1 - _rng.nextDouble() * 0.3,
        speed: 0.3 + _rng.nextDouble() * 0.5,
        size: 4 + _rng.nextDouble() * 6,
        color: [AppColors.neon, AppColors.yellow, AppColors.blue, Colors.white, AppColors.red][_rng.nextInt(5)],
        rotation: _rng.nextDouble() * pi * 2,
      ));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.active)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(_particles, _controller.value),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  _Particle({required this.x, required this.y, required this.speed, required this.size, required this.color, required this.rotation});
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y + progress * p.speed) * size.height;
      if (y > size.height) continue;
      final x = p.x * size.width + sin(progress * pi * 4 + p.rotation) * 20;
      final paint = Paint()..color = p.color.withValues(alpha: 1 - progress * 0.5);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * pi * 2);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Animação de sucesso no check-in com pulse neon.
class CheckinSuccessOverlay extends StatefulWidget {
  const CheckinSuccessOverlay({
    super.key,
    required this.visible,
    required this.nomeAluno,
    this.streak = 0,
    this.milestone,
    this.onDone,
  });

  final bool visible;
  final String nomeAluno;
  final int streak;
  final int? milestone;
  final VoidCallback? onDone;

  @override
  State<CheckinSuccessOverlay> createState() => _CheckinSuccessOverlayState();
}

class _CheckinSuccessOverlayState extends State<CheckinSuccessOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
    ]).animate(_ctrl);
    _glow = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.visible) _play();
  }

  @override
  void didUpdateWidget(CheckinSuccessOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _play();
  }

  Future<void> _play() async {
    await _ctrl.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale.value,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.neon.withValues(alpha: 0.5 + _glow.value * 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.neon.withValues(alpha: 0.3 * _glow.value), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        widget.nomeAluno.split(' ').first,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text('Presença confirmada! 💪', style: TextStyle(fontSize: 16, color: AppColors.neon, fontWeight: FontWeight.w800)),
                      if (widget.streak >= 2) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.yellow.withValues(alpha: 0.4)),
                          ),
                          child: Text('🔥 ${widget.streak} treinos seguidos!', style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w900)),
                        ),
                      ],
                      if (widget.milestone != null) ...[
                        const SizedBox(height: 10),
                        Text('🏆 Marco ${widget.milestone}! +50 Pulguinha Points', style: TextStyle(fontSize: 13, color: AppColors.neon.withValues(alpha: 0.9), fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
